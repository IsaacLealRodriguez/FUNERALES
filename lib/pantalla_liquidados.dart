import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_detalle_contrato.dart'; // Para poder entrar y ver quién cobró

class PantallaLiquidados extends StatefulWidget {
  const PantallaLiquidados({super.key});

  @override
  State<PantallaLiquidados> createState() => _PantallaLiquidadosState();
}

class _PantallaLiquidadosState extends State<PantallaLiquidados> {
  List<Map<String, dynamic>> _liquidados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarLiquidados();
  }

  Future<void> _cargarLiquidados() async {
    try {
      final response = await Supabase.instance.client
          .from('contratos')
          .select(
            '*, clientes(nombre_difunto, nombre_contacto), planes(nombre)',
          )
          .lte(
            'saldo_pendiente',
            0,
          ) // <--- ESTO FILTRA SOLO LOS QUE DEBEN 0 O MENOS
          .order('fecha_inicio', ascending: false); // Los más recientes primero

      if (mounted) {
        setState(() {
          _liquidados = List<Map<String, dynamic>>.from(response);
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CONTRATOS LIQUIDADOS"),
        backgroundColor: Colors.black,
        foregroundColor: const Color.fromARGB(
          255,
          212,
          175,
          55,
        ), // Color verde para indicar éxito
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _liquidados.isEmpty
          ? const Center(
              child: Text(
                "Aún no hay contratos liquidados.",
                style: TextStyle(color: Colors.white30),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _liquidados.length,
              itemBuilder: (context, index) {
                final contrato = _liquidados[index];
                final cliente = contrato['clientes'] ?? {};
                final plan = contrato['planes'] ?? {};

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      color: Colors.green,
                      width: 1,
                    ), // Borde verde
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    title: Text(
                      cliente['nombre_difunto'] ?? "Cliente",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${plan['nombre']} - Titular: ${cliente['nombre_contacto']}",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white24,
                    ),
                    onTap: () {
                      // Entrar para ver el historial de pagos y ver QUIÉN cobró
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantallaDetalleContrato(
                            contrato: contrato,
                            cliente: {},
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
