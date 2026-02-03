import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaClientes extends StatefulWidget {
  const PantallaClientes({super.key});

  @override
  State<PantallaClientes> createState() => _PantallaClientesState();
}

class _PantallaClientesState extends State<PantallaClientes> {
  List<Map<String, dynamic>> _clientes = [];
  bool _cargando = true;
  String? _funerariaId;

  // CONSTANTES DE DISEÑO
  final Color _colorFondo = Colors.black;
  final Color _colorDorado = const Color(0xFFD4AF37);
  final Color _colorCard = const Color(
    0xFF1E1E1E,
  ); // Un gris muy oscuro para las tarjetas
  final Color _colorTextoBlanco = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final datosFuneraria = await Supabase.instance.client
          .from('funerarias')
          .select('id')
          .eq('user_id', userId)
          .single();

      _funerariaId = datosFuneraria['id'].toString();

      final response = await Supabase.instance.client
          .from('clientes')
          .select()
          .eq('funeraria_id', _funerariaId!)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _clientes = List<Map<String, dynamic>>.from(response);
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        // SnackBar de error con estilo
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
  }

  // Estilo común para los inputs del diálogo
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: _colorDorado),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _colorDorado, width: 2),
      ),
    );
  }

  void _mostrarFormularioAgregar() {
    if (_funerariaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Esperando datos de la funeraria...")),
      );
      return;
    }

    final nombreDifuntoCtrl = TextEditingController();
    final nombreContactoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colorCard, // Fondo oscuro para el diálogo
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(color: _colorDorado, width: 1), // Borde fino dorado
        ),
        title: Text(
          "Nuevo Ingreso",
          style: TextStyle(
            color: _colorTextoBlanco,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreDifuntoCtrl,
                style: TextStyle(color: _colorTextoBlanco),
                cursorColor: _colorDorado,
                decoration: _inputDecoration(
                  "Nombre del Difunto",
                  Icons.person_outline,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: nombreContactoCtrl,
                style: TextStyle(color: _colorTextoBlanco),
                cursorColor: _colorDorado,
                decoration: _inputDecoration(
                  "Familiar Responsable",
                  Icons.family_restroom,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: telefonoCtrl,
                style: TextStyle(color: _colorTextoBlanco),
                cursorColor: _colorDorado,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("Teléfono", Icons.phone),
              ),
            ],
          ),
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
            onPressed: () async {
              if (nombreDifuntoCtrl.text.isEmpty) return;

              try {
                await Supabase.instance.client.from('clientes').insert({
                  'funeraria_id': _funerariaId,
                  'nombre_difunto': nombreDifuntoCtrl.text,
                  'nombre_contacto': nombreContactoCtrl.text,
                  'telefono_contacto': telefonoCtrl.text,
                  'fecha_fallecimiento': DateTime.now().toIso8601String(),
                });

                if (context.mounted) Navigator.pop(context);
                _cargarClientes();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorDorado, // Fondo Dorado
              foregroundColor: Colors.black, // Texto Negro
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text(
              "GUARDAR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondo, // Negro Total
      appBar: AppBar(
        title: const Text(
          "LISTA DE CLIENTES",
          style: TextStyle(letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.black, // AppBar negra
        foregroundColor: _colorDorado, // Título dorado
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.white12, // Línea sutil separadora
            height: 1.0,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioAgregar,
        backgroundColor: _colorDorado,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: _colorDorado))
          : _clientes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 60, color: Colors.grey[800]),
                  const SizedBox(height: 10),
                  Text(
                    "No hay clientes registrados",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _clientes.length,
              itemBuilder: (context, index) {
                final cliente = _clientes[index];
                return Card(
                  color: _colorCard, // Tarjeta gris oscuro
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      5,
                    ), // Bordes rectos/serios
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: CircleAvatar(
                      backgroundColor: _colorDorado,
                      radius: 25,
                      child: const Icon(
                        Icons.person,
                        color: Colors.black,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      cliente['nombre_difunto'] ?? 'Sin nombre',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _colorTextoBlanco,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.family_restroom,
                                size: 14,
                                color: _colorDorado,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Familiar: ${cliente['nombre_contacto'] ?? '-'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 14, color: _colorDorado),
                              const SizedBox(width: 5),
                              Text(
                                "Tel: ${cliente['telefono_contacto'] ?? '-'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: _colorDorado,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
