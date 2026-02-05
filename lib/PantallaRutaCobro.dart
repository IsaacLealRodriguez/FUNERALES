import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'pantalla_detalle_contrato.dart'; // IMPORTANTE: Importamos la nueva pantalla

class PantallaRutaCobro extends StatefulWidget {
  const PantallaRutaCobro({super.key});

  @override
  State<PantallaRutaCobro> createState() => _PantallaRutaCobroState();
}

class _PantallaRutaCobroState extends State<PantallaRutaCobro> {
  bool _cargando = true;
  List<Map<String, dynamic>> _listaCobros = [];
  double _totalPorCobrarHoy = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarRutaDeCobro();
  }

  Future<void> _cargarRutaDeCobro() async {
    if (!mounted) return;
    setState(() => _cargando = true);
    try {
      final hoy = DateTime.now();
      // Fin del día de hoy
      final finDeDia = DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
        23,
        59,
        59,
      ).toIso8601String();

      final response = await Supabase.instance.client
          .from('contratos')
          .select('*, clientes(*), planes(nombre)')
          .eq('estado', 'Activo')
          .lte('proximo_pago', finDeDia)
          .order('proximo_pago', ascending: true);

      double total = 0;
      final data = List<Map<String, dynamic>>.from(response);
      for (var item in data) {
        total += (item['monto_parcial'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _listaCobros = data;
          _totalPorCobrarHoy = total;
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando ruta: $e');
      if (mounted) setState(() => _cargando = false);
    }
  }

  int _calcularDiasAtraso(String fechaPago) {
    final fecha = DateTime.parse(fechaPago);
    final hoy = DateTime.now();
    final fechaSoloDia = DateTime(fecha.year, fecha.month, fecha.day);
    final hoySoloDia = DateTime(hoy.year, hoy.month, hoy.day);
    return hoySoloDia.difference(fechaSoloDia).inDays;
  }

  @override
  Widget build(BuildContext context) {
    const colorDorado = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("RUTA DE COBRO"),
        backgroundColor: Colors.black,
        foregroundColor: colorDorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarRutaDeCobro,
          ),
        ],
      ),
      body: Column(
        children: [
          // --- RESUMEN DE RUTA ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Visitas pendientes:",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "${_listaCobros.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Monto a recaudar:",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "\$${_totalPorCobrarHoy.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- LISTA DE COBROS ---
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: colorDorado),
                  )
                : _listaCobros.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.green,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "¡Todo al día!",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        Text(
                          "No hay cobros pendientes por ahora.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _listaCobros.length,
                    itemBuilder: (context, index) {
                      final contrato = _listaCobros[index];
                      final cliente = contrato['clientes'];
                      final plan = contrato['planes'];

                      final fechaPago = DateTime.parse(
                        contrato['proximo_pago'],
                      );
                      final diasAtraso = _calcularDiasAtraso(
                        contrato['proximo_pago'],
                      );
                      final cuota = (contrato['monto_parcial'] as num)
                          .toDouble();

                      Color colorEstado;
                      String textoEstado;

                      if (diasAtraso > 0) {
                        colorEstado = Colors.redAccent;
                        textoEstado = "ATRASADO ($diasAtraso días)";
                      } else if (diasAtraso == 0) {
                        colorEstado = Colors.orangeAccent;
                        textoEstado = "TOCA HOY";
                      } else {
                        colorEstado = Colors.green;
                        textoEstado = "PRÓXIMAMENTE";
                      }

                      return Card(
                        color: const Color(0xFF151515),
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: colorEstado.withOpacity(0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorEstado.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      textoEstado,
                                      style: TextStyle(
                                        color: colorEstado,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd/MMM/yyyy').format(fechaPago),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cliente['nombre_contacto'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Plan: ${plan['nombre']}",
                                style: const TextStyle(
                                  color: colorDorado,
                                  fontSize: 14,
                                ),
                              ),
                              const Divider(color: Colors.white12, height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.white54,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      cliente['direccion'] ?? "Sin dirección",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        color: Colors.white54,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        cliente['telefono'] ?? "--",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "\$${cuota.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.payment),
                                  label: const Text("IR A ABONAR"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white10,
                                    foregroundColor: Colors.white,
                                  ),
                                  // AQUÍ ESTÁ LA CORRECCIÓN CLAVE: async y limpieza
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PantallaDetalleContrato(
                                              contrato: contrato,
                                              cliente: cliente,
                                            ),
                                      ),
                                    );
                                    // Al volver, recargar la lista
                                    _cargarRutaDeCobro();
                                  },
                                ),
                              ),
                            ],
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
