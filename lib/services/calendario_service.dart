import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/evento.dart';
import 'supabase_config.dart';

class CalendarioService {
  static final _client = SupabaseConfig.client;
  static const String _localFile = 'pawid_calendario.json';

  // ─── SUPABASE ─────────────────────────────────────────────────────────────

  static Future<List<Evento>> loadEventosCloud(String userId) async {
    try {
      final data = await _client
          .from('calendario')
          .select()
          .eq('usuario_id', userId)
          .order('fecha', ascending: true);

      final eventos = (data as List).map((e) => Evento.fromJson(e)).toList();
      await _saveLocal(eventos);
      return eventos;
    } catch (_) {
      return _loadLocal();
    }
  }

  static Future<void> addEvento(Evento evento) async {
    try {
      await _client.from('calendario').insert(evento.toJson());
    } catch (_) {}
    final eventos = await _loadLocal();
    eventos.add(evento);
    await _saveLocal(eventos);
  }

  static Future<void> updateEvento(Evento evento) async {
    try {
      await _client.from('calendario').update(evento.toJson()).eq('id', evento.id);
    } catch (_) {}
    final eventos = await _loadLocal();
    final i = eventos.indexWhere((e) => e.id == evento.id);
    if (i != -1) { eventos[i] = evento; await _saveLocal(eventos); }
  }

  static Future<void> deleteEvento(String id) async {
    try {
      await _client.from('calendario').delete().eq('id', id);
    } catch (_) {}
    final eventos = await _loadLocal();
    eventos.removeWhere((e) => e.id == id);
    await _saveLocal(eventos);
  }

  static Future<void> toggleCompletado(Evento evento) async {
    evento.completado = !evento.completado;
    await updateEvento(evento);
  }

  // ─── LOCAL ────────────────────────────────────────────────────────────────

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_localFile');
  }

  static Future<List<Evento>> _loadLocal() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final List<dynamic> list = jsonDecode(content);
      return list.map((e) => Evento.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveLocal(List<Evento> eventos) async {
    final file = await _getFile();
    await file.writeAsString(
        jsonEncode(eventos.map((e) => e.toJson()).toList()));
  }
}