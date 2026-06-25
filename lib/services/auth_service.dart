import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'supabase_config.dart';

class AuthService {
  static final _client = SupabaseConfig.client;

  // Hash de contraseña simple
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Registra un nuevo usuario
  static Future<String?> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final existing = await _client
          .from('usuarios')
          .select('id')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();

      if (existing != null) {
        return 'Este email ya está registrado. Inicia sesión.';
      }

      await _client.from('usuarios').insert({
        'nombre': nombre.trim(),
        'email': email.toLowerCase().trim(),
        'password': _hashPassword(password),
        'telefono': '',
        'foto_path': '',
      });

      return null;
    } catch (e) {
      return 'Error al registrar: $e';
    }
  }

  /// Inicia sesión — ahora retorna también telefono y foto_path
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _client
          .from('usuarios')
          .select('id, nombre, email, telefono, foto_path')
          .eq('email', email.toLowerCase().trim())
          .eq('password', _hashPassword(password))
          .maybeSingle();

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Verifica si un email ya existe
  static Future<bool> emailExists(String email) async {
    try {
      final result = await _client
          .from('usuarios')
          .select('id')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }

  /// Actualiza el perfil del usuario (nombre, teléfono, foto)
  static Future<void> updateProfile({
    required String userId,
    required String nombre,
    required String telefono,
    required String fotoPath,
  }) async {
    await _client.from('usuarios').update({
      'nombre': nombre,
      'telefono': telefono,
      'foto_path': fotoPath,
    }).eq('id', userId);
  }
}