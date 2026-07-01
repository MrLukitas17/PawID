import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/pet_storage_service.dart';
import '../theme/app_theme.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

class PetsScreen extends StatefulWidget {
  final String userId;
  final String ownerName;
  final String ownerPhone;
  // 1. METODOLOGÍA HISTORIAL: Agregamos la función callback opcional
  final VoidCallback? onBack;

  const PetsScreen({
    super.key,
    this.userId = '',
    this.ownerName = '',
    this.ownerPhone = '',
    this.onBack, // 2. La recibimos en el constructor
  });

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> with WidgetsBindingObserver {
  List<Pet> _pets = [];
  bool _loading = true;
  String? _error;

  String _searchQuery = '';
  String? _speciesFilter;

  final List<String> _allSpecies = [
    'Perro', 'Gato', 'Aves', 'Roedores', 'Reptiles', 'Peces', 'Otro'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPets();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadPets();
  }

  Future<void> _loadPets() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final pets = await PetStorageService.loadPets(userId: widget.userId);
      if (mounted) setState(() { _pets = pets; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error al cargar mascotas: $e'; _loading = false; });
    }
  }

  List<Pet> get _filteredPets {
    return _pets.where((p) {
      final matchesName = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSpecies = _speciesFilter == null || p.species == _speciesFilter;
      return matchesName && matchesSpecies;
    }).toList();
  }

  List<String> get _availableSpecies {
    final existing = _pets.map((p) => p.species).toSet();
    return _allSpecies.where((s) => existing.contains(s)).toList();
  }

  Future<void> _goToAddPet() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPetScreen(
          userId: widget.userId,
          defaultOwnerName: widget.ownerName,
          defaultOwnerPhone: widget.ownerPhone,
        ),
      ),
    );
    if (added == true) {
      await _loadPets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mascota agregada correctamente'),
            backgroundColor: Color(0xFF00A3A3),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _goToDetail(Pet pet) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet, userId: widget.userId)),
    );
    await _loadPets();
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
                const Text('Filtrar por Especie',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _modalChip('Todas', null, setModal),
                    ..._availableSpecies.map((s) => _modalChip(s, s, setModal)),
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
    final selected = _speciesFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.white,
      labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w600),
      onSelected: (_) {
        setState(() => _speciesFilter = value);
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
          // Imagen de fondo fija
          Positioned.fill(
            child: Image.asset(
              'assets/images/agregar_mascota.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.white),
            ),
          ),

          // Contenido de la interfaz
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mis Mascotas',
                          style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 24)),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        onPressed: _loadPets,
                      ),
                    ],
                  ),
                ),

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
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Buscar mascota...',
                              prefixIcon: const Icon(Icons.search, color: AppColors.textMedium),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.close, color: AppColors.textLight, size: 18),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            style: const TextStyle(color: AppColors.textDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _error != null
                      ? _buildError()
                      : _pets.isEmpty
                      ? Stack(
                    children: [
                      Positioned(
                        top: 280,
                        left: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'No hay mascotas registradas',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF1A2536),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Toca + para agregar el primer registro',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF9A9FA7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      : _filteredPets.isEmpty
                      ? _buildNoResults()
                      : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadPets,
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 80 + bottomPadding),
                      itemCount: _filteredPets.length,
                      itemBuilder: (context, index) => _buildPetCard(_filteredPets[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botones inferiores flotantes (Atrás y Agregar)
          Positioned(
            bottom: 16 + bottomPadding,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  // 3. METODOLOGÍA HISTORIAL: Ejecuta el onBack igual que el historial médico
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
                  onTap: _goToAddPet,
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.textMedium), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadPets, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 56, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Sin resultados',
              style: TextStyle(fontSize: 17, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Intenta con otro nombre o especie',
              style: TextStyle(fontSize: 13, color: AppColors.textLight)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() {
              _searchQuery = '';
              _speciesFilter = null;
            }),
            child: const Text('Limpiar filtros',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () => _goToDetail(pet),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
                color: AppColors.primary.withOpacity(0.08),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildPhotoPreview(pet),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 3),
                  Text('${pet.species} · ${pet.breed}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                  const SizedBox(height: 2),
                  Text(pet.age, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  // Muestra la foto de la mascota tanto si es una URL de Supabase Storage
  // como si fuera una ruta local antigua (compatibilidad con datos viejos).
  Widget _buildPhotoPreview(Pet pet) {
    final path = pet.photoPath;
    if (path == null || path.isEmpty) {
      return const Icon(Icons.pets, size: 28, color: AppColors.primary);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        // Agrega el timestamp de la URL como key para que Flutter no reutilice
        // la imagen cacheada cuando la URL cambia al editar la foto.
        key: ValueKey(path),
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.pets, size: 28, color: AppColors.primary),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
      const Icon(Icons.pets, size: 28, color: AppColors.primary),
    );
  }
}