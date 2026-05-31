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
    };

    final query = params.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$_baseUrl?$query';
  }
}