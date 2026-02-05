import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha bonito

class PantallaNuevoContrato extends StatefulWidget {
  final Map<String, dynamic>? planPreseleccionado;

  const PantallaNuevoContrato({super.key, this.planPreseleccionado});

  @override
  State<PantallaNuevoContrato> createState() => _PantallaNuevoContratoState();
}

class _PantallaNuevoContratoState extends State<PantallaNuevoContrato> {
  // --- CONTROLADORES ---
  final _nombreDifuntoController = TextEditingController();
  final _nombreContactoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _engancheController = TextEditingController(text: "0");
  final _montoParcialController = TextEditingController(text: "0");

  // --- VARIABLES DE ESTADO ---
  bool _cargando = false;
  bool _esNuevoCliente = true;

  // Listas y Selecciones
  List<Map<String, dynamic>> _listaClientesExistentes = [];
  Map<String, dynamic>? _clienteExistenteSeleccionado;
  List<Map<String, dynamic>> _listaPlanes = [];
  Map<String, dynamic>? _planSeleccionado;

  // --- LÓGICA DE FECHAS Y COBRANZA ---
  String _frecuenciaPago = 'Semanal';
  final List<String> _frecuencias = ['Semanal', 'Quincenal', 'Mensual'];
  DateTime _fechaProximoPago = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarPlanes();
    _cargarClientesExistentes();
    _calcularFechaPago(); // Calcula la fecha inicial al abrir
  }

  // 1. FUNCIÓN INTELIGENTE DE FECHAS
  void _calcularFechaPago() {
    final hoy = DateTime.now();
    DateTime nuevaFecha;

    switch (_frecuenciaPago) {
      case 'Semanal':
        nuevaFecha = hoy.add(const Duration(days: 7));
        break;
      case 'Quincenal':
        nuevaFecha = hoy.add(const Duration(days: 15));
        break;
      case 'Mensual':
        // Suma 1 mes exacto (maneja años bisiestos y cambios de año solo)
        nuevaFecha = DateTime(hoy.year, hoy.month + 1, hoy.day);
        break;
      default:
        nuevaFecha = hoy.add(const Duration(days: 7));
    }

    setState(() {
      _fechaProximoPago = nuevaFecha;
    });
  }

  // 2. CARGAR PLANES
  Future<void> _cargarPlanes() async {
    try {
      final response = await Supabase.instance.client
          .from('planes')
          .select()
          .order('precio_total', ascending: true);

      setState(() {
        _listaPlanes = List<Map<String, dynamic>>.from(response);

        // Preseleccionar plan si viene de la pantalla anterior
        if (widget.planPreseleccionado != null) {
          try {
            _planSeleccionado = _listaPlanes.firstWhere(
              (p) => p['id'] == widget.planPreseleccionado!['id'],
            );
          } catch (e) {
            if (_listaPlanes.isNotEmpty) _planSeleccionado = _listaPlanes[0];
          }
        } else if (_listaPlanes.isNotEmpty) {
          _planSeleccionado = _listaPlanes[0];
        }
      });
    } catch (e) {
      debugPrint('Error cargando planes: $e');
    }
  }

  // 3. CARGAR CLIENTES
  Future<void> _cargarClientesExistentes() async {
    try {
      final response = await Supabase.instance.client
          .from('clientes')
          .select('id, nombre_contacto, nombre_difunto, telefono')
          .order('nombre_contacto', ascending: true);

      setState(() {
        _listaClientesExistentes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error cargando clientes: $e');
    }
  }

  // 4. GUARDAR CONTRATO
  Future<void> _guardarContrato() async {
    if (_planSeleccionado == null) return;

    // VALIDACIONES
    if (_esNuevoCliente) {
      if (_nombreDifuntoController.text.isEmpty ||
          _nombreContactoController.text.isEmpty) {
        _mostrarError("Faltan nombres obligatorios");
        return;
      }
    } else {
      if (_clienteExistenteSeleccionado == null) {
        _mostrarError("Debes seleccionar un cliente existente");
        return;
      }
    }

    setState(() => _cargando = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      int clienteId;

      // A. OBTENER ID CLIENTE
      if (_esNuevoCliente) {
        final clienteData = await supabase
            .from('clientes')
            .insert({
              'nombre_difunto': _nombreDifuntoController.text.toUpperCase(),
              'nombre_contacto': _nombreContactoController.text.toUpperCase(),
              'telefono': _telefonoController.text,
              'direccion': _direccionController.text.toUpperCase(),
              'fecha_registro': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        clienteId = clienteData['id'];
      } else {
        clienteId = _clienteExistenteSeleccionado!['id'];
      }

      // B. CÁLCULOS FINANCIEROS
      final double precioPlan = (_planSeleccionado!['precio_total'] as num)
          .toDouble();
      final double enganche = double.tryParse(_engancheController.text) ?? 0.0;

      // Seguridad: Enganche no puede ser mayor al precio
      if (enganche > precioPlan) {
        _mostrarError(
          "El enganche (\$$enganche) supera el total (\$$precioPlan).",
        );
        setState(() => _cargando = false);
        return;
      }

      final double cuota = double.tryParse(_montoParcialController.text) ?? 0.0;
      final double saldoPendiente = precioPlan - enganche;
      final String estado = saldoPendiente <= 0 ? 'Liquidado' : 'Activo';

      // C. INSERTAR CONTRATO (CON LA FECHA DE COBRO CALCULADA)
      final contratoData = await supabase
          .from('contratos')
          .insert({
            'cliente_id': clienteId,
            'plan_id': _planSeleccionado!['id'],
            'saldo_pendiente': saldoPendiente,
            'monto_parcial': cuota,
            'frecuencia_pago': _frecuenciaPago,
            'estado': estado,
            'fecha_inicio': DateTime.now().toIso8601String(),
            // --- AQUÍ ESTÁ LA CLAVE PARA SABER A QUIÉN COBRAR ---
            'proximo_pago': _fechaProximoPago.toIso8601String(),
          })
          .select()
          .single();

      final contratoId = contratoData['id'];

      // D. REGISTRAR PAGO DEL ENGANCHE
      if (enganche > 0 && userId != null) {
        await supabase.from('pagos').insert({
          'contrato_id': contratoId,
          'monto': enganche,
          'fecha_pago': DateTime.now().toIso8601String(),
          'metodo_pago': 'Efectivo',
          'usuario_id': userId,

          // CAMBIA 'concepto' POR EL NOMBRE QUE TENGAS EN TU BASE DE DATOS
          // Si no tienes ninguna columna para notas, BORRA ESTA LÍNEA
          'concepto': 'ENGANCHE INICIAL',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Contrato creado! Cobro programado."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _mostrarError("Error: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estilos
    const colorDorado = Color(0xFFD4AF37);
    final inputBorder = OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white30),
      borderRadius: BorderRadius.circular(8),
    );
    final inputBorderFocus = OutlineInputBorder(
      borderSide: const BorderSide(color: colorDorado),
      borderRadius: BorderRadius.circular(8),
    );

    // Cálculos visuales
    double precio = _planSeleccionado != null
        ? (_planSeleccionado!['precio_total'] as num).toDouble()
        : 0.0;
    double enganche = double.tryParse(_engancheController.text) ?? 0.0;
    double saldo = precio - enganche;

    // Formatear Fecha (Ej: 15/10/2023)
    // Nota: Usamos formato numérico para evitar errores si el idioma español no está cargado
    String fechaVisual = DateFormat('dd/MM/yyyy').format(_fechaProximoPago);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("NUEVO CONTRATO"),
        backgroundColor: Colors.black,
        foregroundColor: colorDorado,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TIPO DE CLIENTE ---
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _esNuevoCliente = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _esNuevoCliente
                              ? colorDorado
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(9),
                          ),
                        ),
                        child: Text(
                          "Nuevo Cliente",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _esNuevoCliente
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _esNuevoCliente = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_esNuevoCliente
                              ? colorDorado
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(9),
                          ),
                        ),
                        child: Text(
                          "Cliente Existente",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_esNuevoCliente
                                ? Colors.black
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- FORMULARIO CLIENTE ---
            if (_esNuevoCliente) ...[
              _inputCampo(
                "Nombre del Difunto",
                _nombreDifuntoController,
                Icons.person,
                inputBorder,
                inputBorderFocus,
              ),
              const SizedBox(height: 10),
              _inputCampo(
                "Nombre del Titular",
                _nombreContactoController,
                Icons.account_box,
                inputBorder,
                inputBorderFocus,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _inputCampo(
                      "Teléfono",
                      _telefonoController,
                      Icons.phone,
                      inputBorder,
                      inputBorderFocus,
                      numero: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _inputCampo(
                      "Dirección",
                      _direccionController,
                      Icons.home,
                      inputBorder,
                      inputBorderFocus,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue val) {
                  if (val.text.isEmpty)
                    return const Iterable<Map<String, dynamic>>.empty();
                  return _listaClientesExistentes.where(
                    (c) => c['nombre_contacto']
                        .toString()
                        .toLowerCase()
                        .contains(val.text.toLowerCase()),
                  );
                },
                displayStringForOption: (c) => c['nombre_contacto'],
                onSelected: (sel) =>
                    setState(() => _clienteExistenteSeleccionado = sel),
                fieldViewBuilder: (ctx, ctrl, focus, onEdit) => TextField(
                  controller: ctrl,
                  focusNode: focus,
                  onEditingComplete: onEdit,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Buscar por Titular",
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: colorDorado),
                    enabledBorder: inputBorder,
                    focusedBorder: inputBorderFocus,
                    helperText: _clienteExistenteSeleccionado != null
                        ? "Seleccionado: ${_clienteExistenteSeleccionado!['nombre_contacto']}"
                        : "Escribe para buscar...",
                    helperStyle: TextStyle(
                      color: _clienteExistenteSeleccionado != null
                          ? Colors.green
                          : Colors.white54,
                    ),
                  ),
                ),
                optionsViewBuilder: (ctx, onSel, opts) => Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: const Color(0xFF1E1E1E),
                    elevation: 4,
                    child: SizedBox(
                      width: MediaQuery.of(ctx).size.width - 40,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: opts.length,
                        itemBuilder: (ctx, i) {
                          final o = opts.elementAt(i);
                          return ListTile(
                            title: Text(
                              o['nombre_contacto'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "Difunto: ${o['nombre_difunto'] ?? 'N/A'}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            onTap: () => onSel(o),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),

            // --- SECCIÓN DE PAGOS Y FECHAS ---
            const Text(
              "PLAN Y FECHAS DE PAGO",
              style: TextStyle(
                color: colorDorado,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<Map<String, dynamic>>(
              dropdownColor: const Color(0xFF1E1E1E),
              value: _planSeleccionado,
              decoration: InputDecoration(
                labelText: "Selecciona un Plan",
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: inputBorder,
                focusedBorder: inputBorderFocus,
                prefixIcon: const Icon(Icons.inventory_2, color: colorDorado),
              ),
              style: const TextStyle(color: Colors.white),
              items: _listaPlanes
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text("${p['nombre']} - \$${p['precio_total']}"),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _planSeleccionado = val),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1E1E1E),
                    value: _frecuenciaPago,
                    decoration: InputDecoration(
                      labelText: "Frecuencia",
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorderFocus,
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: _frecuencias
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _frecuenciaPago = val);
                        _calcularFechaPago(); // Recalcular fecha al cambiar
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _inputCampo(
                    "Cuota",
                    _montoParcialController,
                    Icons.monetization_on,
                    inputBorder,
                    inputBorderFocus,
                    numero: true,
                  ),
                ),
              ],
            ),

            // --- VISUALIZADOR DE FECHA (CALENDARIO TIPO ALERT) ---
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF15202B), // Azul muy oscuro
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Colors.blueAccent,
                    size: 30,
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PRÓXIMO PAGO TOCA EL:",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        fechaVisual, // Aquí se muestra la fecha calculada
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "($_frecuenciaPago)",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            TextField(
              controller: _engancheController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: "Enganche (Pago Hoy)",
                labelStyle: const TextStyle(color: Colors.greenAccent),
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: Colors.greenAccent,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.greenAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.greenAccent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) => setState(() {}),
            ),

            const SizedBox(height: 30),

            // --- RESUMEN FINAL ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorDorado.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _filaRes(
                    "Precio Plan:",
                    "\$${precio.toStringAsFixed(2)}",
                    Colors.white,
                  ),
                  _filaRes(
                    "(-) Enganche:",
                    "\$${enganche.toStringAsFixed(2)}",
                    Colors.greenAccent,
                  ),
                  const Divider(color: Colors.white24),
                  _filaRes(
                    "SALDO PENDIENTE:",
                    "\$${saldo.toStringAsFixed(2)}",
                    saldo < 0 ? Colors.red : colorDorado,
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _cargando ? null : _guardarContrato,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorDorado,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "CREAR CONTRATO",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _filaRes(String t, String v, Color c, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            t,
            style: TextStyle(color: Colors.white70, fontSize: isBold ? 16 : 14),
          ),
          Text(
            v,
            style: TextStyle(
              color: c,
              fontSize: isBold ? 20 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCampo(
    String label,
    TextEditingController controller,
    IconData icon,
    InputBorder border,
    InputBorder focusBorder, {
    bool numero = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numero ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60),
        enabledBorder: border,
        focusedBorder: focusBorder,
      ),
    );
  }
}
