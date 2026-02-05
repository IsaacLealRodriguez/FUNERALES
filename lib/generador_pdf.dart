import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class GeneradorPDF {
  static Future<void> generarRecibo({
    required String nombreCliente,
    required String nombrePlan,
    required double montoAbono,
    required double saldoRestante,
    required String folioPago,
  }) async {
    final pdf = pw.Document();
    final fechaHoy = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Intentamos cargar el logo. Si falla, usamos un icono o nada.
    pw.MemoryImage? imageLogo;
    try {
      final imageBytes = await rootBundle.load('assets/negro.png');
      imageLogo = pw.MemoryImage(imageBytes.buffer.asUint8List());
    } catch (e) {
      // Si no encuentra la imagen, no pasa nada, sigue sin logo
      print("No se pudo cargar el logo para el PDF: $e");
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Formato ticket
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // --- LOGO (Si existe) ---
              if (imageLogo != null)
                pw.Container(height: 60, width: 60, child: pw.Image(imageLogo)),

              // --- ENCABEZADO ---
              pw.Text(
                "FUNERALES ARIS",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "Servicios Funerarios Profesionales",
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(),

              // --- DATOS DEL TICKET ---
              pw.SizedBox(height: 5),
              pw.Text(
                "RECIBO DE PAGO",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text("Folio: #$folioPago", style: pw.TextStyle(fontSize: 10)),
              pw.Text("Fecha: $fechaHoy", style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),

              // --- DATOS CLIENTE ---
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Cliente:",
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      nombreCliente,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Plan:",
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(nombrePlan, style: pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              pw.SizedBox(height: 10),

              // --- TOTALES ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "ABONO:",
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "\$${montoAbono.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Saldo Restante:", style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    "\$${saldoRestante.toStringAsFixed(2)}",
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              // --- PIE ---
              pw.SizedBox(height: 20),
              pw.Text(
                "Gracias por su preferencia.",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );

    // Muestra la vista previa
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
