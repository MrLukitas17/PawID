import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet.dart';
import '../services/pet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paw_text_field.dart';

class AddPetScreen extends StatefulWidget {
  final Pet? pet;
  final String userId;
  // Datos del dueño desde el perfil (pre-relleno bloqueado)
  final String defaultOwnerName;
  final String defaultOwnerPhone;

  const AddPetScreen({
    super.key,
    this.pet,
    this.userId = '',
    this.defaultOwnerName = '',
    this.defaultOwnerPhone = '',
  });

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  String _selectedSpecies = 'Perro';
  String? _photoPath;
  bool _isSaving = false;

  final List<String> _species = [
    'Perro', 'Gato', 'Ave', 'Conejo', 'Reptil', 'Otro'
  ];

  bool get _isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Modo edición: carga datos de la mascota existente
      final p = widget.pet!;
      _nameController.text = p.name;
      _breedController.text = p.breed;
      _birthDateController.text = p.birthDate;
      _ownerNameController.text = p.ownerName;
      _ownerPhoneController.text = p.ownerPhone;
      _selectedSpecies = p.species;
      _photoPath = p.photoPath;
    } else {
      // Modo nuevo: pre-rellena con datos del perfil
      _ownerNameController.text = widget.defaultOwnerName;
      _ownerPhoneController.text = widget.defaultOwnerPhone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _birthDateController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 600,
      );
      if (picked != null && mounted) {
        setState(() => _photoPath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo seleccionar imagen: $e'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    try {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now.subtract(const Duration(days: 365)),
        firstDate: DateTime(2000),
        lastDate: now,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.background,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null && mounted) {
        setState(() {
          _birthDateController.text =
          '${picked.day.toString().padLeft(2, '0')}/'
              '${picked.month.toString().padLeft(2, '0')}/'
              '${picked.year}';
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final pet = Pet(
        id: _isEditing
            ? widget.pet!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        breed: _breedController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        ownerEmail: '',
        photoPath: _photoPath,
      );

      if (_isEditing) {
        await PetStorageService.updatePet(pet, userId: widget.userId);
      } else {
        await PetStorageService.addPet(pet, userId: widget.userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Mascota guardada exitosamente'),
            ]),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEditing ? 'Editar Mascota' : 'Nueva Mascota',
          style: const TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildPhotoSelector()),
              const SizedBox(height: 8),
              const Center(
                child: Text('Foto opcional — toca para agregar',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              ),
              const SizedBox(height: 24),

              // ── Datos de la Mascota ─────────────────────────────────
              _sectionTitle('Datos de la Mascota'),
              const SizedBox(height: 12),

              // Nombre: solo letras, máximo 50 caracteres
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                  LengthLimitingTextInputFormatter(50),
                ],
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Solo letras, máx. 50 caracteres',
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inputUnderline, width: 1.5)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary, width: 2)),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildSpeciesDropdown(),
              const SizedBox(height: 16),

              // Raza: solo letras, máximo 50 caracteres
              TextFormField(
                controller: _breedController,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                  LengthLimitingTextInputFormatter(50),
                ],
                decoration: const InputDecoration(
                  labelText: 'Raza *',
                  hintText: 'Solo letras, máx. 50 caracteres',
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inputUnderline, width: 1.5)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary, width: 2)),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha de nacimiento: opcional
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: PawTextField(
                    label: 'Fecha de Nacimiento (opcional)',
                    hint: 'Toca para seleccionar',
                    controller: _birthDateController,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Datos del Dueño ─────────────────────────────────────
              _sectionTitle('Datos del Dueño'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 13, color: AppColors.primary.withOpacity(0.6)),
                  const SizedBox(width: 5),
                  const Text('Editables desde Configuración',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
              const SizedBox(height: 12),

              // Nombre del dueño: solo lectura
              _readOnlyField(
                label: 'Nombre del dueño',
                value: _ownerNameController.text,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // Teléfono: solo lectura con prefijo +56
              _readOnlyPhoneField(value: _ownerPhoneController.text),

              const SizedBox(height: 36),

              _isSaving
                  ? const Center(child: Column(children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 8),
                Text('Guardando...', style: TextStyle(color: AppColors.textMedium)),
              ]))
                  : ElevatedButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Guardar Cambios' : 'Agregar Mascota'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Campo solo lectura con fondo sutil
  Widget _readOnlyField({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputUnderline.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: TextStyle(
                      fontSize: 14,
                      color: value.isNotEmpty
                          ? AppColors.textDark
                          : AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Campo teléfono solo lectura con prefijo +56
  Widget _readOnlyPhoneField({required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inputUnderline.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Text('+56',
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: AppColors.inputUnderline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Teléfono',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: TextStyle(
                      fontSize: 14,
                      color: value.isNotEmpty
                          ? AppColors.textDark
                          : AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: _photoPath != null
                ? Image.file(File(_photoPath!), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.pets, size: 44, color: AppColors.primary))
                : const Icon(Icons.pets, size: 44, color: AppColors.primary),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, size: 16, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSpecies,
      decoration: const InputDecoration(
        labelText: 'Especie *',
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.inputUnderline, width: 1.5)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
      dropdownColor: AppColors.background,
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      items: _species.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) => setState(() => _selectedSpecies = v!),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary));
  }
}