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
  /// Retorna null si fue exitoso, o un mensaje de error
  static Future<String?> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      // Verificar si el email ya existe
      final existing = await _client
          .from('usuarios')
          .select('id')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();

      if (existing != null) {
        return 'Este email ya está registrado. Inicia sesión.';
      }

      // Crear usuario
      await _client.from('usuarios').insert({
        'nombre': nombre.trim(),
        'email': email.toLowerCase().trim(),
        'password': _hashPassword(password),
      });

      return null; // éxito
    } catch (e) {
      return 'Error al registrar: $e';
    }
  }

  /// Inicia sesión
  /// Retorna el usuario si fue exitoso, o null si falló
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _client
          .from('usuarios')
          .select('id, nombre, email')
          .eq('email', email.toLowerCase().trim())
          .eq('password', _hashPassword(password))
          .maybeSingle();

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Verifica si un email ya existe (para validación en tiempo real)
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
}