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
  List<Map<String, dynamic>> _contratosOriginales = [];
  List<Map<String, dynamic>> _contratosFiltrados = [];

  bool _cargando = true;
  final TextEditingController _searchController = TextEditingController();

  // CONSTANTES DE DISEÑO
  final Color _colorFondo = Colors.black;
  final Color _colorDorado = const Color(0xFFD4AF37);
  final Color _colorCard = const Color(0xFF1E1E1E);
  final Color _colorTextoBlanco = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarTodosLosContratos();
  }

  Future<void> _cargarTodosLosContratos() async {
    try {
      final response = await Supabase.instance.client
          .from('contratos')
          .select(
            '*, clientes(nombre_difunto, nombre_contacto), planes(nombre, precio_total)',
          )
          .order('estado', ascending: true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _contratosOriginales = List<Map<String, dynamic>>.from(response);
          _contratosFiltrados = _contratosOriginales;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: $e",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red[900],
          ),
        );
      }
      debugPrint("Error cargando contratos: $e");
    }
  }

  void _filtrarLista(String texto) {
    setState(() {
      if (texto.isEmpty) {
        _contratosFiltrados = _contratosOriginales;
      } else {
        _contratosFiltrados = _contratosOriginales.where((contrato) {
          final nombreDifunto = contrato['clientes'] != null
              ? (contrato['clientes']['nombre_difunto']
                        ?.toString()
                        .toLowerCase() ??
                    "")
              : "";

          final nombreContacto = contrato['clientes'] != null
              ? (contrato['clientes']['nombre_contacto']
                        ?.toString()
                        .toLowerCase() ??
                    "")
              : "";

          final input = texto.toLowerCase();
          return nombreDifunto.contains(input) ||
              nombreContacto.contains(input);
        }).toList();
      }
    });
  }

  // Estilo para inputs (usado en el diálogo)
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: _colorDorado),
      prefixText: "\$ ",
      prefixStyle: TextStyle(color: _colorTextoBlanco, fontSize: 16),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _colorDorado, width: 2),
      ),
    );
  }

  void _mostrarDialogoAbono(Map<String, dynamic> contrato) {
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
        backgroundColor: _colorCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(color: _colorDorado, width: 1),
        ),
        title: Text(
          "Registrar Abono",
          style: TextStyle(
            color: _colorTextoBlanco,
            fontWeight: FontWeight.bold,
          ),
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
              style: TextStyle(color: _colorTextoBlanco),
              cursorColor: _colorDorado,
              decoration: _inputDecoration(
                "Cantidad a Pagar",
                Icons.attach_money,
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
              backgroundColor: _colorDorado,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            onPressed: () async {
              await _procesarPago(
                contrato,
                double.tryParse(abonoCtrl.text) ?? 0,
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
          backgroundColor: _colorDorado,
        ),
      );

      _cargarTodosLosContratos();
      _searchController.clear();
      _filtrarLista("");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $e",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red[900],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondo,

      // >>> AQUÍ AGREGAMOS EL BOTÓN FLOTANTE <<<
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _colorDorado,
        icon: const Icon(Icons.person_add, color: Colors.black),
        label: const Text(
          "NUEVO",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          // Navegar a la pantalla de nuevo contrato y recargar al volver
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantallaNuevoContrato()),
          ).then((_) => _cargarTodosLosContratos());
        },
      ),

      // >>> FIN DEL BOTÓN FLOTANTE <<<
      appBar: AppBar(
        title: const Text(
          "CARTERA DE CLIENTES",
          style: TextStyle(letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: _colorDorado,
        elevation: 0,
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
              onChanged: _filtrarLista,
              style: TextStyle(color: _colorTextoBlanco),
              cursorColor: _colorDorado,
              decoration: InputDecoration(
                hintText: "Buscar cliente...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: _colorDorado),
                filled: true,
                fillColor: _colorCard, // Fondo gris oscuro
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarLista("");
                        },
                      )
                    : null,
              ),
            ),
          ),

          // LISTA
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: _colorDorado))
                : _contratosFiltrados.isEmpty
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
                    itemCount: _contratosFiltrados.length,
                    itemBuilder: (context, index) {
                      final c = _contratosFiltrados[index];

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
                        color: _colorCard,
                        margin: const EdgeInsets.only(bottom: 15),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: estaLiquidado
                                ? _colorDorado.withOpacity(0.5)
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
                                  cliente: {},
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // HEADER DE LA TARJETA
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nombreDifunto,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: _colorTextoBlanco,
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
                                            ? _colorDorado
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

                                // BARRA DE PROGRESO
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: LinearProgressIndicator(
                                        value: porcentaje.toDouble(),
                                        backgroundColor: Colors.white10,
                                        color: _colorDorado, // Barra dorada
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

                                // BOTONES DE ACCIÓN
                                SizedBox(
                                  width: double.infinity,
                                  child: estaLiquidado
                                      ? OutlinedButton.icon(
                                          icon: Icon(
                                            Icons.history,
                                            color: _colorDorado,
                                          ),
                                          label: Text(
                                            "VER HISTORIAL",
                                            style: TextStyle(
                                              color: _colorDorado,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: _colorDorado,
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
                                                      cliente: {},
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
                                            backgroundColor: _colorDorado,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _mostrarDialogoAbono(c),
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
