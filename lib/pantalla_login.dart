import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_inicio.dart'; // Conexión vital con el nuevo menú

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _cargando = false; // El guardián de nuestro botón

  Future<void> _iniciarSesion() async {
    // 1. Evitamos ejecuciones si ya hay una en curso (doble seguridad)
    if (_cargando) return;

    setState(() => _cargando = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null && mounted) {
        // Navegar a la pantalla principal
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      _mostrarAlerta(e.message);
    } catch (e) {
      _mostrarAlerta("Ocurrió un error inesperado. Revisa tu conexión.");
    } finally {
      // 2. Importante: Liberamos el botón siempre, falle o tenga éxito
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarAlerta(String msj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msj), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorDorado = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/blanco.png',
                height: 380,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),

              // 2. CAJA DE TEXTO: CORREO
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Correo electrónico",
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.email, color: colorDorado),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: colorDorado),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: colorDorado, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. CAJA DE TEXTO: CONTRASEÑA
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.lock, color: colorDorado),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: colorDorado),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: colorDorado, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 4. EL BOTÓN DE INGRESAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _iniciarSesion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorDorado,
                    disabledBackgroundColor: colorDorado.withOpacity(0.3),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "INGRESAR",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
