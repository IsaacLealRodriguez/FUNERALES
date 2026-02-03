import 'package:flutter/material.dart';

class PantallaReportes extends StatelessWidget {
  const PantallaReportes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "REPORTES Y ESTADÍSTICAS",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILTRO DE FECHA (Visual)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Resumen del Mes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Febrero 2024",
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TARJETAS DE RESUMEN
            Row(
              children: [
                _TarjetaResumen(
                  titulo: "Ingresos",
                  valor: "\$ 12,450",
                  icono: Icons.attach_money,
                  colorIcono: Colors.green,
                ),
                const SizedBox(width: 15),
                _TarjetaResumen(
                  titulo: "Contratos",
                  valor: "8 Nuevos",
                  icono: Icons.file_copy,
                  colorIcono: const Color(0xFFD4AF37),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // TÍTULO LISTA
            const Text(
              "Movimientos Recientes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // LISTA DE TRANSACCIONES (Ejemplos visuales)
            _ItemReporte(
              cliente: "Juan Pérez",
              concepto: "Pago Mensualidad - Plan Básico",
              monto: "+ \$500.00",
              fecha: "Hoy, 10:30 AM",
            ),
            _ItemReporte(
              cliente: "Maria Gonzalez",
              concepto: "Anticipo - Plan Premium",
              monto: "+ \$1,200.00",
              fecha: "Ayer, 4:15 PM",
            ),
            _ItemReporte(
              cliente: "Carlos Ruiz",
              concepto: "Pago Total - Servicio Inmediato",
              monto: "+ \$8,500.00",
              fecha: "2 Feb, 9:00 AM",
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGET INTERNO: TARJETA SUPERIOR
class _TarjetaResumen extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color colorIcono;

  const _TarjetaResumen({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: colorIcono, size: 30),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WIDGET INTERNO: FILA DE LA LISTA
class _ItemReporte extends StatelessWidget {
  final String cliente;
  final String concepto;
  final String monto;
  final String fecha;

  const _ItemReporte({
    required this.cliente,
    required this.concepto,
    required this.monto,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cliente,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                concepto,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text(
                fecha,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          Text(
            monto,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green, // Verde para dinero entrando
            ),
          ),
        ],
      ),
    );
  }
}
