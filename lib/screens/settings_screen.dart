import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final String currentName;
  final String currentPhone;
  final String currentPhotoPath;

  const SettingsScreen({
    super.key,
    required this.userId,
    this.currentName = '',
    this.currentPhone = '',
    this.currentPhotoPath = '',
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _photoPath = widget.currentPhotoPath.isNotEmpty ? widget.currentPhotoPath : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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
              onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Elegir de galería'),
              onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.gallery); },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Eliminar foto',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _photoPath = null);
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
        maxWidth: 600,
      );
      if (photo != null && mounted) {
        setState(() => _photoPath = photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la imagen: $e'),
              backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      await AuthService.updateProfile(
        userId: widget.userId,
        nombre: _nameController.text.trim(),
        telefono: _phoneController.text.trim(),
        fotoPath: _photoPath ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, {
          'nombre': _nameController.text.trim(),
          'telefono': _phoneController.text.trim(),
          'foto_path': _photoPath ?? '',
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Configuración',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Foto de perfil ──────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _selectPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        backgroundImage: _photoPath != null
                            ? FileImage(File(_photoPath!))
                            : null,
                        child: _photoPath == null
                            ? const Icon(Icons.person, size: 56, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Toca para cambiar foto',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight)),
              ),

              const SizedBox(height: 32),
              _sectionTitle('Información personal'),
              const SizedBox(height: 16),

              // ── Nombre ──────────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Lucas González',
                  prefixIcon: Icon(Icons.person_outline,
                      color: AppColors.primary, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
                  if (v.trim().length < 2) return 'Nombre muy corto';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Teléfono Chile (+56) ────────────────────────────────
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: '9 1234 5678',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('+56',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        SizedBox(width: 8),
                        SizedBox(height: 20,
                            child: VerticalDivider(
                                color: AppColors.inputUnderline, width: 1)),
                      ],
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (v.length != 9) return 'Debe tener 9 dígitos';
                  if (!v.startsWith('9')) return 'Los celulares chilenos empiezan con 9';
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // ── Botón guardar ───────────────────────────────────────
              _saving
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                onPressed: _save,
                child: const Text('Guardar cambios'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary));
  }
}