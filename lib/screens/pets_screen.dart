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

  const PetsScreen({
    super.key,
    this.userId = '',
    this.ownerName = '',
    this.ownerPhone = '',
  });

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> with WidgetsBindingObserver {
  List<Pet> _pets = [];
  bool _loading = true;
  String? _error;

  // Filtros
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

  // Mascotas filtradas por nombre y especie
  List<Pet> get _filteredPets {
    return _pets.where((p) {
      final matchesName = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSpecies = _speciesFilter == null || p.species == _speciesFilter;
      return matchesName && matchesSpecies;
    }).toList();
  }

  // Solo muestra chips de especies que existen en la lista
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
            backgroundColor: AppColors.primary,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Mis Mascotas',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadPets,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _goToAddPet,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: _loading
          ? const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Cargando mascotas...', style: TextStyle(color: AppColors.textMedium)),
        ],
      ))
          : _error != null
          ? _buildError()
          : Column(
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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

          // Chips de especie (solo si hay más de una especie)
          if (_availableSpecies.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _speciesChip('Todos', null),
                  ..._availableSpecies.map((s) => _speciesChip(s, s)),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Lista o estado vacío
          Expanded(
            child: _pets.isEmpty
                ? _buildEmpty()
                : _filteredPets.isEmpty
                ? _buildNoResults()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  // Chip de filtro por especie
  Widget _speciesChip(String label, String? value) {
    final selected = _speciesFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _speciesFilter = value),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 72, color: AppColors.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No tienes mascotas aún',
              style: TextStyle(fontSize: 18, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Toca el botón + para agregar tu primera mascota',
              style: TextStyle(fontSize: 13, color: AppColors.textLight), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // Cuando hay mascotas pero no coinciden con el filtro
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

  Widget _buildList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPets,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _filteredPets.length,
        itemBuilder: (context, index) => _buildPetCard(_filteredPets[index]),
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
              child: pet.photoPath != null
                  ? Image.file(File(pet.photoPath!), fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 28, color: AppColors.primary))
                  : const Icon(Icons.pets, size: 28, color: AppColors.primary),
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
}