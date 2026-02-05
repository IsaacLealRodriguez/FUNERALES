import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Necesario para formatear dinero y fechas

class PantallaReportes extends StatefulWidget {
  const PantallaReportes({super.key});

  @override
  State<PantallaReportes> createState() => _PantallaReportesState();
}

class _PantallaReportesState extends State<PantallaReportes> {
  // COLORES DEL TEMA
  final Color _colorFondo = Colors.black;
  final Color _colorCard = const Color(0xFF1E1E1E);
  final Color _colorDorado = const Color(0xFFD4AF37);

  // VARIABLES DE DATOS
  bool _cargando = true;
  double _totalIngresos = 0.0;
  int _totalContratos = 0;
  List<Map<String, dynamic>> _movimientos = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // LÓGICA: CONECTAR CON SUPABASE
  Future<void> _cargarDatos() async {
    try {
      // 1. Obtener todas las ventas ordenadas por fecha (más reciente primero)
      final response = await Supabase.instance.client
          .from('ventas') // <--- NOMBRE DE TU TABLA EN SUPABASE
          .select()
          .order('created_at', ascending: false);

      // 2. Calcular totales localmente
      double sumaDinero = 0;
      for (var venta in response) {
        // Nos aseguramos que el precio sea un número, si es null ponemos 0
        final precio = (venta['precio'] ?? 0).toDouble();
        sumaDinero += precio;
      }

      // 3. Actualizar la pantalla
      if (mounted) {
        setState(() {
          _movimientos = List<Map<String, dynamic>>.from(response);
          _totalIngresos = sumaDinero;
          _totalContratos = response.length;
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando reportes: $e');
      if (mounted) {
        setState(() {
          _cargando = false; // Dejar de cargar aunque haya error
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    }
  }

  // HELPER: Obtener fecha actual formateada
  String _obtenerMesActual() {
    return DateFormat('MMMM yyyy', 'es_ES').format(DateTime.now());
    // Nota: Si no tienes configurado 'es_ES', saldrá en inglés.
    // Puedes usar DateFormat.yMMMM() simplemente.
  }

  @override
  Widget build(BuildContext context) {
    // Formateador de dinero (Ej: $ 1,200.00)
    final formatMoney = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        backgroundColor: _colorFondo,
        elevation: 0,
        iconTheme: IconThemeData(color: _colorDorado),
        title: Text(
          "REPORTES Y ESTADÍSTICAS",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _colorDorado,
            letterSpacing: 1.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white12, height: 1.0),
        ),
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator(color: _colorDorado))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CABECERA CON FECHA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Resumen Global",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: _colorDorado),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          // Muestra fecha actual o fija si prefieres
                          DateFormat('MMM yyyy').format(DateTime.now()),
                          style: TextStyle(
                            color: _colorDorado,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // TARJETAS DE RESUMEN (INGRESOS Y CONTRATOS)
                  Row(
                    children: [
                      _TarjetaResumen(
                        titulo: "Ingresos Totales",
                        valor: formatMoney.format(_totalIngresos),
                        icono: Icons.attach_money,
                        colorIcono: _colorDorado,
                        colorFondo: _colorCard,
                      ),
                      const SizedBox(width: 15),
                      _TarjetaResumen(
                        titulo: "Ventas Totales",
                        valor: "$_totalContratos",
                        icono: Icons.file_copy,
                        colorIcono: Colors.white,
                        colorFondo: _colorCard,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // TÍTULO LISTA
                  const Text(
                    "Últimos Movimientos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // LISTA DE TRANSACCIONES GENERADA DINÁMICAMENTE
                  if (_movimientos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _colorCard,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.inbox, color: Colors.white24, size: 40),
                          SizedBox(height: 10),
                          Text(
                            "No hay datos registrados",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._movimientos.map((venta) {
                      // Preparamos los datos individuales
                      final nombre =
                          venta['nombre_cliente'] ?? 'Cliente Desconocido';
                      final plan = venta['nombre_plan'] ?? 'Venta General';
                      final precio = (venta['precio'] ?? 0).toDouble();
                      final fechaRaw =
                          venta['created_at'] ??
                          DateTime.now().toIso8601String();
                      final fecha = DateFormat(
                        'dd MMM, HH:mm',
                      ).format(DateTime.parse(fechaRaw));

                      return _ItemReporte(
                        cliente: nombre,
                        concepto: plan,
                        monto: "+ ${formatMoney.format(precio)}",
                        fecha: fecha,
                        colorCard: _colorCard,
                        colorDorado: _colorDorado,
                      );
                    }).toList(),

                  const SizedBox(height: 30), // Espacio final
                ],
              ),
            ),
    );
  }
}

// -----------------------------------------------------------
// WIDGETS PERSONALIZADOS (ESTILO BLACK & GOLD)
// -----------------------------------------------------------

class _TarjetaResumen extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color colorIcono;
  final Color colorFondo;

  const _TarjetaResumen({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.colorIcono,
    required this.colorFondo,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: colorIcono, size: 28),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 5),
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16, // Ajustado para que quepan números grandes
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemReporte extends StatelessWidget {
  final String cliente;
  final String concepto;
  final String monto;
  final String fecha;
  final Color colorCard;
  final Color colorDorado;

  const _ItemReporte({
    required this.cliente,
    required this.concepto,
    required this.monto,
    required this.fecha,
    required this.colorCard,
    required this.colorDorado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LADO IZQUIERDO: TEXTOS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  concepto,
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fecha,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LADO DERECHO: MONTO
          Text(
            monto,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: colorDorado, // Dinero en dorado
            ),
          ),
        ],
      ),
    );
  }
}
