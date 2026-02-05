import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_detalle_contrato.dart'; // Asegúrate de importar la pantalla de detalle que ya tienes

class PantallaContratosCliente extends StatefulWidget {
  final Map<String, dynamic> cliente;

  const PantallaContratosCliente({super.key, required this.cliente});

  @override
  State<PantallaContratosCliente> createState() =>
      _PantallaContratosClienteState();
}

class _PantallaContratosClienteState extends State<PantallaContratosCliente> {
  List<Map<String, dynamic>> _contratos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarContratosDelCliente();
  }

  Future<void> _cargarContratosDelCliente() async {
    try {
      final response = await Supabase.instance.client
          .from('contratos')
          .select(
            '*, planes(*), clientes(*)',
          ) // Traemos info del plan y cliente
          .eq(
            'cliente_id',
            widget.cliente['id'],
          ) // FILTRO CLAVE: Solo de este cliente
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _contratos = List<Map<String, dynamic>>.from(response);
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando contratos: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.cliente['nombre_contacto'] ?? "Contratos"),
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFD4AF37),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            )
          : _contratos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.folder_off, color: Colors.white54, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "Este cliente no tiene contratos activos.",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _contratos.length,
              itemBuilder: (context, index) {
                final contrato = _contratos[index];
                final planNombre =
                    contrato['planes']?['nombre'] ?? "Plan Desconocido";
                final estado = contrato['estado'] ?? 'Activo';
                final saldo = (contrato['saldo_pendiente'] as num).toDouble();

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: estado == 'Liquidado'
                          ? Colors.green
                          : const Color(0xFFD4AF37),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      planNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Difunto: ${widget.cliente['nombre_difunto']}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          estado,
                          style: TextStyle(
                            color: estado == 'Liquidado'
                                ? Colors.green
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (saldo > 0)
                          Text(
                            "Debe: \$${saldo.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      // Navegar al detalle para cobrar
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantallaDetalleContrato(
                            contrato: contrato,
                            cliente: widget.cliente,
                          ),
                        ),
                      ).then(
                        (_) => _cargarContratosDelCliente(),
                      ); // Recargar al volver
                    },
                  ),
                );
              },
            ),
    );
  }
}
