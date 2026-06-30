import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import '../models/pet.dart';

class PdfGeneratorService {
  // ── Nueva paleta de colores ──────────────────────────────────────────────
  static const PdfColor _primary     = PdfColor.fromInt(0xFF007777); // Turquesa oscuro
  static const PdfColor _primaryLight= PdfColor.fromInt(0xFF00A3A3); // Turquesa claro
  static const PdfColor _mint        = PdfColor.fromInt(0xFFE0F7FA); // Verde menta
  static const PdfColor _beige       = PdfColor.fromInt(0xFFF5F5F0); // Beige tierra
  static const PdfColor _textDark    = PdfColor.fromInt(0xFF1A1A3A); // Azul marino
  static const PdfColor _textMedium  = PdfColor.fromInt(0xFF333333); // Gris oscuro
  static const PdfColor _textLight   = PdfColor.fromInt(0xFF666666); // Gris medio
  static const PdfColor _coral       = PdfColor.fromInt(0xFFFF8C69); // Naranja coral
  static const PdfColor _white       = PdfColor.fromInt(0xFFFEFEFE); // Blanco crudo
  static const PdfColor _border      = PdfColor.fromInt(0xFF00A3A3); // Borde turquesa

  static Future<String> generateAndOpen(Pet pet) async {
    final pdfBytes = await _buildPdf(pet);
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'PawID_${pet.name.replaceAll(' ', '_')}.pdf';
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes, flush: true);
    await OpenFilex.open(filePath);
    return filePath;
  }

  static Future<void> sharePdf(Pet pet) async {
    final pdfBytes = await _buildPdf(pet);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'PawID_${pet.name}.pdf',
    );
  }

  static Future<Uint8List> _buildPdf(Pet pet) async {
    final pdf = pw.Document();

    pw.MemoryImage? petImage;
    if (pet.photoPath != null) {
      try {
        final imgFile = File(pet.photoPath!);
        if (await imgFile.exists()) {
          petImage = pw.MemoryImage(await imgFile.readAsBytes());
        }
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              // Borde rectangular turquesa alrededor de todo el contenido
              border: pw.Border.all(color: _border, width: 2.5),
              borderRadius: pw.BorderRadius.circular(14),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // ── ENCABEZADO ─────────────────────────────────────
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: pw.BoxDecoration(
                    color: _primary,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PawID',
                              style: pw.TextStyle(
                                  fontSize: 26,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _white)),
                          pw.SizedBox(height: 4),
                          pw.Text('Ficha de Mascota',
                              style: pw.TextStyle(
                                  fontSize: 12, color: _mint)),
                        ],
                      ),
                      // Foto o inicial
                      petImage != null
                          ? pw.Container(
                        width: 64,
                        height: 64,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(
                              color: _white, width: 2.5),
                        ),
                        child: pw.ClipOval(
                          child: pw.Image(petImage,
                              fit: pw.BoxFit.cover),
                        ),
                      )
                          : pw.Container(
                        width: 64,
                        height: 64,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: _mint,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            pet.name.isNotEmpty
                                ? pet.name[0].toUpperCase()
                                : '?',
                            style: pw.TextStyle(
                                fontSize: 28,
                                fontWeight: pw.FontWeight.bold,
                                color: _primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // ── DATOS DE LA MASCOTA ─────────────────────────────
                _buildSection(
                  title: 'Datos de la Mascota',
                  rows: [
                    _buildRow('Nombre', pet.name),
                    _buildRow('Especie', pet.species),
                    _buildRow('Raza', pet.breed),
                    _buildRow('Fecha de nacimiento',
                        pet.birthDate.isNotEmpty ? pet.birthDate : '—'),
                    _buildRow('Edad', pet.age),
                  ],
                ),

                pw.SizedBox(height: 14),

                // ── DATOS DEL DUEÑO ─────────────────────────────────
                _buildSection(
                  title: 'Datos del Dueño',
                  rows: [
                    _buildRow('Nombre', pet.ownerName),
                    _buildRow('Teléfono', pet.ownerPhone),
                    if (pet.ownerEmail.isNotEmpty)
                      _buildRow('Email', pet.ownerEmail),
                  ],
                ),

                pw.SizedBox(height: 14),

                // ── PIE DE PÁGINA ────────────────────────────────────
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: _mint,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _primaryLight, width: 1),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ID: ${pet.id}',
                          style: pw.TextStyle(
                              fontSize: 8, color: _textLight)),
                      pw.Text('Generado por PawID',
                          style: pw.TextStyle(
                              fontSize: 8,
                              color: _primary,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSection({
    required String title,
    required List<pw.Widget> rows,
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _primaryLight, width: 1.2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Título con fondo turquesa claro
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 14, vertical: 9),
            decoration: pw.BoxDecoration(
              color: _primaryLight,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _white),
            ),
          ),
          // Filas con fondo blanco crudo
          pw.Container(
            color: _beige,
            padding: const pw.EdgeInsets.all(14),
            child: pw.Column(children: rows),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 10, color: _textLight)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _textDark)),
          ),
        ],
      ),
    );
  }
}