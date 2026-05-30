import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/pet.dart';

class WordGeneratorService {
  /// Genera un archivo .txt enriquecido con los datos de la mascota
  /// (compatible universalmente sin plantilla .docx externa)
  /// y lo abre automáticamente.
  static Future<String> generateAndOpen(Pet pet) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'PawID_${pet.name.replaceAll(' ', '_')}.txt';
      final filePath = '${dir.path}/$fileName';

      final content = _buildContent(pet);
      final file = File(filePath);
      await file.writeAsString(content, flush: true);

      await OpenFilex.open(filePath);
      return filePath;
    } catch (e) {
      throw Exception('Error al generar el documento: $e');
    }
  }

  static String _buildContent(Pet pet) {
    final now = DateTime.now();
    final fecha = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    return '''
╔══════════════════════════════════════╗
         FICHA DE MASCOTA - PawID
╚══════════════════════════════════════╝

📋 DATOS DE LA MASCOTA
───────────────────────────────────────
  Nombre       : ${pet.name}
  Especie      : ${pet.species}
  Raza         : ${pet.breed}
  Fecha Nac.   : ${pet.birthDate}
  Edad         : ${pet.age}

👤 DATOS DEL DUEÑO
───────────────────────────────────────
  Nombre       : ${pet.ownerName}
  Teléfono     : ${pet.ownerPhone}
  Email        : ${pet.ownerEmail}

───────────────────────────────────────
  ID Mascota   : ${pet.id}
  Generado     : $fecha
  Aplicación   : PawID
───────────────────────────────────────

Este documento fue generado por PawID.
Guardado localmente en el dispositivo.
''';
  }
}