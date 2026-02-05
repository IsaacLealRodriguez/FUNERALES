import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_nuevo_contrato.dart';
import 'pantalla_detalle_contrato.dart';
import 'menu_lateral.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  // Variables para las métricas
  double _cobradoHoy = 0.0;
  double _porCobrarTotal = 0.0;
  bool _cargandoMetricas = true;

  // Stream de contratos activos
  final _contratosStream = Supabase.instance.client
      .from('contratos')
      .stream(primaryKey: ['id'])
      .eq('estado', 'Activo')
      .order('fecha_inicio', ascending: false);

  @override
  void initState() {
    super.initState();
    _calcularMetricas();
  }

  // --- FUNCIÓN PARA CALCULAR DINERO ---
  Future<void> _calcularMetricas() async {
    final supabase = Supabase.instance.client;
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();

    try {
      // 1. Calcular lo cobrado HOY (Tabla pagos)
      final pagosHoy = await supabase
          .from('pagos')
          .select('monto')
          .gte('fecha_pago', inicioDia); // Pagos desde las 00:00 de hoy

      double sumaHoy = 0.0;
      for (var p in pagosHoy) {
        sumaHoy += (p['monto'] as num).toDouble();
      }

      // 2. Calcular deuda total (Tabla contratos activos)
      final contratosActivos = await supabase
          .from('contratos')
          .select('saldo_pendiente')
          .eq('estado', 'Activo');

      double sumaDeuda = 0.0;
      for (var c in contratosActivos) {
        sumaDeuda += (c['saldo_pendiente'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _cobradoHoy = sumaHoy;
          _porCobrarTotal = sumaDeuda;
          _cargandoMetricas = false;
        });
      }
    } catch (e) {
      debugPrint("Error métricas: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorDorado = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("PANEL DE CONTROL"),
        backgroundColor: Colors.black,
        foregroundColor: colorDorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _calcularMetricas, // Botón para recalcular caja
          ),
        ],
      ),
      drawer: const MenuLateral(),

      body: Column(
        children: [
          // --- TARJETA DE RESUMEN FINANCIERO ---
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E1E1E), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: colorDorado.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: colorDorado.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // CAJA DEL DÍA
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "COBRADO HOY",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _cargandoMetricas
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorDorado,
                                ),
                              )
                            : Text(
                                "\$${_cobradoHoy.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                    // DEUDA TOTAL
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "POR COBRAR (TOTAL)",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _cargandoMetricas
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorDorado,
                                ),
                              )
                            : Text(
                                "\$${_porCobrarTotal.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- TÍTULO SECCIÓN ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "CONTRATOS ACTIVOS",
                  style: TextStyle(
                    color: colorDorado,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.arrow_downward, color: Colors.white24, size: 16),
              ],
            ),
          ),

          // --- LISTA DE DEUDORES ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _contratosStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                    child: CircularProgressIndicator(color: colorDorado),
                  );

                final contratos = snapshot.data!;
                if (contratos.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay contratos activos.",
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: contratos.length,
                  itemBuilder: (context, index) {
                    final contrato = contratos[index];

                    // Supabase a veces trae las relaciones anidadas si configuramos la foreign key,
                    // pero en el stream simple a veces solo trae el ID.
                    // Para simplificar el Dashboard, haremos una consulta inteligente.
                    // NOTA: Si ves "Instance of..." aquí, avísame y ajustamos la consulta.

                    return _TarjetaContratoSimple(contrato: contrato);
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PantallaNuevoContrato(),
            ),
          );
        },
        backgroundColor: colorDorado,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          "NUEVO CONTRATO",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Widget separado para manejar la carga de datos del cliente individualmente
// Esto evita que el stream principal se complique
class _TarjetaContratoSimple extends StatefulWidget {
  final Map<String, dynamic> contrato;
  const _TarjetaContratoSimple({required this.contrato});

  @override
  State<_TarjetaContratoSimple> createState() => _TarjetaContratoSimpleState();
}

class _TarjetaContratoSimpleState extends State<_TarjetaContratoSimple> {
  Map<String, dynamic>? _cliente;
  Map<String, dynamic>? _plan;

  @override
  void initState() {
    super.initState();
    _cargarDatosRelacionados();
  }

  Future<void> _cargarDatosRelacionados() async {
    final supabase = Supabase.instance.client;
    // Cargar Cliente
    final clienteRes = await supabase
        .from('clientes')
        .select()
        .eq('id', widget.contrato['cliente_id'])
        .single();
    // Cargar Plan
    final planRes = await supabase
        .from('planes')
        .select()
        .eq('id', widget.contrato['plan_id'])
        .single();

    if (mounted) {
      setState(() {
        _cliente = clienteRes;
        _plan = planRes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cliente == null) return const SizedBox(); // Cargando silencioso

    final saldo = (widget.contrato['saldo_pendiente'] as num).toDouble();

    // Unificar mapa completo para pasar al detalle
    final contratoCompleto = {
      ...widget.contrato,
      'clientes': _cliente,
      'planes': _plan,
    };

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.black,
          child: Text(
            (_cliente!['nombre_difunto'] ?? "C")[0],
            style: const TextStyle(color: Color(0xFFD4AF37)),
          ),
        ),
        title: Text(
          _cliente!['nombre_difunto'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Debe: \$${saldo.toStringAsFixed(2)}",
          style: const TextStyle(color: Colors.redAccent),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.white24,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaDetalleContrato(
                contrato: contratoCompleto,
                cliente: {},
              ),
            ),
          );
        },
      ),
    );
  }
}
