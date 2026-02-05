import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importamos tus pantallas para la navegación
import 'pantalla_inicio.dart';
import 'pantalla_clientes.dart';
import 'pantalla_planes.dart';
import 'pantalla_liquidados.dart';
import 'pantalla_login.dart';
import 'pantallaRutaCobro.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? "Usuario";
    const colorDorado = Color(0xFFD4AF37);

    return Drawer(
      backgroundColor: const Color(0xFF1E1E1E), // Gris oscuro elegante
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // CABECERA DEL MENÚ
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.black,
              image: DecorationImage(
                image: AssetImage(
                  'assets/blanco.png',
                ), // Tu logo de fondo suave si quieres
                opacity: 0.1, // Muy transparente para que no estorbe
                fit: BoxFit.cover,
              ),
            ),
            accountName: const Text(
              "FUNERALES ARIS",
              style: TextStyle(
                color: colorDorado,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            accountEmail: Text(
              email,
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorDorado,
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : "A",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),

          // OPCIONES DEL MENÚ
          _itemMenu(context, Icons.dashboard, "Inicio", const PantallaInicio()),
          _itemMenu(
            context,
            Icons.people,
            "Directorio Clientes",
            const PantallaClientes(),
          ),
          _itemMenu(
            context,
            Icons.inventory_2,
            "Planes y Servicios",
            const PantallaPlanes(),
          ),
          _itemMenu(
            context,
            Icons.history_edu,
            "Historial Liquidados",
            const PantallaLiquidados(),
          ),

          const Divider(color: Colors.white24),
          // --- BOTÓN RUTA DE COBRO ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.green, // Color verde para indicar dinero/cobro
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PantallaRutaCobro(),
                  ),
                );
              },
              icon: const Icon(
                Icons.map_outlined,
                size: 30,
              ), // Icono de mapa/ruta
              label: const Text(
                "IR A RUTA DE COBRO",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // BOTÓN CERRAR SESIÓN
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Cerrar Sesión",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PantallaLogin(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para crear botones de menú rápido
  Widget _itemMenu(
    BuildContext context,
    IconData icon,
    String texto,
    Widget pantalla,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(texto, style: const TextStyle(color: Colors.white)),
      onTap: () {
        // Cierra el menú y va a la pantalla
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => pantalla),
        );
      },
    );
  }
}
