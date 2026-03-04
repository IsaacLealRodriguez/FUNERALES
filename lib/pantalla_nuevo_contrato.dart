import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
// Importa el paquete de mapas y tu pantalla de selector
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';
import 'selector_mapa.dart';

class PantallaNuevoContrato extends StatefulWidget {
  final Map<String, dynamic>? planPreseleccionado;
  const PantallaNuevoContrato({super.key, this.planPreseleccionado});

  @override
  State<PantallaNuevoContrato> createState() => _PantallaNuevoContratoState();
}

class _PantallaNuevoContratoState extends State<PantallaNuevoContrato> {
  // --- 1. CONTROLADORES ---
  final _nombreDifuntoController = TextEditingController();
  final _nombreContactoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _engancheController = TextEditingController(text: "0");
  final _montoParcialController = TextEditingController(text: "0");

  // --- 2. VARIABLES DE ESTADO ---
  bool _cargando = false;
  bool _esNuevoCliente = true;
  List<Map<String, dynamic>> _listaClientesExistentes = [];
  Map<String, dynamic>? _clienteExistenteSeleccionado;
  List<Map<String, dynamic>> _listaPlanes = [];
  Map<String, dynamic>? _planSeleccionado;

  // Variables para Coordenadas GPS
  double? _latitud;
  double? _longitud;

