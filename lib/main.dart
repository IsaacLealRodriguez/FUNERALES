import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_login.dart';
import 'pantalla_inicio.dart'; // <--- FALTABA ESTA IMPORTACIÓN

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
      title: 'Gestión Funeraria',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        primaryColor: Colors.black,

        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Color(0xFFD4AF37),
          surface: Colors.white,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Color(0xFFD4AF37),
          elevation: 0,
          centerTitle: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: const Color(0xFFD4AF37),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.black87),
        ),
      ),

      // AQUÍ ES DONDE SUCEDE LA MAGIA DEL LOGIN
      home: Supabase.instance.client.auth.currentUser == null
          ? const PantallaLogin()
          : const PantallaInicio(),
    );
  }
}
