import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_nuevo_contrato.dart';

class PantallaPlanes extends StatefulWidget {
  const PantallaPlanes({super.key});

  @override
  State<PantallaPlanes> createState() => _PantallaPlanesState();
}

class _PantallaPlanesState extends State<PantallaPlanes> {
  List<Map<String, dynamic>> _planes = [];
  bool _cargando = true;

  // Colores del Tema
  final Color _colorFondo = Colors.black;
  final Color _colorCard = const Color(0xFF1E1E1E); // Gris muy oscuro
  final Color _colorDorado = const Color(0xFFD4AF37);
  final Color _colorTexto = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarPlanes();
  }

  Future<void> _cargarPlanes() async {
    try {
      final response = await Supabase.instance.client
          .from('planes')
          .select()
          .order('precio_total', ascending: true);

      setState(() {
        _planes = List<Map<String, dynamic>>.from(response);
        _cargando = false;
      });
    } catch (e) {
      debugPrint("Error cargando planes: $e");
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        title: const Text(
          "CATÁLOGO DE PLANES",
          style: TextStyle(letterSpacing: 1.5),
        ),
        backgroundColor: Colors.black,
        foregroundColor: _colorDorado,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white12, height: 1.0),
        ),
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: _colorDorado))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _planes.length,
              itemBuilder: (context, index) {
                final plan = _planes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _colorCard,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _colorDorado.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado: Nombre y Precio
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                plan['nombre'] ?? "Plan",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _colorTexto,
                                ),
                              ),
                            ),
                            Text(
                              "\$${plan['precio_total']}",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _colorDorado,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 25),

                        // Descripción
                        Text(
                          plan['descripcion'] ?? "Sin descripción disponible.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Botón de Acción
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.shopping_cart_checkout,
                              size: 18,
                            ),
                            label: const Text(
                              "VENDER ESTE PLAN",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _colorDorado,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              // Navegamos pasando el plan seleccionado
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PantallaNuevoContrato(
                                    planPreseleccionado: plan, // <--- OJO AQUÍ
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
