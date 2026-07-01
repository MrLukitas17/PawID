import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';
import 'supabase_config.dart';

class PetStorageService {
  static final _client = SupabaseConfig.client;
  static const String _localFileName = 'pawid_pets_local.json';

  // Nombre del bucket creado en Supabase Storage (debe ser público)
  static const String _storageBucket = 'mascotas-fotos';

  // ─── STORAGE (fotos) ──────────────────────────────────────────────────────

  /// Sube una foto local al bucket de Supabase Storage y devuelve su URL pública.
  /// Si [localPath] ya es una URL (http/https), la devuelve sin volver a subir.
  static Future<String?> uploadPetPhoto(String localPath, String petId) async {
    try {
      // Si ya es una URL pública (ej. al editar una mascota que ya tenía foto
      // subida y el usuario no cambió la imagen), no hay que volver a subirla.
      if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
        return localPath;
      }

      final file = File(localPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final ext = localPath.split('.').last.toLowerCase();
      // Incluye timestamp en el nombre: así cada vez que se cambia la foto
      // es un archivo nuevo en Storage, evitando que el CDN sirva la versión
      // anterior cacheada. El archivo viejo queda huérfano pero no rompe nada.
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '${petId}_$timestamp.$ext';

      await _client.storage.from(_storageBucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(upsert: false),
      );

      final publicUrl =
      _client.storage.from(_storageBucket).getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error al subir foto a Supabase Storage: $e');
      // Si falla la subida (sin internet, etc.), devolvemos null y el caller
      // decide si guarda la ruta local como fallback solo para el PDF nativo.
      return null;
    }
  }

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
        birthDate: m['fecha_nacimiento'] ?? '',
        ownerName: m['dueno_nombre'],
        ownerPhone: m['dueno_telefono'],
        ownerEmail: '',
        photoPath: m['foto_path']?.isNotEmpty == true ? m['foto_path'] : null,
      )).toList();
    } catch (e) {
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
      await savePetsLocal(pets);
      return pets;
    }
    return loadPetsLocal();
  }

  static Future<void> addPet(Pet pet, {String userId = ''}) async {
    if (userId.isNotEmpty) {
      await addPetToCloud(pet, userId);
    }
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