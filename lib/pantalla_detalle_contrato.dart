import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'generador_pdf.dart'; // Asegúrate de que este import no tenga errores

class PantallaDetalleContrato extends StatefulWidget {
  final Map<String, dynamic> contrato;

  const PantallaDetalleContrato({
    super.key,
    required this.contrato,
    required Map<dynamic, dynamic> cliente,
  });

  @override
  State<PantallaDetalleContrato> createState() =>
      _PantallaDetalleContratoState();
}

class _PantallaDetalleContratoState extends State<PantallaDetalleContrato> {
  bool _cargando = false;
  List<Map<String, dynamic>> _pagos = [];
  late double _saldoActual;
  late String _estadoActual;

  @override
  void initState() {
    super.initState();
    _saldoActual = (widget.contrato['saldo_pendiente'] as num).toDouble();
    _estadoActual = widget.contrato['estado'] ?? 'Activo';
    _cargarHistorialPagos();
  }

  // 1. CARGAR HISTORIAL DE PAGOS
  Future<void> _cargarHistorialPagos() async {
    try {
      final response = await Supabase.instance.client
          .from('pagos')
          .select()
          .eq('contrato_id', widget.contrato['id'])
          .order('fecha_pago', ascending: false);

      if (mounted) {
        setState(() {
          _pagos = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint("Error cargando pagos: $e");
    }
  }

  // 2. REGISTRAR UN NUEVO ABONO (VENTANA)
  Future<void> _registrarAbono() async {
    final montoController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            labelText: "Monto a abonar",
            labelStyle: TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.attach_money, color: Color(0xFFD4AF37)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
            ),
            child: const Text(
              "COBRAR",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _procesarPago(montoController.text);
            },
          ),
        ],
      ),
    );
  }

  // 3. LÓGICA DE COBRO CON IMPRESIÓN
  Future<void> _procesarPago(String montoStr) async {
    final monto = double.tryParse(montoStr);
    if (monto == null || monto <= 0) return;

    setState(() => _cargando = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // A. Insertar pago y RECUPERAR EL ID (.select().single())
      final pagoResponse = await supabase
          .from('pagos')
          .insert({
            'contrato_id': widget.contrato['id'],
            'monto': monto,
            'fecha_pago': DateTime.now().toIso8601String(),
            'metodo_pago': 'Efectivo',
            'usuario_id': userId,
          })
          .select()
          .single(); // <--- ESTO ES CLAVE PARA OBTENER EL FOLIO

      // B. Calcular nuevo saldo
      double nuevoSaldo = _saldoActual - monto;
      String nuevoEstado = _estadoActual;
      if (nuevoSaldo <= 0) {
        nuevoSaldo = 0;
        nuevoEstado = 'Liquidado';
      }

      // C. Actualizar contrato
      await supabase
          .from('contratos')
          .update({'saldo_pendiente': nuevoSaldo, 'estado': nuevoEstado})
          .eq('id', widget.contrato['id']);

      // D. Actualizar pantalla y PREGUNTAR POR RECIBO
      if (mounted) {
        setState(() {
          _saldoActual = nuevoSaldo;
          _estadoActual = nuevoEstado;
        });
        _cargarHistorialPagos();

        // --- AQUÍ LLAMAMOS A LA VENTANA DE IMPRESIÓN ---
        _mostrarDialogoExito(monto, nuevoSaldo, pagoResponse['id'].toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // 4. VENTANA DE ÉXITO E IMPRESIÓN
  void _mostrarDialogoExito(
    double montoPagado,
    double saldoRestante,
    String folio,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "¡Pago Exitoso!",
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
            SizedBox(height: 10),
            Text(
              "El pago se registró correctamente.",
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              "¿Deseas generar el comprobante?",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cerrar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
            ),
            icon: const Icon(Icons.print, color: Colors.black),
            label: const Text(
              "IMPRIMIR",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Llamada al generador
              GeneradorPDF.generarRecibo(
                nombreCliente:
                    widget.contrato['clientes']?['nombre_difunto'] ?? "Cliente",
                nombrePlan: widget.contrato['planes']?['nombre'] ?? "Servicio",
                montoAbono: montoPagado,
                saldoRestante: saldoRestante,
                folioPago: folio,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.contrato['clientes'] ?? {};
    final plan = widget.contrato['planes'] ?? {};
    final nombreDifunto = cliente['nombre_difunto'] ?? "N/A";
    final nombrePlan = plan['nombre'] ?? "Plan";
    final precioTotal = (plan['precio_total'] ?? 0).toString();
    const colorDorado = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("DETALLE DE CUENTA"),
        backgroundColor: Colors.black,
        foregroundColor: colorDorado,
      ),
      body: Column(
        children: [
          // RESUMEN
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreDifunto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(nombrePlan, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Costo Total",
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        Text(
                          "\$$precioTotal",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "SALDO PENDIENTE",
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        Text(
                          "\$${_saldoActual.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: _estadoActual == 'Liquidado'
                                ? Colors.green
                                : Colors.redAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_estadoActual == 'Liquidado')
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Center(
                      child: Text(
                        "✅ CUENTA PAGADA",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // LISTA DE PAGOS
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "HISTORIAL DE PAGOS",
                style: TextStyle(
                  color: colorDorado,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: _pagos.isEmpty
                ? const Center(
                    child: Text(
                      "No hay pagos registrados aún.",
                      style: TextStyle(color: Colors.white30),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _pagos.length,
                    itemBuilder: (context, index) {
                      final pago = _pagos[index];
                      final fechaRaw = DateTime.parse(
                        pago['fecha_pago'],
                      ).toLocal();
                      final fechaStr =
                          "${fechaRaw.day}/${fechaRaw.month}/${fechaRaw.year}";

                      return Card(
                        color: const Color(0xFF2C2C2C),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          title: Text(
                            "Abono en ${pago['metodo_pago']}",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            fechaStr,
                            style: const TextStyle(color: Colors.white54),
                          ),
                          // AQUÍ AGREGAMOS EL BOTÓN DE IMPRIMIR Y EL MONTO
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "+\$${pago['monto']}",
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(
                                  Icons.print,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  // Re-imprimir recibo histórico
                                  GeneradorPDF.generarRecibo(
                                    nombreCliente: nombreDifunto,
                                    nombrePlan: nombrePlan,
                                    montoAbono: (pago['monto'] as num)
                                        .toDouble(),
                                    saldoRestante:
                                        0, // No podemos calcular el saldo histórico fácilmente aquí, ponemos 0 o N/A
                                    folioPago: pago['id'].toString(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // BOTÓN PRINCIPAL
          if (_estadoActual != 'Liquidado')
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cargando ? null : _registrarAbono,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorDorado,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: const Icon(Icons.attach_money, color: Colors.black),
                label: _cargando
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "REGISTRAR ABONO",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
