import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/pet.dart';

class PetStorageService {
  static const String _fileName = 'pawid_pets.json';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<Pet>> loadPets() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => Pet.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> savePets(List<Pet> pets) async {
    final file = await _getFile();
    final jsonList = pets.map((p) => p.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList), flush: true);
  }

  static Future<void> addPet(Pet pet) async {
    final pets = await loadPets();
    pets.add(pet);
    await savePets(pets);
  }

  static Future<void> updatePet(Pet updatedPet) async {
    final pets = await loadPets();
    final index = pets.indexWhere((p) => p.id == updatedPet.id);
    if (index != -1) {
      pets[index] = updatedPet;
      await savePets(pets);
    }
  }

  static Future<void> deletePet(String id) async {
    final pets = await loadPets();
    pets.removeWhere((p) => p.id == id);
    await savePets(pets);
  }

  static Future<Pet?> getPetById(String id) async {
    final pets = await loadPets();
    try {
      return pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}