  String _frecuenciaPago = 'Semanal';
  final List<String> _frecuencias = ['Semanal', 'Quincenal', 'Mensual'];
  DateTime _fechaProximoPago = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarPlanes();
    _cargarClientesExistentes();
    _calcularFechaPago();
  }

  @override
  void dispose() {
    _nombreDifuntoController.dispose();
    _nombreContactoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _engancheController.dispose();
    _montoParcialController.dispose();
    super.dispose();
  }

  // --- 3. LÓGICA DE MAPAS ---
  // --- 3. LÓGICA DE MAPAS ---
  Future<void> _abrirSelectorMapa() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectorMapa()),
    );

    if (resultado != null) {
      setState(() {
        // 🌟 LA SOLUCIÓN: Usar addressName que sí es un String
        _direccionController.text = resultado.addressName;

        _latitud = resultado.latLong.latitude;
        _longitud = resultado.latLong.longitude;
      });
    }
  }
  // --- 4. LÓGICA DE NEGOCIO ---

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
        nuevaFecha = DateTime(hoy.year, hoy.month + 1, hoy.day);
        break;
      default:
        nuevaFecha = hoy.add(const Duration(days: 7));
    }
    setState(() => _fechaProximoPago = nuevaFecha);
  }

  Future<void> _cargarPlanes() async {
    try {
      final response = await Supabase.instance.client
          .from('planes')
          .select()
          .order('precio_total', ascending: true);
      setState(() {
        _listaPlanes = List<Map<String, dynamic>>.from(response);
        if (widget.planPreseleccionado != null) {
          _planSeleccionado = _listaPlanes.firstWhere(
            (p) => p['id'] == widget.planPreseleccionado!['id'],
            orElse: () => _listaPlanes.isNotEmpty ? _listaPlanes[0] : {},
          );
        } else if (_listaPlanes.isNotEmpty) {
          _planSeleccionado = _listaPlanes[0];
        }
      });
    } catch (e) {
      debugPrint('Error cargando planes: $e');
    }
  }

  Future<void> _cargarClientesExistentes() async {
    try {
      final response = await Supabase.instance.client
          .from('clientes')
          .select(
            'id, nombre_contacto, nombre_difunto, telefono, direccion, latitud, longitud',
          )
          .order('nombre_contacto', ascending: true);
      setState(
        () => _listaClientesExistentes = List<Map<String, dynamic>>.from(
          response,
        ),
      );
    } catch (e) {
      debugPrint('Error cargando clientes: $e');
    }
  }

  Future<void> _guardarContrato() async {
    if (_planSeleccionado == null) return;
    if (_esNuevoCliente) {
      if (_nombreContactoController.text.isEmpty ||
          _direccionController.text.isEmpty) {
        _mostrarError("Nombre y Dirección son obligatorios");
        return;
      }
    } else if (_clienteExistenteSeleccionado == null) {
      _mostrarError("Selecciona un cliente de la lista");
      return;
    }

    setState(() => _cargando = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      int clienteId;

      if (_esNuevoCliente) {
        final clienteData = await supabase
            .from('clientes')
            .insert({
              'nombre_difunto': _nombreDifuntoController.text.toUpperCase(),
              'nombre_contacto': _nombreContactoController.text.toUpperCase(),
              'telefono': _telefonoController.text,
              'direccion': _direccionController.text.toUpperCase(),
              'latitud': _latitud,
              'longitud': _longitud,
              'fecha_registro': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        clienteId = clienteData['id'];
      } else {
        clienteId = _clienteExistenteSeleccionado!['id'];
      }

      final double precioPlan = (_planSeleccionado!['precio_total'] as num)
          .toDouble();
      final double enganche = double.tryParse(_engancheController.text) ?? 0.0;
      final double cuota = double.tryParse(_montoParcialController.text) ?? 0.0;
      final double saldoPendiente = precioPlan - enganche;

      final contratoData = await supabase
          .from('contratos')
          .insert({
            'cliente_id': clienteId,
            'plan_id': _planSeleccionado!['id'],
            'saldo_pendiente': saldoPendiente,
            'monto_parcial': cuota,
            'frecuencia_pago': _frecuenciaPago,
            'estado': saldoPendiente <= 0 ? 'Liquidado' : 'Activo',
            'fecha_inicio': DateTime.now().toIso8601String(),
            'proximo_pago': _fechaProximoPago.toIso8601String(),
          })
          .select()
          .single();

      if (enganche > 0 && userId != null) {
        await supabase.from('pagos').insert({
          'contrato_id': contratoData['id'],
          'monto': enganche,
          'fecha_pago': DateTime.now().toIso8601String(),
          'metodo_pago': 'Efectivo',
          'usuario_id': userId,
          'concepto': 'ENGANCHE INICIAL',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Contrato Guardado con Éxito!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _mostrarError("Error al guardar: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msj) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msj), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    const colorDorado = Color(0xFFD4AF37);

    double precio = _planSeleccionado != null
        ? (_planSeleccionado!['precio_total'] as num).toDouble()
        : 0.0;
    double enganche = double.tryParse(_engancheController.text) ?? 0.0;
    double saldo = precio - enganche;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "NUEVO CONTRATO",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: colorDorado,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _selectorTipoCliente(colorDorado),
            const SizedBox(height: 25),

            if (_esNuevoCliente) ...[
              _inputCampo(
                "Nombre del Difunto",
                _nombreDifuntoController,
                Icons.person,
              ),
              const SizedBox(height: 12),
              _inputCampo(
                "Nombre del Titular (Cliente)",
                _nombreContactoController,
                Icons.account_box,
              ),
              const SizedBox(height: 12),
              _inputCampo(
                "Teléfono Celular",
                _telefonoController,
                Icons.phone,
                numero: true,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _direccionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Dirección de Cobro",
                  labelStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.home, color: Colors.white60),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.map, color: colorDorado),
                    onPressed: _abrirSelectorMapa,
                    tooltip: "Seleccionar en mapa",
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colorDorado),
                  ),
                ),
              ),
              if (_latitud != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 5),
                      Text(
                        "Ubicación GPS capturada",
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ] else
              _buscadorClientes(colorDorado),

            const SizedBox(height: 30),
            _dividerDorado("DATOS DEL PLAN"),
            const SizedBox(height: 15),

            DropdownButtonFormField<Map<String, dynamic>>(
              dropdownColor: const Color(0xFF1E1E1E),
              value: _planSeleccionado,
              decoration: _dropdownStyle("Seleccionar Plan", colorDorado),
              style: const TextStyle(color: Colors.white),
              items: _listaPlanes
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text("${p['nombre']} (\$${p['precio_total']})"),
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
                    decoration: _dropdownStyle("Frecuencia", colorDorado),
                    style: const TextStyle(color: Colors.white),
                    items: _frecuencias
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _frecuenciaPago = val);
                        _calcularFechaPago();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _inputCampo(
                    "Cuota \$",
                    _montoParcialController,
                    Icons.payments,
                    numero: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _visualizadorFecha(),
            const SizedBox(height: 20),

            TextField(
              controller: _engancheController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                labelText: "Enganche recibido hoy",
                labelStyle: const TextStyle(color: Colors.greenAccent),
                prefixIcon: const Icon(Icons.stars, color: Colors.greenAccent),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent, width: 2),
                ),
              ),
              onChanged: (val) => setState(() {}),
            ),

            const SizedBox(height: 30),
            _resumenFinal(precio, enganche, saldo, colorDorado),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _cargando
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "FINALIZAR CONTRATO",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- COMPONENTES UI ---

  InputDecoration _dropdownStyle(String label, Color dorado) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: dorado)),
    );
  }

  Widget _dividerDorado(String texto) {
    return Row(
      children: [
        Text(
          texto,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Colors.white10)),
      ],
    );
  }

  Widget _selectorTipoCliente(Color dorado) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [_tab(true, "CLIENTE NUEVO"), _tab(false, "YA EXISTENTE")],
      ),
    );
  }

  Widget _tab(bool esNuevo, String label) {
    bool activo = _esNuevoCliente == esNuevo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _esNuevoCliente = esNuevo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFFD4AF37) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: activo ? Colors.black : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputCampo(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool numero = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: numero
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD4AF37)),
        ),
      ),
    );
  }

  Widget _buscadorClientes(Color dorado) {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (val) => val.text.isEmpty
          ? []
          : _listaClientesExistentes.where(
              (c) => c['nombre_contacto'].toString().toLowerCase().contains(
                val.text.toLowerCase(),
              ),
            ),
      displayStringForOption: (c) => c['nombre_contacto'],
      onSelected: (sel) => setState(() => _clienteExistenteSeleccionado = sel),
      fieldViewBuilder: (ctx, ctrl, focus, onEdit) => TextField(
        controller: ctrl,
        focusNode: focus,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: "Buscar cliente por nombre...",
          prefixIcon: Icon(Icons.search, color: dorado),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: dorado),
          ),
          helperText: _clienteExistenteSeleccionado != null
              ? "✓ Seleccionado: ${_clienteExistenteSeleccionado!['nombre_contacto']}"
              : null,
          helperStyle: const TextStyle(color: Colors.greenAccent),
        ),
      ),
    );
  }

  Widget _visualizadorFecha() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.blueAccent),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "FECHA DE PRIMER PAGO",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat(
                  'EEEE dd, MMMM',
                ).format(_fechaProximoPago).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumenFinal(double p, double e, double s, Color d) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _filaResumen(
            "Total del Plan",
            "\$${p.toStringAsFixed(2)}",
            Colors.white,
          ),
          const SizedBox(height: 8),
          _filaResumen(
            "Enganche hoy",
            "-\$${e.toStringAsFixed(2)}",
            Colors.greenAccent,
          ),
          const Divider(height: 25, color: Colors.white12),
          _filaResumen(
            "RESTANTE POR COBRAR",
            "\$${s.toStringAsFixed(2)}",
            d,
            esBold: true,
          ),
        ],
      ),
    );
  }

  Widget _filaResumen(String t, String v, Color c, {bool esBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t,
          style: TextStyle(
            color: Colors.white70,
            fontSize: esBold ? 14 : 13,
            fontWeight: esBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          v,
          style: TextStyle(
            color: c,
            fontSize: esBold ? 20 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
