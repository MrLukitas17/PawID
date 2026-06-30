import 'dart:convert';
import '../models/pet.dart';

class QrDataService {
  static const String _baseUrl =
      'https://mrlukitas17.github.io/PawID_Escanear/';

  /// Genera la URL corta con los datos como parámetros
  /// El QR apunta a GitHub Pages donde se genera el PDF
  static String generateQrContent(Pet pet) {
    final params = {
      'n':  pet.name,
      'e':  pet.species,
      'r':  pet.breed,
      'f':  pet.birthDate,
      'ed': pet.age,
      'd':  pet.ownerName,
      't':  pet.ownerPhone,
      'em': pet.ownerEmail,
      'id': pet.id,
      // URL pública de la foto en Supabase Storage (si existe).
      // Si photoPath es null o sigue siendo una ruta local antigua que
      // nunca se subió, simplemente no se manda este parámetro y el HTML
      // muestra el círculo con la inicial, como ya estaba previsto.
      if (pet.photoPath != null &&
          pet.photoPath!.startsWith('http'))
        'img': pet.photoPath!,
    };

    final query = params.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$_baseUrl?$query';
  }
}