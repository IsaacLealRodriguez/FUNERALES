import 'dart:async'; // <--- IMPORTANTE PARA EL DEBOUNCER
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_detalle_contrato.dart';
import 'pantalla_nuevo_contrato.dart';

class PantallaCobranza extends StatefulWidget {
  const PantallaCobranza({super.key});

  @override
  State<PantallaCobranza> createState() => _PantallaCobranzaState();
}

class _PantallaCobranzaState extends State<PantallaCobranza> {
  List<Map<String, dynamic>> _contratos = [];
  bool _cargando = true;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // <--- TEMPORIZADOR PARA LA BÚSQUEDA

  @override
  void initState() {
    super.initState();
    _cargarContratos(); // Carga inicial sin filtros
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // >>> NUEVA LÓGICA DE BÚSQUEDA EN EL SERVIDOR <<<
  Future<void> _cargarContratos([String terminoBusqueda = '']) async {
    if (!mounted) return;
    setState(() => _cargando = true);

    try {
      // 1. Consulta base SIN ordenamiento todavía
      var peticion = Supabase.instance.client
          .from('contratos')
          .select(
            '*, clientes!inner(nombre_difunto, nombre_contacto), planes(nombre, precio_total)',
          );

      // 2. Si el usuario escribió algo, le pegamos el filtro
      if (terminoBusqueda.isNotEmpty) {
        peticion = peticion.or(
          'nombre_difunto.ilike.%$terminoBusqueda%,nombre_contacto.ilike.%$terminoBusqueda%',
          referencedTable: 'clientes',
        );
      }

      // 3. AHORA SÍ, ordenamos la lista y ejecutamos la petición (await)
      final response = await peticion
          .order('estado', ascending: true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _contratos = List<Map<String, dynamic>>.from(response);
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red[900],
          ),
        );
      }
      debugPrint("Error cargando contratos: $e");
    }
  }

  // Se ejecuta cada vez que el usuario teclea algo
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Espera 500 milisegundos después de que el usuario deja de escribir
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _cargarContratos(query);
    });
  }

  void _mostrarDialogoAbono(Map<String, dynamic> contrato, Color colorDorado) {
    final abonoCtrl = TextEditingController();
    final montoSugerido = contrato['monto_parcial'] ?? 0;
    abonoCtrl.text = montoSugerido.toString();

    final nombreCliente = contrato['clientes'] != null
        ? (contrato['clientes']['nombre_difunto'] ?? "Cliente")
        : "Cliente";
    final saldoPendiente = contrato['saldo_pendiente'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(color: colorDorado, width: 1),
        ),
        title: const Text(
          "Registrar Abono",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Cliente: $nombreCliente",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              "Debe: \$$saldoPendiente",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: abonoCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              cursorColor: colorDorado,
              decoration: InputDecoration(
                labelText: "Cantidad a Pagar",
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.attach_money, color: colorDorado),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorDorado, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorDorado,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              await _procesarPago(
                contrato,
                double.tryParse(abonoCtrl.text) ?? 0,
                colorDorado,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              "COBRAR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _procesarPago(
    Map<String, dynamic> contrato,
    double monto,
    Color colorDorado,
  ) async {
    if (monto <= 0) return;
    try {
      await Supabase.instance.client.from('pagos').insert({
        'contrato_id': contrato['id'],
        'monto': monto,
        'fecha_pago': DateTime.now().toIso8601String(),
        'metodo_pago': 'Efectivo',
      });

      final saldoActual = (contrato['saldo_pendiente'] as num?) ?? 0;
      final nuevoSaldo = saldoActual - monto;

      await Supabase.instance.client
          .from('contratos')
          .update({
            'saldo_pendiente': nuevoSaldo,
            'estado': nuevoSaldo <= 0 ? 'Liquidado' : 'Activo',
          })
          .eq('id', contrato['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "¡Abono registrado!",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: colorDorado,
        ),
      );

      _searchController.clear();
      _cargarContratos(); // Recarga los datos desde el servidor
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red[900]),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // EXTRAEMOS LOS COLORES DEL TEMA GLOBAL
    final tema = Theme.of(context);
    final colorDorado = tema.colorScheme.secondary;
    final colorFondo =
        tema.primaryColor; // Usamos el negro que definiste como primario
    const colorCard = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: colorFondo,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorDorado,
        icon: const Icon(Icons.person_add, color: Colors.black),
        label: const Text(
          "NUEVO",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantallaNuevoContrato()),
          ).then((_) => _cargarContratos());
        },
      ),
      appBar: AppBar(
        title: const Text(
          "CARTERA DE CLIENTES",
          style: TextStyle(letterSpacing: 1.2),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white12, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged, // Llama al debouncer
              style: const TextStyle(color: Colors.white),
              cursorColor: colorDorado,
              decoration: InputDecoration(
                hintText: "Buscar por difunto o contacto...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: colorDorado),
                filled: true,
                fillColor: colorCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _cargarContratos(); // Recarga todo sin filtro
                        },
                      )
                    : null,
              ),
            ),
          ),

          // LISTA
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: colorDorado))
                : _contratos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 50,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No se encontraron clientes",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    itemCount: _contratos.length,
                    itemBuilder: (context, index) {
                      final c = _contratos[index];
                      final planData = c['planes'] ?? {};
                      final clienteData = c['clientes'] ?? {};

                      final precioTotal =
                          (planData['precio_total'] as num?) ?? 1;
                      final saldo = (c['saldo_pendiente'] as num?) ?? 0;
                      final nombreDifunto =
                          clienteData['nombre_difunto'] ?? "Sin Nombre";
                      final nombrePlan = planData['nombre'] ?? "Plan";
                      final frecuencia = c['frecuencia_pago'] ?? "";

                      final bool estaLiquidado =
                          c['estado'] == 'Liquidado' || saldo <= 0;
                      final pagado = precioTotal - saldo;
                      final porcentaje = (precioTotal > 0)
                          ? (pagado / precioTotal).clamp(0.0, 1.0)
                          : 0.0;

                      return Card(
                        color: colorCard,
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: estaLiquidado
                                ? colorDorado.withOpacity(0.5)
                                : Colors.white12,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PantallaDetalleContrato(
                                  contrato: c,
                                  cliente:
                                      const {}, // Se ajustó para enviar un mapa vacío
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nombreDifunto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: estaLiquidado
                                            ? colorDorado
                                            : Colors.red[900],
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        estaLiquidado
                                            ? "LIQUIDADO"
                                            : "Debe: \$$saldo",
                                        style: TextStyle(
                                          color: estaLiquidado
                                              ? Colors.black
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Plan: $nombrePlan ($frecuencia)",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: LinearProgressIndicator(
                                        value: porcentaje.toDouble(),
                                        backgroundColor: Colors.white10,
                                        color: colorDorado,
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Pagado: \$$pagado de \$$precioTotal",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  child: estaLiquidado
                                      ? OutlinedButton.icon(
                                          icon: Icon(
                                            Icons.history,
                                            color: colorDorado,
                                          ),
                                          label: Text(
                                            "VER HISTORIAL",
                                            style: TextStyle(
                                              color: colorDorado,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: colorDorado,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    PantallaDetalleContrato(
                                                      contrato: c,
                                                      cliente:
                                                          const {}, // Ajuste mapa vacío
                                                    ),
                                              ),
                                            );
                                          },
                                        )
                                      : ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.attach_money,
                                            size: 20,
                                          ),
                                          label: const Text("REGISTRAR ABONO"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorDorado,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          onPressed: () => _mostrarDialogoAbono(
                                            c,
                                            colorDorado,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
