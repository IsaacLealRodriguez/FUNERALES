import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PantallaHistorial extends StatefulWidget {
  const PantallaHistorial({super.key});

  @override
  State<PantallaHistorial> createState() => _PantallaHistorialState();
}

class _PantallaHistorialState extends State<PantallaHistorial> {
  DateTime _fechaSeleccionada = DateTime.now();
  List<Map<String, dynamic>> _pagosDelDia = [];
  double _totalCobrado = 0.0;
  bool _cargando = false;

  // COLORES
  final Color _colorFondo = Colors.black;
  final Color _colorDorado = const Color(0xFFD4AF37);
  final Color _colorCard = const Color(0xFF1E1E1E);

  @override
  void initState() {
    super.initState();
    _cargarPagosPorFecha(_fechaSeleccionada);
  }

  // Lógica para cambiar fecha
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _colorDorado,
              onPrimary: Colors.black,
              surface: _colorCard,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
      _cargarPagosPorFecha(picked);
    }
  }

  Future<void> _cargarPagosPorFecha(DateTime fecha) async {
    setState(() {
      _cargando = true;
      _totalCobrado = 0.0;
    });

    try {
      // Definir rango del día (00:00 a 23:59)
      final inicioDia = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
      ).toIso8601String();
      final finDia = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        23,
        59,
        59,
      ).toIso8601String();

      // CONSULTA CON TRIPLE JOIN: Pagos -> Contratos -> Clientes
      // Nota: Supabase usa la notación: tabla(columna) para joins anidados
      final response = await Supabase.instance.client
          .from('pagos')
          .select(
            'id, monto, fecha_pago, contratos!inner(id, clientes!inner(nombre_difunto))',
          )
          .gte('fecha_pago', inicioDia)
          .lte('fecha_pago', finDia)
          .order('fecha_pago', ascending: false);

      // Calcular total
      double suma = 0;
      final data = List<Map<String, dynamic>>.from(response);

      for (var p in data) {
        suma += (p['monto'] ?? 0);
      }

      if (mounted) {
        setState(() {
          _pagosDelDia = data;
          _totalCobrado = suma;
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar historial: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _formatearHora(String fechaIso) {
    try {
      final fecha = DateTime.parse(
        fechaIso,
      ).toLocal(); // Convertir a hora local
      return DateFormat('hh:mm a').format(fecha);
    } catch (_) {
      return "--:--";
    }
  }

  String _formatearFechaTitulo() {
    return DateFormat('dd/MM/yyyy').format(_fechaSeleccionada);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        title: const Text("CORTE DE CAJA"),
        backgroundColor: Colors.black,
        foregroundColor: _colorDorado,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _seleccionarFecha,
          ),
        ],
      ),
      body: Column(
        children: [
          // TARJETA DE RESUMEN
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _colorCard,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _colorDorado.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  "INGRESOS DEL ${_formatearFechaTitulo()}",
                  style: const TextStyle(
                    color: Colors.white54,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        "\$${_totalCobrado.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: _colorDorado,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 5),
                Text(
                  "${_pagosDelDia.length} Transacciones",
                  style: const TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10),

          // LISTA DE TRANSACCIONES
          Expanded(
            child: _cargando
                ? Center(child: CircularProgressIndicator(color: _colorDorado))
                : _pagosDelDia.isEmpty
                ? const Center(
                    child: Text(
                      "No hay movimientos en esta fecha.",
                      style: TextStyle(color: Colors.white30),
                    ),
                  )
                : ListView.builder(
                    itemCount: _pagosDelDia.length,
                    itemBuilder: (context, index) {
                      final pago = _pagosDelDia[index];
                      // Navegamos seguros a través del JSON anidado
                      final contrato =
                          pago['contratos'] as Map<String, dynamic>? ?? {};
                      final cliente =
                          contrato['clientes'] as Map<String, dynamic>? ?? {};
                      final nombreCliente =
                          cliente['nombre_difunto'] ?? "Cliente Desconocido";

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          nombreCliente,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "Hora: ${_formatearHora(pago['fecha_pago'])}",
                          style: const TextStyle(color: Colors.white38),
                        ),
                        trailing: Text(
                          "+\$${pago['monto']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
