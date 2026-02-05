import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PantallaDetalleContrato extends StatefulWidget {
  final Map<String, dynamic> contrato;
  final Map<String, dynamic> cliente;

  const PantallaDetalleContrato({
    super.key,
    required this.contrato,
    required this.cliente,
  });

  @override
  State<PantallaDetalleContrato> createState() =>
      _PantallaDetalleContratoState();
}

class _PantallaDetalleContratoState extends State<PantallaDetalleContrato> {
  bool _cargando = false;
  late double _saldoActual;
  late String _estadoActual;
  late String _fechaProximoPagoStr;

  @override
  void initState() {
    super.initState();
    _saldoActual = (widget.contrato['saldo_pendiente'] as num).toDouble();
    _estadoActual = widget.contrato['estado'];
    _fechaProximoPagoStr =
        widget.contrato['proximo_pago'] ?? DateTime.now().toIso8601String();
  }

  Future<void> _registrarAbono(double monto) async {
    setState(() => _cargando = true);
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('pagos').insert({
        'contrato_id': widget.contrato['id'],
        'monto': monto,
        'fecha_pago': DateTime.now().toIso8601String(),
        'usuario_id': supabase.auth.currentUser?.id,
        'concepto': 'ABONO RUTINARIO',
      });

      double nuevoSaldo = _saldoActual - monto;
      if (nuevoSaldo < 0) nuevoSaldo = 0;
      String nuevoEstado = (nuevoSaldo <= 0) ? 'Liquidado' : 'Activo';

      DateTime fechaBase = DateTime.now();
      DateTime nuevaFechaPago = fechaBase;
      String frecuencia = widget.contrato['frecuencia_pago'];

      if (nuevoEstado == 'Activo') {
        switch (frecuencia) {
          case 'Semanal':
            nuevaFechaPago = fechaBase.add(const Duration(days: 7));
            break;
          case 'Quincenal':
            nuevaFechaPago = fechaBase.add(const Duration(days: 15));
            break;
          case 'Mensual':
            nuevaFechaPago = DateTime(
              fechaBase.year,
              fechaBase.month + 1,
              fechaBase.day,
            );
            break;
          default:
            nuevaFechaPago = fechaBase.add(const Duration(days: 7));
        }
      }

      await supabase
          .from('contratos')
          .update({
            'saldo_pendiente': nuevoSaldo,
            'estado': nuevoEstado,
            'proximo_pago': nuevoEstado == 'Activo'
                ? nuevaFechaPago.toIso8601String()
                : null,
          })
          .eq('id', widget.contrato['id']);

      if (mounted) {
        setState(() {
          _saldoActual = nuevoSaldo;
          _estadoActual = nuevoEstado;
          _fechaProximoPagoStr = nuevaFechaPago.toIso8601String();
          _cargando = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Abono registrado. Próximo pago: ${DateFormat('dd/MMM').format(nuevaFechaPago)}",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarDialogoAbono() {
    final montoController = TextEditingController();
    montoController.text = widget.contrato['monto_parcial'].toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Registrar Abono",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: montoController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            prefixText: "\$ ",
            prefixStyle: TextStyle(color: Colors.green),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              final monto = double.tryParse(montoController.text);
              if (monto != null && monto > 0) _registrarAbono(monto);
            },
            child: const Text("COBRAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorDorado = Color(0xFFD4AF37);
    final fechaPago = DateTime.tryParse(_fechaProximoPagoStr) ?? DateTime.now();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("DETALLE CONTRATO"),
        backgroundColor: Colors.black,
        foregroundColor: colorDorado,
      ),
      floatingActionButton: _estadoActual == 'Liquidado'
          ? null
          : FloatingActionButton.extended(
              onPressed: _cargando ? null : _mostrarDialogoAbono,
              backgroundColor: Colors.green,
              label: const Text(
                "ABONAR",
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.attach_money, color: Colors.white),
            ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _estadoActual == 'Liquidado'
                    ? Colors.green
                    : colorDorado,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _estadoActual.toUpperCase(),
                  style: TextStyle(
                    color: _estadoActual == 'Liquidado'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "SALDO PENDIENTE",
                  style: TextStyle(color: Colors.white54),
                ),
                Text(
                  "\$${_saldoActual.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_estadoActual != 'Liquidado') ...[
                  const Divider(color: Colors.white24, height: 30),
                  Text(
                    "Próximo pago: ${DateFormat('dd/MMM/yyyy').format(fechaPago)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "HISTORIAL",
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('pagos')
                  .stream(primaryKey: ['id'])
                  .eq('contrato_id', widget.contrato['id'])
                  .order('fecha_pago', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final pagos = snapshot.data!;
                if (pagos.isEmpty)
                  return const Center(
                    child: Text(
                      "Sin pagos",
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                return ListView.builder(
                  itemCount: pagos.length,
                  itemBuilder: (context, index) {
                    final p = pagos[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(
                        "\$${p['monto']}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'dd/MM HH:mm',
                        ).format(DateTime.parse(p['fecha_pago'])),
                        style: const TextStyle(color: Colors.white54),
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
