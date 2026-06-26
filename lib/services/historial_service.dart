import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/registro_medico.dart';

class ServicioHistorial {
  static final _cliente = Supabase.instance.client;
  static const String _archivoLocal = 'pawid_historial.json';

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

  static Future<File> _getArchivo() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_archivoLocal');
  }

  static Future<List<RegistroMedico>> _cargarLocal() async {
    try {
      final archivo = await _getArchivo();
      if (!await archivo.exists()) return [];
      final contenido = await archivo.readAsString();
      if (contenido.isEmpty) return [];
      final List<dynamic> lista = jsonDecode(contenido);
      return lista.map((r) => RegistroMedico.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _guardarLocal(List<RegistroMedico> registros) async {
    final archivo = await _getArchivo();
    await archivo.writeAsString(
        jsonEncode(registros.map((r) => r.toJson()).toList()));
  }
}