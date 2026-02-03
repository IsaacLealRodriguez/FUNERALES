import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaNuevoContrato extends StatefulWidget {
  // Ahora aceptamos un parámetro opcional
  final Map<String, dynamic>? planPreseleccionado;

  const PantallaNuevoContrato({super.key, this.planPreseleccionado});

  @override
  State<PantallaNuevoContrato> createState() => _PantallaNuevoContratoState();
}

class _PantallaNuevoContratoState extends State<PantallaNuevoContrato> {
  final _formKey = GlobalKey<FormState>();
  bool _cargando = true;
  bool _guardando = false;

  List<Map<String, dynamic>> _listaClientes = [];
  List<Map<String, dynamic>> _listaPlanes = [];

  String? _clienteId;
  String? _planId;
  String _frecuencia = 'Mensual';

  double _precioPlan = 0.0;
  final TextEditingController _anticipoController = TextEditingController();

  final Color _colorFondo = Colors.black;
  final Color _colorDorado = const Color(0xFFD4AF37);
  final Color _colorCard = const Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final responses = await Future.wait([
        Supabase.instance.client
            .from('clientes')
            .select('id, nombre_difunto')
            .order('created_at'),
        Supabase.instance.client
            .from('planes')
            .select('id, nombre, precio_total')
            .order('precio_total'),
      ]);

      if (mounted) {
        setState(() {
          _listaClientes = List<Map<String, dynamic>>.from(responses[0]);
          _listaPlanes = List<Map<String, dynamic>>.from(responses[1]);

          // LÓGICA DE PRE-SELECCIÓN
          if (widget.planPreseleccionado != null) {
            final planViniendo = widget.planPreseleccionado!;
            // Buscamos el ID en la lista cargada para asegurar consistencia
            _planId = planViniendo['id'].toString();
            _precioPlan = (planViniendo['precio_total'] as num).toDouble();
          }

          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ... (El resto del código _guardarVenta y build es igual que antes,
  // solo asegúrate de que el Dropdown de planes se actualice si cambia)

  Future<void> _guardarVenta() async {
    // ... (Mismo código de guardar que te di en la respuesta anterior)
    // Copia el bloque _guardarVenta de la respuesta anterior aquí
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final anticipo = double.tryParse(_anticipoController.text) ?? 0.0;
      final saldoPendiente = _precioPlan - anticipo;
      final estado = saldoPendiente <= 0 ? 'Liquidado' : 'Activo';

      final contratoRes = await Supabase.instance.client
          .from('contratos')
          .insert({
            'cliente_id': _clienteId,
            'plan_id': _planId,
            'frecuencia_pago': _frecuencia,
            'saldo_pendiente': saldoPendiente,
            'estado': estado,
            'fecha_inicio': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final contratoId = contratoRes['id'];

      if (anticipo > 0) {
        await Supabase.instance.client.from('pagos').insert({
          'contrato_id': contratoId,
          'monto': anticipo,
          'metodo_pago': 'Efectivo',
          'concepto': 'Enganche / Primer Pago',
          'fecha_pago': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("¡Venta registrada!"),
            backgroundColor: _colorDorado,
          ),
        );
        // Si venimos de planes, hacemos pop dos veces o usamos pushReplacement en el origen
        // Por seguridad, hacemos pop.
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (El build es idéntico, solo asegúrate de copiarlo completo del paso anterior)
    // Lo pego aquí resumido para que veas dónde encaja
    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        title: const Text("NUEVA VENTA"),
        backgroundColor: Colors.black,
        foregroundColor: _colorDorado,
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: _colorDorado))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Dropdown Clientes...
                    _buildDropdown(
                      label: "Cliente",
                      value: _clienteId,
                      items: _listaClientes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Text(
                                c['nombre_difunto'],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _clienteId = v),
                    ),
                    const SizedBox(height: 15),

                    // Dropdown Planes (Aquí se verá reflejado el cambio automático)
                    _buildDropdown(
                      label: "Plan",
                      value: _planId,
                      items: _listaPlanes
                          .map(
                            (p) => DropdownMenuItem(
                              value: p['id'].toString(),
                              child: Text(
                                p['nombre'],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _planId = v;
                          final planObj = _listaPlanes.firstWhere(
                            (p) => p['id'].toString() == v,
                          );
                          _precioPlan = (planObj['precio_total'] as num)
                              .toDouble();
                        });
                      },
                    ),

                    // Resto del formulario (Frecuencia, Anticipo, Botón)...
                    // ... Pega aquí el resto de widgets del código anterior ...
                    // (Si necesitas el código completo completo dímelo, pero es igual al anterior)
                    const SizedBox(height: 15),
                    _buildDropdown(
                      label: "Frecuencia",
                      value: _frecuencia,
                      items: ["Semanal", "Quincenal", "Mensual"]
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                f,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _frecuencia = v!),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _anticipoController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Anticipo",
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: _colorCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15),
                      color: _colorCard,
                      child: Text(
                        "Saldo Restante: \$${(_precioPlan - (double.tryParse(_anticipoController.text) ?? 0)).toStringAsFixed(2)}",
                        style: TextStyle(
                          color: _colorDorado,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorDorado,
                        ),
                        onPressed: _guardando ? null : _guardarVenta,
                        child: Text(
                          "REGISTRAR",
                          style: TextStyle(
                            color: Colors.black,
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF2C2C2C),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: _colorCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
