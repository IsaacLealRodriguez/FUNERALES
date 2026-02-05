import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_detalle_contrato.dart'; // Asegúrate de importar la pantalla que hicimos antes

class PantallaPerfilCliente extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const PantallaPerfilCliente({super.key, required this.cliente});

  @override
  State<PantallaPerfilCliente> createState() => _PantallaPerfilClienteState();
}

class _PantallaPerfilClienteState extends State<PantallaPerfilCliente> {
  List<Map<String, dynamic>> _contratos = [];
  bool _cargando = true;

  // COLORES
  final Color _colorFondo = Colors.black;
  final Color _colorDorado = const Color(0xFFD4AF37);
  final Color _colorCard = const Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _cargarContratosDelCliente();
  }

  Future<void> _cargarContratosDelCliente() async {
    try {
      // Traemos contratos y unimos con la info del PLAN para saber el nombre
      final response = await Supabase.instance.client
          .from('contratos')
          .select('*, planes(nombre, precio_total), clientes(*)')
          .eq('cliente_id', widget.cliente['id'])
          .order('fecha_inicio', ascending: false);

      if (mounted) {
        setState(() {
          _contratos = List<Map<String, dynamic>>.from(response);
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar contratos: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        title: const Text("PERFIL DE CLIENTE"),
        backgroundColor: Colors.black,
        foregroundColor: _colorDorado,
      ),
      body: Column(
        children: [
          // 1. FICHA DE DATOS PERSONALES
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: _colorCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _datoFicha(
                  "DIFUNTO / BENEFICIARIO",
                  widget.cliente['nombre_difunto'],
                ),
                const SizedBox(height: 10),
                _datoFicha(
                  "TITULAR RESPONSABLE",
                  widget.cliente['nombre_contacto'],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _datoFicha("TELÉFONO", widget.cliente['telefono']),
                    ),
                    Expanded(
                      child: _datoFicha(
                        "DIRECCIÓN",
                        widget.cliente['direccion'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "PLANES CONTRATADOS (${_contratos.length})",
                style: TextStyle(
                  color: _colorDorado,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. LISTA DE CONTRATOS
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: _colorDorado))
                : _contratos.isEmpty
                ? const Center(
                    child: Text(
                      "Este cliente no tiene planes activos.",
                      style: TextStyle(color: Colors.white30),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _contratos.length,
                    itemBuilder: (context, index) {
                      final contrato = _contratos[index];
                      final plan = contrato['planes'] ?? {};
                      final saldo = contrato['saldo_pendiente'] ?? 0;
                      final esLiquidado = saldo <= 0;

                      return Card(
                        color: _colorCard,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: esLiquidado ? Colors.green : Colors.white12,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          title: Text(
                            plan['nombre'] ?? "Plan Desconocido",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            esLiquidado ? "LIQUIDADO" : "PENDIENTE: \$$saldo",
                            style: TextStyle(
                              color: esLiquidado
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white54,
                            size: 16,
                          ),
                          onTap: () {
                            // NAVEGAR AL DETALLE (PAGOS)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PantallaDetalleContrato(
                                  contrato: contrato,
                                  cliente: {},
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _datoFicha(String label, String? valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        Text(
          valor ?? "---",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}
