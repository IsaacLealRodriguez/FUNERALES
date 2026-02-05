import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // NECESARIO PARA LLAMAR
import 'pantalla_contratos_cliente.dart'; // La pantalla nueva que acabamos de crear

class PantallaClientes extends StatefulWidget {
  const PantallaClientes({super.key});

  @override
  State<PantallaClientes> createState() => _PantallaClientesState();
}

class _PantallaClientesState extends State<PantallaClientes> {
  final TextEditingController _searchController = TextEditingController();
  String _filtro = "";

  // CAMBIO 1: Ordenamos por 'nombre_contacto' (Titular) para que la lista sea alfabética por quien paga
  final _clientesStream = Supabase.instance.client
      .from('clientes')
      .stream(primaryKey: ['id'])
      .order('nombre_contacto', ascending: true);

  // --- FUNCIÓN PARA LLAMAR ---
  Future<void> _hacerLlamada(String? telefono) async {
    if (telefono == null || telefono.isEmpty || telefono.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No hay un número de teléfono válido registrado."),
        ),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: telefono);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'No se pudo abrir el marcador';
      }
    } catch (e) {
      debugPrint("Error llamada: $e");
    }
  }

  void _confirmarEliminar(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "¿Eliminar Cliente?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Se eliminará al titular '${cliente['nombre_contacto']}'.\n\nSi tiene contratos, no se podrá borrar.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarCliente(cliente['id']);
            },
            child: const Text(
              "ELIMINAR",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCliente(int idCliente) async {
    try {
      await Supabase.instance.client
          .from('clientes')
          .delete()
          .eq('id', idCliente);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cliente eliminado"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se puede borrar (Tiene historial)"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorDorado = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("DIRECTORIO (TITULARES)"),
        backgroundColor: Colors.black,
        foregroundColor: colorDorado,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white12, height: 1),
        ),
      ),
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.black,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar titular...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: colorDorado),
                suffixIcon: _filtro.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filtro = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: colorDorado, width: 1),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _filtro = val.toLowerCase();
                });
              },
            ),
          ),

          // --- LISTA DE CLIENTES ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _clientesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                    child: CircularProgressIndicator(color: colorDorado),
                  );

                final clientes = snapshot.data!;
                final clientesFiltrados = clientes.where((c) {
                  final difunto = (c['nombre_difunto'] ?? "")
                      .toString()
                      .toLowerCase();
                  final contacto = (c['nombre_contacto'] ?? "")
                      .toString()
                      .toLowerCase();
                  return difunto.contains(_filtro) ||
                      contacto.contains(_filtro);
                }).toList();

                if (clientesFiltrados.isEmpty) {
                  return const Center(
                    child: Text(
                      "No se encontraron resultados.",
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  itemCount: clientesFiltrados.length,
                  itemBuilder: (context, index) {
                    final c = clientesFiltrados[index];

                    // Preparamos variables para mejor lectura
                    final nombreTitular = c['nombre_contacto'] ?? "Sin Nombre";
                    final nombreDifunto = c['nombre_difunto'] ?? "N/A";
                    final telefono = c['telefono'] ?? "Sin tel";

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),

                        // LETRA INICIAL (Ahora basada en el Titular)
                        leading: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorDorado.withOpacity(0.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            (nombreTitular.isNotEmpty ? nombreTitular[0] : "C")
                                .toUpperCase(),
                            style: const TextStyle(
                              color: colorDorado,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),

                        // CAMBIO 2: TÍTULO PRINCIPAL ES EL TITULAR
                        title: Text(
                          nombreTitular,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),

                        // CAMBIO 3: EL DIFUNTO PASA AL SUBTÍTULO
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            "Difunto: $nombreDifunto \n📞 $telefono",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                        isThreeLine: true,

                        // --- ACCIONES (LLAMAR Y BORRAR) ---
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón de llamar
                            IconButton(
                              icon: const Icon(
                                Icons.phone,
                                color: Colors.green,
                              ),
                              onPressed: () => _hacerLlamada(c['telefono']),
                              tooltip: 'Llamar',
                            ),
                            // Botón de borrar
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red[300],
                              ),
                              onPressed: () => _confirmarEliminar(c),
                              tooltip: 'Eliminar',
                            ),
                          ],
                        ),

                        // --- AL TOCAR LA TARJETA, VA A LOS CONTRATOS ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PantallaContratosCliente(cliente: c),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
