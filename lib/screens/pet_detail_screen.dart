import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/pet.dart';
import '../services/pet_storage_service.dart';
import '../services/pdf_generator_service.dart';
import '../theme/app_theme.dart';
import '../services/qr_data_service.dart';
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

  String get _qrData => QrDataService.generateQrContent(_pet);

  Future<void> _openPdf() async {
    setState(() => _isGenerating = true);
    try {
      await PdfGeneratorService.generateAndOpen(_pet);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _isGenerating = true);
    try {
      await PdfGeneratorService.sharePdf(_pet);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _deletePet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Eliminar mascota',
            style: TextStyle(color: AppColors.textDark)),
        content: Text(
          '¿Eliminar a ${_pet.name}? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textMedium),
        ),
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
        title: Text(_pet.name,
            style: const TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AddPetScreen(pet: _pet)),
              );
              if (changed == true) {
                final updated = await PetStorageService.getPetById(_pet.id);
                if (updated != null && mounted) setState(() => _pet = updated);
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
            _buildHeader(),
            const SizedBox(height: 24),
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
            _buildQRSection(),
            const SizedBox(height: 20),

            // Botón abrir PDF
            _isGenerating
                ? const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 8),
                  Text('Generando PDF...',
                      style: TextStyle(color: AppColors.textMedium)),
                ],
              ),
            )
                : Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _openPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Abrir PDF'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _sharePdf,
                  icon: const Icon(Icons.share_outlined,
                      color: AppColors.primary),
                  label: const Text('Compartir PDF',
                      style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
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
              ? Image.file(File(_pet.photoPath!), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.pets, size: 44, color: AppColors.primary))
              : const Icon(Icons.pets, size: 44, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(_pet.name,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        Text('${_pet.species} · ${_pet.breed}',
            style: const TextStyle(fontSize: 14, color: AppColors.textMedium)),
      ],
    );
  }

  Widget _buildInfoCard(
      {required String title,
        required IconData icon,
        required List<Widget> rows}) {
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ]),
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
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMedium))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark))),
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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          const Text('Código QR',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: 6),
          const Text(
            'Escanea con la cámara del celular. Se abre el navegador y puedes descargar el PDF',
            style: TextStyle(fontSize: 12, color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: _qrData,
            version: QrVersions.auto,
            size: 180,
            eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square, color: AppColors.primary),
            dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text('ID: ${_pet.id}',
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }
}