import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/registro_medico.dart';

class ServicioHistorial {
  static final _cliente = Supabase.instance.client;
  static const String _archivoLocal = 'pawid_historial.json';
  static const String _claveWeb = 'pawid_historial';

  // ─── SUPABASE ─────────────────────────────────────────────────────────────

  static Future<List<RegistroMedico>> cargarHistorialNube(String usuarioId) async {
    try {
      final datos = await _cliente
          .from('historial_medico')
          .select()
          .eq('usuario_id', usuarioId)
          .order('created_at', ascending: false);

      final registros = (datos as List)
          .map((r) => RegistroMedico.fromJson(r))
          .toList();
      await _guardarLocal(registros);
      return registros;
    } catch (_) {
      return _cargarLocal();
    }
  }

  static Future<void> agregarRegistro(RegistroMedico registro) async {
    try {
      await _cliente.from('historial_medico').insert(registro.toJson());
    } catch (_) {}
    final lista = await _cargarLocal();
    lista.insert(0, registro);
    await _guardarLocal(lista);
  }

  // Método para actualizar un registro existente
  static Future<void> actualizarRegistro(RegistroMedico registro) async {
    try {
      await _cliente
          .from('historial_medico')
          .update(registro.toJson())
          .eq('id', registro.id);
    } catch (_) {}
    final lista = await _cargarLocal();
    final i = lista.indexWhere((r) => r.id == registro.id);
    if (i != -1) {
      lista[i] = registro;
      await _guardarLocal(lista);
    }
  }

  static Future<void> eliminarRegistro(String id) async {
    try {
      await _cliente.from('historial_medico').delete().eq('id', id);
    } catch (_) {}
    final lista = await _cargarLocal();
    lista.removeWhere((r) => r.id == id);
    await _guardarLocal(lista);
  }

  // ─── LOCAL ────────────────────────────────────────────────────────────────
  // En móvil/escritorio: archivo JSON en la carpeta de documentos.
  // En web: SharedPreferences (almacenamiento del navegador), porque el
  // navegador no tiene una carpeta de documentos accesible.

  static Future<File> _getArchivo() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_archivoLocal');
  }

  static Future<List<RegistroMedico>> _cargarLocal() async {
    try {
      final String contenido;

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        contenido = prefs.getString(_claveWeb) ?? '';
      } else {
        final archivo = await _getArchivo();
        if (!await archivo.exists()) return [];
        contenido = await archivo.readAsString();
      }

      if (contenido.isEmpty) return [];
      final List<dynamic> lista = jsonDecode(contenido);
      return lista.map((r) => RegistroMedico.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// El respaldo local es "de mejor esfuerzo": si falla, no debe romper
  /// una operación que en Supabase ya se hizo bien.
  static Future<void> _guardarLocal(List<RegistroMedico> registros) async {
    try {
      final contenido =
      jsonEncode(registros.map((r) => r.toJson()).toList());

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_claveWeb, contenido);
      } else {
        final archivo = await _getArchivo();
        await archivo.writeAsString(contenido);
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ No se pudo guardar el historial local: $e');
    }
  }
}