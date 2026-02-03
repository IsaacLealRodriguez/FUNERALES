import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_inicio.dart'; // Asegúrate de tener este archivo creado

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _iniciarSesion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PantallaInicio()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ocurrió un error inesperado"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos el color dorado para usarlo fácil
    const colorDorado = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        0,
        0,
        0,
      ), // Gris oscuro (RGB 75,75,75)
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- TU LOGO ---
              Container(
                height:
                    250, // Ajusté un poco el tamaño para que no desborde en pantallas chicas
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  // Asegúrate de que esta imagen exista en pubspec.yaml
                  image: const DecorationImage(
                    image: AssetImage('assets/blanco.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // TÍTULO
              const Text(
                "FUNERALES ARIS",
                style: TextStyle(
                  fontSize: 32, // Un poco más pequeño para evitar overflow
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Ingresa tus credenciales",
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              const SizedBox(height: 40),

              // INPUT EMAIL
              TextField(
                controller: _emailController,
                style: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                ), // IMPORTANTE: Texto blanco
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Correo Electrónico",
                  labelStyle: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  // Bordes personalizados para fondo oscuro
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromRGBO(212, 175, 55, 1),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // INPUT PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                ), // IMPORTANTE: Texto blanco
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  // Bordes personalizados para fondo oscuro
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 212, 175, 55),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // BOTÓN LOGIN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                      255,
                      212,
                      175,
                      55,
                    ), // Fondo blanco
                    foregroundColor:
                        Colors.black, // Texto negro (mejor contraste)
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        5,
                      ), // Bordes menos redondos (estilo serio)
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "INGRESAR",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
