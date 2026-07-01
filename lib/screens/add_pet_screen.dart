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
    'Perro', 'Gato', 'Aves', 'Roedores', 'Reptiles', 'Peces', 'Otro'
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
      _selectedSpecies = p.species;
      _photoPath = p.photoPath;
    } else {
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

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador superior
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Tomar foto
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF007777)),
                title: const Text('Tomar foto',
                    style: TextStyle(color: Color(0xFF1A1A3A))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              // Elegir de galería
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF007777)),
                title: const Text('Elegir de galería',
                    style: TextStyle(color: Color(0xFF1A1A3A))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              // Eliminar foto (solo si ya hay foto)
              if (_photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  title: const Text('Eliminar foto',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photoPath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
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
      final petId = _isEditing
          ? widget.pet!.id
          : DateTime.now().millisecondsSinceEpoch.toString();

      // ── Subida de foto a Supabase Storage ────────────────────────────
      // Si el usuario eligió una foto nueva (ruta local en el dispositivo),
      // la subimos al bucket y nos quedamos con la URL pública resultante.
      // Si _photoPath ya era una URL (no se tocó la foto al editar) o no hay
      // foto, uploadPetPhoto la deja pasar o devuelve null sin romper nada.
      String? finalPhotoUrl = _photoPath;
      if (_photoPath != null) {
        final uploadedUrl =
        await PetStorageService.uploadPetPhoto(_photoPath!, petId);
        if (uploadedUrl != null) {
          finalPhotoUrl = uploadedUrl;
        }
        // Si la subida falla (ej. sin internet), finalPhotoUrl se queda con
        // la ruta local: el PDF nativo de Flutter seguirá funcionando en este
        // dispositivo, aunque la ficha web de GitHub no podrá mostrar la foto
        // hasta que haya conexión y se vuelva a guardar.
      }

      final pet = Pet(
        id: petId,
        name: _nameController.text.trim(),
        species: _selectedSpecies,
        breed: _breedController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        ownerEmail: '',
        photoPath: finalPhotoUrl,
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
            backgroundColor: Color(0xFF00A3A3),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Editar Mascota' : 'Nueva Mascota',
          style: const TextStyle(
              color: Color(0xFF007777),
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF007777)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/agregar_mascota.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFE0F7FA),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomPadding),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(child: _buildPhotoSelector()),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text('Toca para agregar foto',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textLight)),
                          ),
                          const SizedBox(height: 20),

                          _sectionTitle('Datos de la Mascota'),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                                color: AppColors.textDark, fontSize: 14),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                              LengthLimitingTextInputFormatter(50),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Nombre *',
                              hintText: 'Solo letras, máx. 50 caracteres',
                              labelStyle: TextStyle(color: Color(0xFF007777)),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF00A3A3), width: 1.5)),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF007777), width: 2)),
                              contentPadding:
                              EdgeInsets.symmetric(vertical: 8),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Campo requerido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildSpeciesDropdown(),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _breedController,
                            style: const TextStyle(
                                color: AppColors.textDark, fontSize: 14),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                              LengthLimitingTextInputFormatter(50),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Raza *',
                              labelStyle: TextStyle(color: Color(0xFF007777)),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF00A3A3), width: 1.5)),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color(0xFF007777), width: 2)),
                              contentPadding:
                              EdgeInsets.symmetric(vertical: 8),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Campo requerido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

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

                          const SizedBox(height: 24),

                          _sectionTitle('Datos del Dueño'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 13,
                                  color: const Color(0xFF007777).withOpacity(0.6)),
                              const SizedBox(width: 5),
                              const Text('Editables desde Configuración',
                                  style: TextStyle(
                                      fontSize: 12, color: AppColors.textLight)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _readOnlyField(
                            label: 'Nombre del dueño',
                            value: _ownerNameController.text,
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),

                          _readOnlyPhoneField(
                              value: _ownerPhoneController.text),

                          const SizedBox(height: 28),

                          _isSaving
                              ? const Center(
                            child: Column(children: [
                              CircularProgressIndicator(
                                  color: Color(0xFF007777)),
                              SizedBox(height: 8),
                              Text('Guardando...',
                                  style: TextStyle(
                                      color: AppColors.textMedium)),
                            ]),
                          )
                              : SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007777),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(26)),
                                elevation: 0,
                              ),
                              child: Text(
                                _isEditing
                                    ? 'GUARDAR CAMBIOS'
                                    : 'AGREGAR MASCOTA',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyField({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF007777).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF007777).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF007777).withOpacity(0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textLight)),
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

  Widget _readOnlyPhoneField({required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF007777).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF007777).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('+56',
              style: TextStyle(
                  color: Color(0xFF007777),
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
      onTap: _showPhotoOptions,
      child: Stack(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF007777).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF007777), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPhotoPreview(),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: Color(0xFF007777), shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Muestra la foto seleccionada tanto si es una ruta local (foto recién
  // elegida, aún no subida) como si ya es una URL de Supabase (mascota
  // existente que se está editando).
  Widget _buildPhotoPreview() {
    if (_photoPath == null) {
      return const Icon(Icons.pets, size: 44, color: Color(0xFF007777));
    }
    if (_photoPath!.startsWith('http://') || _photoPath!.startsWith('https://')) {
      return Image.network(
        _photoPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.pets, size: 44, color: Color(0xFF007777)),
      );
    }
    return Image.file(
      File(_photoPath!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
      const Icon(Icons.pets, size: 44, color: Color(0xFF007777)),
    );
  }

  Widget _buildSpeciesDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSpecies,
      decoration: const InputDecoration(
        labelText: 'Especie *',
        labelStyle: TextStyle(color: Color(0xFF007777)),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF00A3A3), width: 1.5)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF007777), width: 2)),
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
      dropdownColor: const Color(0xFFF5F5F0),
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      items: _species
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) => setState(() => _selectedSpecies = v!),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF007777)));
  }
}