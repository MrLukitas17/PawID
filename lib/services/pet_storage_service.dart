import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';
import 'supabase_config.dart';

class PetStorageService {
  static final _client = SupabaseConfig.client;
  static const String _localFileName = 'pawid_pets_local.json';
  static const String _webPrefsKey = 'pawid_pets_local';

  // Nombre del bucket creado en Supabase Storage (debe ser público)
  static const String _storageBucket = 'mascotas-fotos';

  // ─── STORAGE (fotos) ──────────────────────────────────────────────────────

  /// Extrae la extensión de un nombre o ruta. Si no hay una válida
  /// (por ejemplo en rutas blob: de web), devuelve 'jpg'.
  static String _extensionOf(String path) {
    final clean = path.split('?').first;
    if (!clean.contains('.')) return 'jpg';
    final ext = clean.split('.').last.toLowerCase();
    if (ext.isEmpty || ext.length > 4 || ext.contains('/')) return 'jpg';
    return ext;
  }

  /// Sube una foto al bucket de Supabase Storage y devuelve su URL pública.
  /// - Si [localPath] ya es una URL (http/https), la devuelve sin volver a subir.
  /// - En móvil/escritorio lee el archivo desde [localPath].
  /// - En web hay que pasar [bytes] (con `await xfile.readAsBytes()`),
  ///   porque la ruta del selector de imágenes es un blob: y no un archivo.
  static Future<String?> uploadPetPhoto(
      String localPath,
      String petId, {
        Uint8List? bytes,
        String? fileName,
      }) async {
    try {
      // Si ya es una URL pública (ej. al editar una mascota que ya tenía foto
      // subida y el usuario no cambió la imagen), no hay que volver a subirla.
      if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
        return localPath;
      }

      final Uint8List data;
      final String ext;

      if (bytes != null) {
        data = bytes;
        ext = _extensionOf(fileName ?? localPath);
      } else {
        // Sin bytes, en web no se puede leer un archivo local.
        if (kIsWeb) return null;

        final file = File(localPath);
        if (!await file.exists()) return null;
        data = await file.readAsBytes();
        ext = _extensionOf(localPath);
      }

      // Incluye timestamp en el nombre: así cada vez que se cambia la foto
      // es un archivo nuevo en Storage, evitando que el CDN sirva la versión
      // anterior cacheada. El archivo viejo queda huérfano pero no rompe nada.
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '${petId}_$timestamp.$ext';
      final contentType = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';

      await _client.storage.from(_storageBucket).uploadBinary(
        storagePath,
        data,
        fileOptions: FileOptions(upsert: false, contentType: contentType),
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

      return (data as List)
          .map((m) => Pet(
        id: m['id'],
        name: m['nombre'],
        species: m['especie'],
        breed: m['raza'],
        birthDate: m['fecha_nacimiento'] ?? '',
        ownerName: m['dueno_nombre'],
        ownerPhone: m['dueno_telefono'],
        ownerEmail: '',
        photoPath:
        m['foto_path']?.isNotEmpty == true ? m['foto_path'] : null,
      ))
          .toList();
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
  // En móvil/escritorio: archivo JSON en la carpeta de documentos.
  // En web: SharedPreferences (almacenamiento del navegador), porque el
  // navegador no tiene carpeta de documentos accesible.

  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_localFileName');
  }

  static Future<List<Pet>> loadPetsLocal() async {
    try {
      final String content;

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        content = prefs.getString(_webPrefsKey) ?? '';
      } else {
        final file = await _getLocalFile();
        if (!await file.exists()) return [];
        content = await file.readAsString();
      }

      if (content.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => Pet.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  /// El respaldo local es "de mejor esfuerzo": si falla, no debe romper
  /// una operación que en Supabase ya se hizo bien.
  static Future<void> savePetsLocal(List<Pet> pets) async {
    try {
      final content = jsonEncode(pets.map((p) => p.toJson()).toList());

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_webPrefsKey, content);
      } else {
        final file = await _getLocalFile();
        await file.writeAsString(content);
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ No se pudo guardar el respaldo local: $e');
    }
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