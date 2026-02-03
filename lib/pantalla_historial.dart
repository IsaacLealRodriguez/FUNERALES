import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------
// PANTALLA 1: LISTA HISTÓRICA GENERAL
// ---------------------------------------------------------
class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  List<Map<String, dynamic>> _todosLosContratos = [];
  List<Map<String, dynamic>> _contratosFiltrados = [];
  bool _cargando = true;
  final TextEditingController _searchController = TextEditingController();

  // COLORES TEMA BLACK & GOLD
  final Color _colorFondo = Colors.black;
  final Color _colorDorado = const Color(0xFFD4AF37);
  final Color _colorCard = const Color(0xFF1E1E1E);
  final Color _colorTexto = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarContratos();
  }

  @override
  void dispose() {
    _searchController.dispose(); // Buena práctica: limpiar controlador
    super.dispose();
  }

  Future<void> _cargarContratos() async {
    try {
      // Obtenemos contratos con datos del cliente y plan
      final response = await Supabase.instance.client
          .from('contratos')
          .select('*, clientes(nombre_difunto), planes(nombre)')
          .order('created_at', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        setState(() {
          _todosLosContratos = data;
          _contratosFiltrados = data;
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando historial: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _filtrarResultados(String query) {
    setState(() {
      if (query.isEmpty) {
        _contratosFiltrados = _todosLosContratos;
      } else {
        _contratosFiltrados = _todosLosContratos.where((contrato) {
          // Navegación segura para obtener el nombre
          final nombre = contrato['clientes'] != null
              ? (contrato['clientes']['nombre_difunto'] ?? "")
                    .toString()
                    .toLowerCase()
              : "";
          return nombre.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        title: const Text(
          "HISTORIAL GENERAL",
          style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: _colorDorado,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white12, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // BUSCADOR
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.black,
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarResultados,
              style: TextStyle(color: _colorTexto),
              cursorColor: _colorDorado,
              decoration: InputDecoration(
                hintText: "Buscar por nombre de difunto...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: _colorDorado),
                filled: true,
                fillColor: _colorCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // LISTA DE CONTRATOS
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: _colorDorado))
                : _contratosFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      "Sin registros encontrados",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _contratosFiltrados.length,
                    itemBuilder: (context, index) {
                      final contrato = _contratosFiltrados[index];

                      // Extracción segura de datos
                      final cliente = contrato['clientes'] != null
                          ? contrato['clientes']['nombre_difunto']
                          : 'Desconocido';
                      final plan = contrato['planes'] != null
                          ? contrato['planes']['nombre']
                          : 'Plan';
                      final estado = contrato['estado'] ?? 'Activo';

                      return GestureDetector(
                        onTap: () {
                          // Navegar al detalle
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PantallaDetalleContrato(contrato: contrato),
                            ),
                          );
                        },
                        child: Card(
                          color: _colorCard,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.white10),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.description,
                              color: estado == 'Liquidado'
                                  ? Colors.green
                                  : _colorDorado,
                            ),
                            title: Text(
                              cliente,
                              style: TextStyle(
                                color: _colorTexto,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              plan,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: estado == 'Liquidado'
                                    ? _colorDorado
                                    : Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: TextStyle(
                                  color: estado == 'Liquidado'
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

// ---------------------------------------------------------
// PANTALLA 2: DETALLE DE PAGOS Y CONTRATO
// ---------------------------------------------------------
class PantallaDetalleContrato extends StatefulWidget {
  final Map<String, dynamic> contrato;
  const PantallaDetalleContrato({super.key, required this.contrato});

  @override
  State<PantallaDetalleContrato> createState() =>
      _PantallaDetalleContratoState();
}

class _PantallaDetalleContratoState extends State<PantallaDetalleContrato> {
  List<Map<String, dynamic>> _pagos = [];
  bool _cargando = true;

  // COLORES
  final Color _colorFondo = Colors.black;
  final Color _colorDorado = const Color(0xFFD4AF37);
  final Color _colorCard = const Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _cargarHistorialPagos();
  }

  Future<void> _cargarHistorialPagos() async {
    try {
      final contratoId = widget.contrato['id'];

      final response = await Supabase.instance.client
          .from('pagos')
          .select()
          .eq('contrato_id', contratoId)
          .order('fecha_pago', ascending: false);

      if (mounted) {
        setState(() {
          _pagos = List<Map<String, dynamic>>.from(response);
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
      debugPrint("Error cargando pagos: $e");
    }
  }

  // Función manual para no depender del paquete 'intl' y evitar errores
  String _formatearFecha(String? fechaIso) {
    if (fechaIso == null) return "-";
    try {
      final fecha = DateTime.parse(fechaIso);
      // Formato simple DD/MM/AAAA HH:MM
      return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fechaIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extracción de datos
    final clienteMap = widget.contrato['clientes'] ?? {};
    final planMap = widget.contrato['planes'] ?? {};

    final nombreCliente = clienteMap['nombre_difunto'] ?? "Cliente Desconocido";
    final nombrePlan = planMap['nombre'] ?? "Plan";

    // Cálculos numéricos seguros
    final saldoPendiente =
        (widget.contrato['saldo_pendiente'] as num?)?.toDouble() ?? 0.0;
    final precioTotal = (planMap['precio_total'] as num?)?.toDouble() ?? 0.0;

    // Si el precio total es 0 (error de datos), asumimos que lo pagado es 0
    final pagadoTotal = (precioTotal > 0)
        ? (precioTotal - saldoPendiente)
        : 0.0;

    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        title: const Text("ESTADO DE CUENTA"),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: _colorDorado,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white12, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // 1. TARJETA DE RESUMEN (HEADER)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _colorCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _colorDorado.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: _colorDorado.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  nombreCliente,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  nombrePlan.toUpperCase(),
                  style: TextStyle(color: Colors.grey[400], letterSpacing: 1),
                ),
                const Divider(color: Colors.white12, height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoCaja(
                      "Total Plan",
                      "\$${precioTotal.toStringAsFixed(2)}",
                      Colors.white,
                    ),
                    _InfoCaja(
                      "Pagado",
                      "\$${pagadoTotal.toStringAsFixed(2)}",
                      Colors.green,
                    ),
                    _InfoCaja(
                      "Debe",
                      "\$${saldoPendiente.toStringAsFixed(2)}",
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "MOVIMIENTOS REGISTRADOS",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // 2. LISTA DE MOVIMIENTOS
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: _colorDorado))
                : _pagos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 50,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "No hay pagos registrados aún.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _pagos.length,
                    itemBuilder: (context, index) {
                      final pago = _pagos[index];
                      final monto = (pago['monto'] as num?) ?? 0;
                      final fecha = _formatearFecha(
                        pago['fecha_pago'] ?? pago['created_at'],
                      );
                      final metodo = pago['metodo_pago'] ?? 'Efectivo';

                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white10),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _colorDorado.withOpacity(0.2),
                            child: Icon(
                              Icons.check,
                              color: _colorDorado,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            "Abono a cuenta",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "$fecha • $metodo",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            "+\$${monto.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

  Widget _InfoCaja(String titulo, String valor, Color colorValor) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: colorValor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
