import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// CORRECCIÓN: Importamos el archivo del login, no el de la imagen
import 'pantalla_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:
        'https://qdmdiwrmokawigoupfwp.supabase.co', // <--- PEGA AQUÍ TU URL REAL DE SUPABASE
    anonKey:
        'sb_publishable_d72oYB7OyTpbnabRdHlXeQ_L9h4ENgd', // <--- PEGA AQUÍ TU ANON KEY REAL
  );

  runApp(const MiFunerariaApp());
}

class MiFunerariaApp extends StatelessWidget {
  const MiFunerariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión Funeraria',
      theme: ThemeData(
        useMaterial3: true,
        // Fondo casi blanco para limpieza
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        primaryColor: Colors.black, // Color principal NEGRO

        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Color(0xFFD4AF37), // DORADO METALICO
          surface: Colors.white,
        ),

        // Barras Superiores (Negras con texto Dorado)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Color(0xFFD4AF37), // Texto/Iconos Dorados
          elevation: 0,
          centerTitle: true,
        ),

        // Botones (Negros con texto Dorado)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: const Color(0xFFD4AF37), // Texto Dorado
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Input Text (Bordes Dorados al seleccionar)
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.black87),
        ),
      ),
      home: const PantallaLogin(),
    );
  }
}
