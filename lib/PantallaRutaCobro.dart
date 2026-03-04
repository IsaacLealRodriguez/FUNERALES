import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pantalla_detalle_contrato.dart';

class PantallaRutaCobro extends StatefulWidget {
  const PantallaRutaCobro({super.key});

  @override
  State<PantallaRutaCobro> createState() => _PantallaRutaCobroState();
}

class _PantallaRutaCobroState extends State<PantallaRutaCobro> {
  bool _cargando = true;
  String? _errorMensaje;
  List<Map<String, dynamic>> _listaCobros = [];
  double _totalPorCobrarHoy = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarRutaDeCobro();
  }

  /// Carga los contratos que vencen hoy o están atrasados
  Future<void> _cargarRutaDeCobro() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final hoy = DateTime.now();
      final finDeDia = DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
        23,
        59,
        59,
      ).toIso8601String();

      // Timeout de 15 segundos para evitar esperas infinitas en la calle
      final response = await Supabase.instance.client
          .from('contratos')
          .select('*, clientes(*), planes(nombre)')
          .eq('estado', 'Activo')
          .lte('proximo_pago', finDeDia)
          .order('proximo_pago', ascending: true)
          .timeout(const Duration(seconds: 15));

      double total = 0;
      final data = List<Map<String, dynamic>>.from(response);

      for (var item in data) {
        total += (item['monto_parcial'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _listaCobros = data;
          _totalPorCobrarHoy = total;
          _cargando = false;
        });
      }
    } on TimeoutException {
      _manejarError("La conexión tardó demasiado. Revisa tu señal.");
    } on PostgrestException catch (e) {
      _manejarError("Error de base de datos: ${e.message}");
    } catch (e) {
      _manejarError("Sin conexión a internet. Verifica tus datos móviles.");
    }
  }

  void _manejarError(String msj) {
    if (mounted) {
      setState(() {
        _errorMensaje = msj;
        _cargando = false;
      });
    }
  }

  /// Abre la aplicación de mapas externa
  Future<void> _abrirMapa(String direccion) async {
    if (direccion.isEmpty || direccion == "Sin dirección") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El cliente no tiene una dirección válida."),
        ),
      );
      return;
    }

    final query = Uri.encodeComponent(direccion);
    final googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );
    final appleMapsUrl = Uri.parse("https://maps.apple.com/?q=$query");

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir el mapa automáticamente.';
      }
    } catch (e) {
      debugPrint("Error abriendo mapa: $e");
    }
  }

  int _calcularDiasAtraso(String fechaPago) {
    final fecha = DateTime.parse(fechaPago);
    final hoy = DateTime.now();
    final fechaSoloDia = DateTime(fecha.year, fecha.month, fecha.day);
    final hoySoloDia = DateTime(hoy.year, hoy.month, hoy.day);
    return hoySoloDia.difference(fechaSoloDia).inDays;
  }

  @override
  Widget build(BuildContext context) {
    const colorDorado = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "RUTA DE COBRO",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.black,
        foregroundColor: colorDorado,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarRutaDeCobro,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_errorMensaje == null && !_cargando) _buildResumenRuta(),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: colorDorado),
                  )
                : _errorMensaje != null
                ? _buildPantallaError(colorDorado)
                : _listaCobros.isEmpty
                ? _buildVistaVacia()
                : _buildListaCobros(colorDorado),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRuta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDatoResumen(
            "Pendientes",
            "${_listaCobros.length}",
            Colors.white,
          ),
          _buildDatoResumen(
            "Total Hoy",
            "\$${_totalPorCobrarHoy.toStringAsFixed(2)}",
            Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDatoResumen(String titulo, String valor, Color colorValor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        Text(
          valor,
          style: TextStyle(
            color: colorValor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPantallaError(Color dorado) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 100, color: Colors.white10),
            const SizedBox(height: 20),
            Text(
              _errorMensaje!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _cargarRutaDeCobro,
              icon: const Icon(Icons.refresh),
              label: const Text("REINTENTAR"),
              style: ElevatedButton.styleFrom(
                backgroundColor: dorado,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaVacia() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, size: 80, color: Colors.green),
          SizedBox(height: 20),
          Text(
            "¡Ruta Completada!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "No hay más cobros pendientes por hoy.",
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCobros(Color colorDorado) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _listaCobros.length,
      itemBuilder: (context, index) {
        final contrato = _listaCobros[index];
        final cliente = contrato['clientes'];
        final plan = contrato['planes'];
        final diasAtraso = _calcularDiasAtraso(contrato['proximo_pago']);
        final cuota = (contrato['monto_parcial'] as num).toDouble();

        Color colorEstado = diasAtraso > 0
            ? Colors.redAccent
            : (diasAtraso == 0 ? Colors.orangeAccent : Colors.green);
        String textoEstado = diasAtraso > 0
            ? "ATRASADO ($diasAtraso DÍAS)"
            : "TOCA HOY";

        return Card(
          color: const Color(0xFF121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: colorEstado.withOpacity(0.3), width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorEstado.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        textoEstado,
                        style: TextStyle(
                          color: colorEstado,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "\$${cuota.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  cliente['nombre_contacto'] ?? "Sin Nombre",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Plan: ${plan['nombre']}",
                  style: TextStyle(
                    color: colorDorado.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white10),
                ),

                // SECCIÓN DE DIRECCIÓN Y MAPA
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cliente['direccion'] ?? "Sin dirección registrada",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.near_me, color: Colors.blueAccent),
                      onPressed: () => _abrirMapa(cliente['direccion'] ?? ""),
                      tooltip: "Navegar con GPS",
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // BOTÓN DE ACCIÓN
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantallaDetalleContrato(
                            contrato: contrato,
                            cliente: cliente,
                          ),
                        ),
                      );
                      _cargarRutaDeCobro(); // Refrescar al volver
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("GESTIONAR COBRO"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
