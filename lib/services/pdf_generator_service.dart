import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import '../models/pet.dart';

class PdfGeneratorService {
  // ── Paleta de colores ────────────────────────────────────────────────────
  static const PdfColor _primary      = PdfColor.fromInt(0xFF007777);
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFF00A3A3);
  static const PdfColor _mint         = PdfColor.fromInt(0xFFE0F7FA);
  static const PdfColor _beige        = PdfColor.fromInt(0xFFF5F5F0);
  static const PdfColor _textDark     = PdfColor.fromInt(0xFF1A1A3A);
  static const PdfColor _textLight    = PdfColor.fromInt(0xFF666666);
  static const PdfColor _white        = PdfColor.fromInt(0xFFFEFEFE);
  static const PdfColor _border       = PdfColor.fromInt(0xFF00A3A3);

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

  // Carga los bytes de la imagen sin importar si es URL remota o ruta local.
  // Devuelve null si no hay foto o si falla la carga (el PDF se genera igual,
  // con el círculo de inicial como respaldo).
  static Future<Uint8List?> _loadPhotoBytes(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return null;
    try {
      if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
        // Foto en Supabase Storage: descarga los bytes vía HTTP
        final response = await http.get(Uri.parse(photoPath))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) return response.bodyBytes;
        return null;
      } else {
        // Ruta local (compatibilidad con datos viejos antes del fix de Storage)
        final file = File(photoPath);
        if (await file.exists()) return await file.readAsBytes();
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> _buildPdf(Pet pet) async {
    final pdf = pw.Document();

    // Carga la imagen correctamente tanto desde URL como desde ruta local
    pw.MemoryImage? petImage;
    final photoBytes = await _loadPhotoBytes(pet.photoPath);
    if (photoBytes != null) {
      petImage = pw.MemoryImage(photoBytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
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
                        width: 64, height: 64,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: _white, width: 2.5),
                        ),
                        child: pw.ClipOval(
                          child: pw.Image(petImage, fit: pw.BoxFit.cover),
                        ),
                      )
                          : pw.Container(
                        width: 64, height: 64,
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
                style: pw.TextStyle(fontSize: 10, color: _textLight)),
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