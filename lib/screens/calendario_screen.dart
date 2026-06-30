import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/evento.dart';
import '../services/calendario_service.dart';
import '../theme/app_theme.dart';
import 'add_evento_screen.dart';

class CalendarioScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onBack;

  const CalendarioScreen({super.key, this.userId = '', this.onBack});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  List<Evento> _eventos = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEventos();
  }

  Future<void> _loadEventos() async {
    setState(() => _loading = true);
    final eventos = await CalendarioService.loadEventosCloud(widget.userId);
    if (mounted) setState(() { _eventos = eventos; _loading = false; });
  }

  List<Evento> _getEventosDelDia(DateTime day) {
    final fechaStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _eventos.where((e) => e.fecha == fechaStr).toList();
  }

  List<Evento> get _todosLosEventos {
    return [..._eventos]
      ..sort((a, b) => a.fechaDateTime.compareTo(b.fechaDateTime));
  }

  Future<void> _deleteEvento(Evento evento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar evento',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        content: Text('¿Eliminar "${evento.titulo}"?',
            style: const TextStyle(color: AppColors.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMedium)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await CalendarioService.deleteEvento(evento.id);
      await _loadEventos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Calendario',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadEventos,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Imagen de fondo fija
          Positioned.fill(
            child: Image.asset(
              'assets/images/calendario.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFE0F7FA)),
            ),
          ),

          // Contenido Principal
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SafeArea(
            child: Column(
              children: [
                // Calendario compacto
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: TableCalendar<Evento>(
                    locale: 'es_ES',
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventosDelDia,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    rowHeight: 38,
                    daysOfWeekHeight: 22,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: const TextStyle(color: AppColors.accent),
                      cellMargin: const EdgeInsets.all(2),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      headerPadding: EdgeInsets.symmetric(vertical: 4),
                      titleTextStyle: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                      leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
                      rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
                    ),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        if (isSameDay(_selectedDay, selected)) {
                          _selectedDay = null;
                        } else {
                          _selectedDay = selected;
                        }
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) {
                      _focusedDay = focused;
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Espacio de la lista limitado físicamente antes de llegar a los botones
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 80 + bottomPadding),
                    child: _buildEventList(),
                  ),
                ),
              ],
            ),
          ),

          // Botones inferiores flotantes
          Positioned(
            bottom: 16 + bottomPadding,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () { if (widget.onBack != null) widget.onBack!(); },
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 24),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final added = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEventoScreen(
                          userId: widget.userId,
                          fechaInicial: _selectedDay,
                        ),
                      ),
                    );
                    if (added == true) await _loadEventos();
                  },
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final eventosDelDia = _selectedDay != null
        ? _getEventosDelDia(_selectedDay!)
        : <Evento>[];

    const paddingLista = EdgeInsets.symmetric(horizontal: 12);

    if (eventosDelDia.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Día seleccionado (${eventosDelDia.length})',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _selectedDay = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('Ver todos',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: paddingLista,
              itemCount: eventosDelDia.length,
              itemBuilder: (_, i) => _buildEventCard(eventosDelDia[i]),
            ),
          ),
        ],
      );
    }

    final todos = _todosLosEventos;

    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today,
                size: 56, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No hay eventos agendados',
                style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Toca + para agregar un evento',
                style: TextStyle(fontSize: 13, color: AppColors.textLight)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Todos los eventos (${todos.length})',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: paddingLista,
            itemCount: todos.length,
            itemBuilder: (_, i) => _buildEventCard(todos[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Evento evento) {
    final color = _tipoColor(evento.tipo);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(evento.tipoIcon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          evento.titulo,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${evento.mascotaNombre} · ${evento.tipoLabel}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
            Text(
              evento.hora.isNotEmpty
                  ? '${_formatFecha(evento.fecha)} a las ${evento.hora}'
                  : _formatFecha(evento.fecha),
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
            if (evento.descripcion.isNotEmpty)
              Text(evento.descripcion,
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEventoScreen(
                      userId: widget.userId,
                      evento: evento,
                    ),
                  ),
                );
                if (changed == true) await _loadEventos();
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined, color: AppColors.textLight, size: 20),
              ),
            ),
            GestureDetector(
              onTap: () => _deleteEvento(evento),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(String fechaYMD) {
    try {
      final parts = fechaYMD.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return fechaYMD;
    }
  }

  Color _tipoColor(String tipo) {
    switch (tipo) {
      case 'vacuna': return Colors.green;
      case 'medicamento': return Colors.blue;
      default: return AppColors.primary;
    }
  }
}