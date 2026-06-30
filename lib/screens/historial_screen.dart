import 'dart:io';
import 'package:flutter/material.dart';
import '../models/registro_medico.dart';
import '../services/historial_service.dart';
import '../theme/app_theme.dart';
import 'add_historial_screen.dart';

class HistorialScreen extends StatefulWidget {
  final String usuarioId;
  final VoidCallback? onBack;

  const HistorialScreen({super.key, this.usuarioId = '', this.onBack});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<RegistroMedico> _registros = [];
  bool _loading = false;
  String _searchFilter = '';
  String? _petFilter;

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  Future<void> _loadHistorial() async {
    setState(() => _loading = true);
    final registros = await ServicioHistorial.cargarHistorialNube(widget.usuarioId);
    if (mounted) setState(() { _registros = registros; _loading = false; });
  }

  List<RegistroMedico> get _filteredRecords {
    return _registros.where((r) {
      final matchesName = r.nombre.toLowerCase().contains(_searchFilter.toLowerCase());
      final matchesPet = _petFilter == null || r.mascotaNombre == _petFilter;
      return matchesName && matchesPet;
    }).toList();
  }

  List<String> get _petNames {
    final names = _registros.map((r) => r.mascotaNombre).toSet().toList();
    names.sort();
    return names;
  }

  Future<void> _goToAdd() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddHistorialScreen(userId: widget.usuarioId)),
    );
    if (added == true) await _loadHistorial();
  }

  Future<void> _editRecord(RegistroMedico registro) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddHistorialScreen(userId: widget.usuarioId, registro: registro),
      ),
    );
    if (updated == true) await _loadHistorial();
  }

  Future<void> _deleteRecord(RegistroMedico registro) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar registro',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        content: Text('¿Eliminar "${registro.nombre}"?',
            style: const TextStyle(color: AppColors.textMedium)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMedium)),
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
      await ServicioHistorial.eliminarRegistro(registro.id);
      await _loadHistorial();
    }
  }

  void _viewPhoto(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 64))),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtrar por Mascota',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _modalChip('Todas', null, setModal),
                    ..._petNames.map((n) => _modalChip(n, n, setModal)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalChip(String label, String? value, StateSetter setModal) {
    final selected = _petFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.white,
      labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w600),
      onSelected: (_) {
        setState(() => _petFilter = value);
        setModal(() {});
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Imagen de fondo (Pata de menu_historial.png)
          Positioned.fill(
            child: Image.asset(
              'assets/images/menu_historial.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.white),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y refresh
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Historial Médico',
                          style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 24)),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        onPressed: _loadHistorial,
                      ),
                    ],
                  ),
                ),

                // Buscador y filtro
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tune, color: AppColors.primary, size: 28),
                        onPressed: _showFilterSheet,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: TextField(
                            onChanged: (v) => setState(() => _searchFilter = v),
                            decoration: const InputDecoration(
                              hintText: 'Buscar registro...',
                              prefixIcon: Icon(Icons.search, color: AppColors.textMedium),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            style: const TextStyle(color: AppColors.textDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sección de datos dinámica
                Expanded(
                  child: _filteredRecords.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Espacio empujado hacia abajo de la pata
                        const SizedBox(height: 140),
                        const Text(
                          'No hay registros médicos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF1A2536),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Toca + para agregar el primer registro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF9A9FA7),
                              fontSize: 10,
                              fontWeight: FontWeight.w400),
                        ),
                        // Balance de los botones inferiores
                        SizedBox(height: 60 + bottomPadding),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 80 + bottomPadding),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (_, i) => _recordCard(_filteredRecords[i]),
                  ),
                ),
              ],
            ),
          ),

          // Botones flotantes (atrás y agregar)
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
                  onTap: _goToAdd,
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

  Widget _recordCard(RegistroMedico registro) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (registro.fotoUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _viewPhoto(registro.fotoUrl),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(registro.fotoUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            color: AppColors.background,
                            child: const Icon(Icons.image_not_supported,
                                size: 48, color: AppColors.textLight))),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Ver foto',
                                style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(registro.nombre,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ),
                    GestureDetector(
                      onTap: () => _editRecord(registro),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined,
                            color: AppColors.textLight, size: 20),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _deleteRecord(registro),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.pets, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(registro.mascotaNombre,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                    if (registro.fecha.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today,
                          size: 13, color: AppColors.textMedium),
                      const SizedBox(width: 4),
                      Text(registro.fecha,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ],
                ),
                if (registro.notas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(registro.notas,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMedium, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}