import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_login.dart';
import 'pantalla_inicio.dart';

// --- PALETA DE COLORES GLOBAL ---
// Si algún día quieres cambiar el tono, hazlo solo aquí.
const colorPrimario = Colors.black;
const colorDorado = Color(0xFFD4AF37);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qdmdiwrmokawigoupfwp.supabase.co', // Tu URL real
    anonKey: 'sb_publishable_d72oYB7OyTpbnabRdHlXeQ_L9h4ENgd', // Tu Key real
  );

  runApp(const MiFunerariaApp());
}

class MiFunerariaApp extends StatelessWidget {
  const MiFunerariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Funeraria Aris',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        primaryColor: colorPrimario,

        // 1. Esquema de colores principal
        colorScheme: const ColorScheme.light(
          primary: colorPrimario,
          secondary:
              colorDorado, // Tu dorado queda como color secundario/acento
          surface: Colors.white,
        ),

        // 2. Todos los AppBars de la app se verán así por defecto
        appBarTheme: const AppBarTheme(
          backgroundColor: colorPrimario,
          foregroundColor: colorDorado,
          elevation: 0,
          centerTitle: true,
        ),

        // 3. Todos los botones elevados (ElevatedButton) se verán así
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorPrimario,
            foregroundColor: colorDorado,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // 4. Todas las cajas de texto (TextField/TextFormField) se verán así al tocarlas
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorDorado, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.black87),
        ),
      ),

      // LÓGICA DE LOGIN INICIAL
      // LÓGICA DE LOGIN INICIAL
      home: Supabase.instance.client.auth.currentUser == null
          ? const PantallaLogin()
          : const PantallaInicio(),

      // 🌟 ESTA ES LA PIEZA QUE FALTABA: EL MAPA DE RUTAS
      routes: {'/home': (context) => const PantallaInicio()},
    );
  }
}
