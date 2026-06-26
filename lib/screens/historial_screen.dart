import 'dart:io';
import 'package:flutter/material.dart';
import '../models/registro_medico.dart';
import '../services/historial_service.dart';
import '../theme/app_theme.dart';
import 'add_historial_screen.dart';

class HistorialScreen extends StatefulWidget {
  final String usuarioId;

  const HistorialScreen({super.key, this.usuarioId = ''});

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
    if (mounted) {
      setState(() {
        _registros = registros;
        _loading = false;
      });
    }
  }

  List<RegistroMedico> get _filteredRecords {
    return _registros.where((r) {
      final matchesName =
      r.nombre.toLowerCase().contains(_searchFilter.toLowerCase());
      final matchesPet = _petFilter == null || r.mascotaNombre == _petFilter;
      return matchesName && matchesPet;
    }).toList();
  }

  List<String> get _petNames {
    final names = _registros.map((r) => r.mascotaNombre).toSet().toList();
    names.sort();
    return names;
  }

  // Navegar a editar registro
  Future<void> _editRecord(RegistroMedico registro) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddHistorialScreen(
          userId: widget.usuarioId,
          registro: registro,
        ),
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
              child: Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Historial Médico',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadHistorial,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddHistorialScreen(userId: widget.usuarioId),
            ),
          );
          if (added == true) await _loadHistorial();
        },
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchFilter = v),
              decoration: InputDecoration(
                hintText: 'Buscar registro...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMedium),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(color: AppColors.textDark),
            ),
          ),

          // Filtro por mascota (aparece siempre que haya mascotas)
          if (_petNames.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _filterChip('Todas', null),
                  ..._petNames.map((n) => _filterChip(n, n)).toList(),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Lista
          Expanded(
            child: _filteredRecords.isEmpty
                ? _buildEmpty()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: _filteredRecords.length,
              itemBuilder: (_, i) => _recordCard(_filteredRecords[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _petFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _petFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined,
              size: 64, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No hay registros médicos',
              style: TextStyle(
                  fontSize: 17,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Toca + para agregar el primer registro',
              style: TextStyle(fontSize: 13, color: AppColors.textLight)),
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto si existe
          if (registro.fotoUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _viewPhoto(registro.fotoUrl),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(registro.fotoUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.background,
                        child: const Icon(Icons.image_not_supported,
                            size: 48, color: AppColors.textLight),
                      ),
                    ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                    // Botón editar
                    GestureDetector(
                      onTap: () => _editRecord(registro),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_outlined,
                            color: AppColors.textLight, size: 20),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Botón eliminar
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
                          fontSize: 12,
                          color: AppColors.textMedium,
                          height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}