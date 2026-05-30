import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/pet.dart';
import '../services/pet_storage_service.dart';
import '../services/word_generator_service.dart';
import '../theme/app_theme.dart';
import 'add_pet_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late Pet _pet;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  // El QR contiene el ID de la mascota para que la app lo busque localmente
  String get _qrData => 'pawid://pet/${_pet.id}';

  Future<void> _generateDocument() async {
    setState(() => _isGenerating = true);
    try {
      await WordGeneratorService.generateAndOpen(_pet);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documento generado y abierto'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _deletePet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Eliminar mascota',
            style: TextStyle(color: AppColors.textDark)),
        content: Text('¿Eliminar a ${_pet.name}? Esta acción no se puede deshacer.',
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
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PetStorageService.deletePet(_pet.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _pet.name,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => AddPetScreen(pet: _pet)),
              );
              if (changed == true) {
                final updated = await PetStorageService.getPetById(_pet.id);
                if (updated != null) setState(() => _pet = updated);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deletePet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Foto y nombre
            _buildHeader(),
            const SizedBox(height: 24),

            // Datos de la mascota
            _buildInfoCard(
              title: 'Datos de la Mascota',
              icon: Icons.pets,
              rows: [
                _infoRow('Especie', _pet.species),
                _infoRow('Raza', _pet.breed),
                _infoRow('Fecha de nacimiento', _pet.birthDate),
                _infoRow('Edad', _pet.age),
              ],
            ),
            const SizedBox(height: 16),

            // Datos del dueño
            _buildInfoCard(
              title: 'Datos del Dueño',
              icon: Icons.person_outline,
              rows: [
                _infoRow('Nombre', _pet.ownerName),
                _infoRow('Teléfono', _pet.ownerPhone),
                if (_pet.ownerEmail.isNotEmpty)
                  _infoRow('Email', _pet.ownerEmail),
              ],
            ),
            const SizedBox(height: 24),

            // QR Code
            _buildQRSection(),
            const SizedBox(height: 24),

            // Botón descargar documento
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateDocument,
              icon: _isGenerating
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              label: Text(_isGenerating
                  ? 'Generando...'
                  : 'Descargar Ficha (.txt)'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.5),
            color: AppColors.primary.withOpacity(0.1),
          ),
          clipBehavior: Clip.antiAlias,
          child: _pet.photoPath != null
              ? Image.file(File(_pet.photoPath!), fit: BoxFit.cover)
              : const Icon(Icons.pets, size: 44, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          _pet.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        Text(
          '${_pet.species} · ${_pet.breed}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Código QR',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Escanea para descargar la ficha de esta mascota',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: _qrData,
            version: QrVersions.auto,
            size: 180,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.primary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${_pet.id}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}