import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/pet.dart';
import 'supabase_config.dart';

class PetStorageService {
  static final _client = SupabaseConfig.client;
  static const String _localFileName = 'pawid_pets_local.json';

  // ─── SUPABASE ─────────────────────────────────────────────────────────────

  /// Carga mascotas del usuario desde Supabase
  static Future<List<Pet>> loadPetsFromCloud(String userId) async {
    try {
      final data = await _client
          .from('mascotas')
          .select()
          .eq('usuario_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((m) => Pet(
        id: m['id'],
        name: m['nombre'],
        species: m['especie'],
        breed: m['raza'],
        birthDate: m['fecha_nacimiento'],
        ownerName: m['dueno_nombre'],
        ownerPhone: m['dueno_telefono'],
        ownerEmail: m['dueno_email'] ?? '',
        photoPath: m['foto_path']?.isNotEmpty == true ? m['foto_path'] : null,
      )).toList();
    } catch (e) {
      // Si falla Supabase, carga local
      return loadPetsLocal();
    }
  }

  /// Agrega mascota en Supabase
  static Future<void> addPetToCloud(Pet pet, String userId) async {
    await _client.from('mascotas').insert({
      'id': pet.id,
      'usuario_id': userId,
      'nombre': pet.name,
      'especie': pet.species,
      'raza': pet.breed,
      'fecha_nacimiento': pet.birthDate,
      'dueno_nombre': pet.ownerName,
      'dueno_telefono': pet.ownerPhone,
      'dueno_email': pet.ownerEmail,
      'foto_path': pet.photoPath ?? '',
    });
  }

  /// Actualiza mascota en Supabase
  static Future<void> updatePetInCloud(Pet pet) async {
    await _client.from('mascotas').update({
      'nombre': pet.name,
      'especie': pet.species,
      'raza': pet.breed,
      'fecha_nacimiento': pet.birthDate,
      'dueno_nombre': pet.ownerName,
      'dueno_telefono': pet.ownerPhone,
      'dueno_email': pet.ownerEmail,
      'foto_path': pet.photoPath ?? '',
    }).eq('id', pet.id);
  }

  /// Elimina mascota en Supabase
  static Future<void> deletePetFromCloud(String id) async {
    await _client.from('mascotas').delete().eq('id', id);
  }

  // ─── LOCAL (fallback sin internet) ───────────────────────────────────────

  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_localFileName');
  }

  static Future<List<Pet>> loadPetsLocal() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => Pet.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePetsLocal(List<Pet> pets) async {
    final file = await _getLocalFile();
    await file.writeAsString(jsonEncode(pets.map((p) => p.toJson()).toList()));
  }

  // ─── MÉTODOS UNIFICADOS (usa Supabase + guarda local como backup) ─────────

  static Future<List<Pet>> loadPets({String userId = ''}) async {
    if (userId.isNotEmpty) {
      final pets = await loadPetsFromCloud(userId);
      await savePetsLocal(pets); // backup local
      return pets;
    }
    return loadPetsLocal();
  }

  static Future<void> addPet(Pet pet, {String userId = ''}) async {
    if (userId.isNotEmpty) {
      await addPetToCloud(pet, userId);
    }
    // También guarda local
    final pets = await loadPetsLocal();
    pets.add(pet);
    await savePetsLocal(pets);
  }

  static Future<void> updatePet(Pet pet, {String userId = ''}) async {
    if (userId.isNotEmpty) {
      await updatePetInCloud(pet);
    }
    final pets = await loadPetsLocal();
    final index = pets.indexWhere((p) => p.id == pet.id);
    if (index != -1) {
      pets[index] = pet;
      await savePetsLocal(pets);
    }
  }

  static Future<void> deletePet(String id, {String userId = ''}) async {
    if (userId.isNotEmpty) {
      await deletePetFromCloud(id);
    }
    final pets = await loadPetsLocal();
    pets.removeWhere((p) => p.id == id);
    await savePetsLocal(pets);
  }

  static Future<Pet?> getPetById(String id, {String userId = ''}) async {
    final pets = await loadPets(userId: userId);
    try {
      return pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}