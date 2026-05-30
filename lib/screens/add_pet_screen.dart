import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet.dart';
import '../services/pet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paw_text_field.dart';

class AddPetScreen extends StatefulWidget {
  final Pet? pet;

  const AddPetScreen({super.key, this.pet});

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
  final _ownerEmailController = TextEditingController();

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
      final p = widget.pet!;
      _nameController.text = p.name;
      _breedController.text = p.breed;
      _birthDateController.text = p.birthDate;
      _ownerNameController.text = p.ownerName;
      _ownerPhoneController.text = p.ownerPhone;
      _ownerEmailController.text = p.ownerEmail;
      _selectedSpecies = p.species;
      _photoPath = p.photoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _birthDateController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
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
          SnackBar(
            content: Text('No se pudo seleccionar imagen: $e'),
            backgroundColor: Colors.orange,
          ),
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
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.white,
                surface: AppColors.background,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && mounted) {
        setState(() {
          _birthDateController.text =
          '${picked.day.toString().padLeft(2, '0')}/'
              '${picked.month.toString().padLeft(2, '0')}/'
              '${picked.year}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir el calendario'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Quita el foco del teclado
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
        ownerEmail: _ownerEmailController.text.trim(),
        photoPath: _photoPath,
      );

      if (_isEditing) {
        await PetStorageService.updatePet(pet);
      } else {
        await PetStorageService.addPet(pet);
      }

      if (mounted) {
        // Pequeña pausa para que el usuario vea que guardó
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Mascota guardada exitosamente'),
              ],
            ),
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
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.redAccent,
          ),
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
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
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
                child: Text(
                  'Foto opcional — toca para agregar',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ),
              const SizedBox(height: 24),

              _sectionTitle('Datos de la Mascota'),
              const SizedBox(height: 12),

              PawTextField(
                label: 'Nombre *',
                controller: _nameController,
                validator: (v) =>
                v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              _buildSpeciesDropdown(),
              const SizedBox(height: 16),

              PawTextField(
                label: 'Raza *',
                controller: _breedController,
                validator: (v) =>
                v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: PawTextField(
                    label: 'Fecha de Nacimiento *',
                    hint: 'Toca para seleccionar',
                    controller: _birthDateController,
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Campo requerido' : null,
                  ),
                ),
              ),

              const SizedBox(height: 28),
              _sectionTitle('Datos del Dueño'),
              const SizedBox(height: 12),

              PawTextField(
                label: 'Nombre del dueño *',
                controller: _ownerNameController,
                validator: (v) =>
                v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              PawTextField(
                label: 'Teléfono *',
                controller: _ownerPhoneController,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              PawTextField(
                label: 'Email (opcional)',
                controller: _ownerEmailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 36),

              _isSaving
                  ? const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 8),
                    Text('Guardando...', style: TextStyle(color: AppColors.textMedium)),
                  ],
                ),
              )
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

  Widget _buildPhotoSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: _photoPath != null
                ? Image.file(File(_photoPath!), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.pets, size: 44, color: AppColors.primary))
                : const Icon(Icons.pets, size: 44, color: AppColors.primary),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
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
          borderSide: BorderSide(color: AppColors.inputUnderline, width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
      dropdownColor: AppColors.background,
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      items: _species
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) => setState(() => _selectedSpecies = v!),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}