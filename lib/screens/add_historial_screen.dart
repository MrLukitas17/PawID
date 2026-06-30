import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/registro_medico.dart';
import '../models/pet.dart';
import '../services/historial_service.dart';
import '../services/pet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paw_text_field.dart';

class AddHistorialScreen extends StatefulWidget {
  final String userId;
  final RegistroMedico? registro;

  const AddHistorialScreen({
    super.key,
    required this.userId,
    this.registro,
  });

  @override
  State<AddHistorialScreen> createState() => _AddHistorialScreenState();
}

class _AddHistorialScreenState extends State<AddHistorialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();

  List<Pet> _pets = [];
  String? _petId;
  String _petName = '';
  String? _photoPath;
  bool _saving = false;

  bool get _isEditing => widget.registro != null;

  @override
  void initState() {
    super.initState();
    _loadPets();
    if (_isEditing) {
      final r = widget.registro!;
      _nameController.text = r.nombre;
      _dateController.text = r.fecha;
      _notesController.text = r.notas;
      _petId = r.mascotaId;
      _petName = r.mascotaNombre;
      _photoPath = r.fotoUrl.isNotEmpty ? r.fotoUrl : null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    final pets = await PetStorageService.loadPets(userId: widget.userId);
    setState(() {
      _pets = pets;
      if (pets.isNotEmpty && _petId == null) {
        _petId = pets.first.id;
        _petName = pets.first.name;
      }
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.background,
          ),
        ),
        child: child!,
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _dateController.text =
        '${selected.day.toString().padLeft(2, '0')}/'
            '${selected.month.toString().padLeft(2, '0')}/'
            '${selected.year}';
      });
    }
  }

  Future<void> _selectPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (photo != null && mounted) {
        setState(() => _photoPath = photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo obtener la imagen: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una mascota'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final registro = RegistroMedico(
        id: _isEditing
            ? widget.registro!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        usuarioId: widget.userId,
        mascotaId: _petId!,
        mascotaNombre: _petName,
        nombre: _nameController.text.trim(),
        fecha: _dateController.text.trim(),
        fotoUrl: _photoPath ?? '',
        notas: _notesController.text.trim(),
      );

      if (_isEditing) {
        await ServicioHistorial.actualizarRegistro(registro);
      } else {
        await ServicioHistorial.agregarRegistro(registro);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? '✅ Registro actualizado'
                : '✅ Registro guardado'),
            backgroundColor: Color(0xFF00A3A3),
            duration: const Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Editar Registro' : 'Nuevo Registro Médico',
          style: const TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Fondo
            Positioned.fill(
              child: Image.asset(
                'assets/images/historial_medico.png',
                fit: BoxFit.cover,
              ),
            ),
            // Contenido
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _sectionTitle('Mascota'),
                        const SizedBox(height: 12),
                        _pets.isEmpty
                            ? const Text('No tienes mascotas registradas',
                            style: TextStyle(color: AppColors.textMedium))
                            : DropdownButtonFormField<String>(
                          value: _petId,
                          decoration: const InputDecoration(
                            labelText: 'Selecciona la mascota *',
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.inputUnderline, width: 1.5)),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: AppColors.primary, width: 2)),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          dropdownColor: AppColors.background,
                          style: const TextStyle(
                              color: AppColors.textDark, fontSize: 14),
                          items: _pets
                              .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Row(
                              children: [
                                const Icon(Icons.pets,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(p.name),
                              ],
                            ),
                          ))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _petId = v;
                              _petName =
                                  _pets.firstWhere((p) => p.id == v).name;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('Detalles del Registro'),
                        const SizedBox(height: 12),
                        PawTextField(
                          label: 'Nombre del registro *',
                          hint: 'Ej: Control anual, Vacuna antirrábica...',
                          controller: _nameController,
                          validator: (v) =>
                          v == null || v.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: PawTextField(
                              label: 'Fecha (opcional)',
                              hint: 'Toca para seleccionar',
                              controller: _dateController,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PawTextField(
                          label: 'Notas (opcional)',
                          hint: 'Observaciones del veterinario...',
                          controller: _notesController,
                        ),
                        const SizedBox(height: 24),
                        _sectionTitle('Foto o Documento'),
                        const SizedBox(height: 12),
                        _photoPath != null ? _photoPreview() : _addPhotoButton(),
                        const SizedBox(height: 24),
                        _saving
                            ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                            : ElevatedButton(
                          onPressed: _save,
                          child: Text(_isEditing
                              ? 'Guardar Cambios'
                              : 'Guardar Registro'),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addPhotoButton() {
    return GestureDetector(
      onTap: _selectPhoto,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 36, color: AppColors.primary),
            SizedBox(height: 8),
            Text('Toca para agregar foto o documento',
                style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _photoPreview() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(_photoPath!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.image_not_supported,
                  size: 48, color: AppColors.textLight),
            ),
          ),
        ),
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _photoPath = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          bottom: 8, right: 8,
          child: GestureDetector(
            onTap: _selectPhoto,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.primary),
    );
  }
}