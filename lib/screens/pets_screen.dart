import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../services/pet_storage_service.dart';
import '../theme/app_theme.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> with WidgetsBindingObserver {
  List<Pet> _pets = [];
  bool _loading = true;
  String? _error;

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

  // Se llama cuando la app vuelve a primer plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPets();
    }
  }

  Future<void> _loadPets() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pets = await PetStorageService.loadPets();
      if (mounted) {
        setState(() {
          _pets = pets;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar mascotas: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _goToAddPet() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );
    // Recarga siempre al volver, haya o no cambios
    await _loadPets();
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mascota agregada correctamente'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _goToDetail(Pet pet) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
    );
    // Recarga al volver del detalle (puede haber editado o eliminado)
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
        title: const Text(
          'Mis Mascotas',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          // Botón refrescar manual
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
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Cargando mascotas...',
              style: TextStyle(color: AppColors.textMedium, fontSize: 14),
            ),
          ],
        ),
      )
          : _error != null
          ? _buildError()
          : _pets.isEmpty
          ? _buildEmpty()
          : _buildList(),
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
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPets,
              child: const Text('Reintentar'),
            ),
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
          const Text(
            'No tienes mascotas aún',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca el botón + para agregar tu primera mascota',
            style: TextStyle(fontSize: 13, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _goToAddPet,
            icon: const Icon(Icons.add),
            label: const Text('Agregar mascota'),
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
        itemCount: _pets.length,
        itemBuilder: (context, index) => _buildPetCard(_pets[index]),
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
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
                color: AppColors.primary.withOpacity(0.08),
              ),
              clipBehavior: Clip.antiAlias,
              child: pet.photoPath != null
                  ? Image.file(
                File(pet.photoPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.pets, size: 28, color: AppColors.primary),
              )
                  : const Icon(Icons.pets, size: 28, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${pet.species} · ${pet.breed}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pet.age,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
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