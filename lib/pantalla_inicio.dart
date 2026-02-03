import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// IMPORTS DE TUS PANTALLAS
import 'pantalla_clientes.dart';
import 'pantalla_planes.dart';
import 'pantalla_login.dart';
import 'pantalla_reportes.dart';
import 'pantalla_historial.dart'; // <--- Conecta con la pantalla que acabamos de arreglar

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  // COLORES TEMA BLACK & GOLD
  final Color _colorFondo = Colors.black;
  final Color _colorDorado = const Color(0xFFD4AF37);
  final Color _colorCard = const Color(0xFF1E1E1E);

  // Variable para ventas (placeholder)
  double _ventasMes = 0.00;

  Future<void> _cerrarSesion(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PantallaLogin()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? "Admin";

    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: _colorDorado,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PANEL DE CONTROL",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
            tooltip: "Cerrar Sesión",
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white12, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. SECCIÓN DE CABECERA Y LOGO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              decoration: BoxDecoration(
                color:
                    _colorCard, // Gris oscuro en lugar de negro total para diferenciar
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _colorDorado.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // --- LOGO / ICONO ---
                  Container(
                    height: 80,
                    width: 80,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: _colorDorado, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _colorDorado.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(Icons.business, color: _colorDorado, size: 40),
                    // Si tienes una imagen real usa:
                    // image: const DecorationImage(image: AssetImage('assets/logo.png')),
                  ),

                  Text(
                    "Bienvenido",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tarjeta de Resumen (Ventas)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: _colorDorado.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Ventas del Mes: ",
                          style: TextStyle(color: _colorDorado),
                        ),
                        Text(
                          "\$ ${_ventasMes.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 2. GRID DE BOTONES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount:
                    2, // Cambié a 2 columnas para que los botones sean más grandes y legibles
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.3,
                children: [
                  // BOTÓN PLANES (VENTA) - Destacado
                  _BotonMenu(
                    icono: Icons.inventory_2,
                    texto: "NUEVA VENTA\n(CATÁLOGO)",
                    colorIcono: _colorDorado,
                    esDestacado: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PantallaPlanes()),
                    ),
                  ),

                  // BOTÓN HISTORIAL (CONTRATOS)
                  _BotonMenu(
                    icono: Icons.history_edu,
                    texto: "HISTORIAL &\nPAGOS",
                    colorIcono: Colors.white,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PantallaHistorial(),
                      ),
                    ),
                  ),

                  // BOTÓN CLIENTES
                  _BotonMenu(
                    icono: Icons.people,
                    texto: "CLIENTES",
                    colorIcono: Colors.white,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PantallaClientes(),
                      ),
                    ),
                  ),

                  // BOTÓN REPORTES
                  _BotonMenu(
                    icono: Icons.pie_chart,
                    texto: "REPORTES",
                    colorIcono: Colors.white,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PantallaReportes(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Diseño del Botón (Estilo Black & Gold)
class _BotonMenu extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color colorIcono;
  final VoidCallback onTap;
  final bool esDestacado;

  const _BotonMenu({
    required this.icono,
    required this.texto,
    required this.onTap,
    this.colorIcono = Colors.white,
    this.esDestacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorCard = const Color(0xFF1E1E1E);
    final colorDorado = const Color(0xFFD4AF37);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: esDestacado ? colorDorado.withOpacity(0.15) : colorCard,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: esDestacado ? colorDorado : Colors.white10,
            width: esDestacado ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 32,
              color: esDestacado ? colorDorado : colorIcono,
            ),
            const SizedBox(height: 10),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: esDestacado ? colorDorado : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
