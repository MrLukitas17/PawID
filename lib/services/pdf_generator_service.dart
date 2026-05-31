import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import '../models/pet.dart';

class PdfGeneratorService {
  static const PdfColor _primary = PdfColor.fromInt(0xFF6B3A2A);
  static const PdfColor _accent = PdfColor.fromInt(0xFFF5E6D3);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF3D2010);
  static const PdfColor _textMedium = PdfColor.fromInt(0xFF7A5C4A);
  static const PdfColor _white = PdfColor.fromInt(0xFFFFFFFF);

  /// Genera el PDF y lo abre directamente
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

  /// Genera el PDF y lo comparte/imprime usando el diálogo del sistema
  static Future<void> sharePdf(Pet pet) async {
    final pdfBytes = await _buildPdf(pet);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'PawID_${pet.name}.pdf',
    );
  }

  static Future<Uint8List> _buildPdf(Pet pet) async {
    final pdf = pw.Document();

    // Cargar foto si existe
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
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── ENCABEZADO ──────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: _primary,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PawID',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: _white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Ficha de Mascota',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                    // Foto o placeholder
                    petImage != null
                        ? pw.Container(
                      width: 70,
                      height: 70,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: _white, width: 2),
                      ),
                      child: pw.ClipOval(
                        child: pw.Image(petImage, fit: pw.BoxFit.cover),
                      ),
                    )
                        : pw.Container(
                      width: 70,
                      height: 70,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: _accent,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          pet.name.isNotEmpty
                              ? pet.name[0].toUpperCase()
                              : '?',
                          style: pw.TextStyle(
                            fontSize: 30,
                            fontWeight: pw.FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ── DATOS DE LA MASCOTA ──────────────────────────────
              _buildSection(
                title: 'Datos de la Mascota',
                rows: [
                  _buildRow('Nombre', pet.name),
                  _buildRow('Especie', pet.species),
                  _buildRow('Raza', pet.breed),
                  _buildRow('Fecha de nacimiento', pet.birthDate),
                  _buildRow('Edad', pet.age),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── DATOS DEL DUEÑO ──────────────────────────────────
              _buildSection(
                title: 'Datos del Dueno',
                rows: [
                  _buildRow('Nombre', pet.ownerName),
                  _buildRow('Telefono', pet.ownerPhone),
                  if (pet.ownerEmail.isNotEmpty)
                    _buildRow('Email', pet.ownerEmail),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── PIE DE PÁGINA ─────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _accent,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ID: ${pet.id}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: _textMedium,
                      ),
                    ),
                    pw.Text(
                      'Generado por PawID',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: _textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        border: pw.Border.all(color: _accent, width: 1.5),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Título de sección
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: pw.BoxDecoration(
              color: _accent,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
            ),
          ),
          // Filas de datos
          pw.Padding(
            padding: const pw.EdgeInsets.all(16),
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
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                color: _textMedium,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}