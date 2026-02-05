import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_nuevo_contrato.dart'; // IMPORTANTE: Importa tu pantalla de contrato

class PantallaPlanes extends StatefulWidget {
  const PantallaPlanes({super.key});

  @override
  State<PantallaPlanes> createState() => _PantallaPlanesState();
}

class _PantallaPlanesState extends State<PantallaPlanes> {
  final Future<List<Map<String, dynamic>>> _planesFuture = Supabase
      .instance
      .client
      .from('planes')
      .select()
      .order('precio_total', ascending: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CATÁLOGO DE PLANES"),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD4AF37),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _planesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          }
          final planes = snapshot.data!;

          if (planes.isEmpty) {
            return const Center(
              child: Text(
                "No hay planes registrados.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: planes.length,
            itemBuilder: (context, index) {
              final plan = planes[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // --- INFORMACIÓN DEL PLAN ---
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                plan['nombre'] ?? "Plan",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "\$${plan['precio_total']}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 10),
                          Text(
                            plan['descripcion'] ?? "Sin descripción",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- BOTÓN DE ACCIÓN ---
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white12)),
                      ),
                      child: InkWell(
                        // EFECTO VISUAL AL TOCAR
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        onTap: () {
                          // AQUÍ ESTÁ LA MAGIA: Navegamos pasando el plan
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PantallaNuevoContrato(
                                planPreseleccionado: plan,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFFD4AF37),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "VENDER ESTE PLAN",
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
