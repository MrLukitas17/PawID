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
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _photoPath;
  bool _saving = false;
  bool _savingPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Requisitos de contraseña en tiempo real
  bool get _hasMinLength => _newPasswordController.text.length >= 10;
  bool get _hasUppercase => _newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _newPasswordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _newPasswordController.text.contains(RegExp(r'[!@#$%&*.,;:_=+?¿/\()[]{}^~|<>-]'));

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
    _photoPath = widget.currentPhotoPath.isNotEmpty ? widget.currentPhotoPath : null;
    // Escuchar cambios en contraseña para actualizar requisitos
    _newPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  // Guardar perfil
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

  // Cambiar contraseña
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    // Verifica que todos los requisitos se cumplan
    if (!_hasMinLength || !_hasUppercase || !_hasLowercase ||
        !_hasNumber || !_hasSpecial) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña no cumple todos los requisitos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _savingPassword = true);

    try {
      await AuthService.changePassword(
        userId: widget.userId,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Contraseña actualizada correctamente'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar contraseña: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Foto de perfil ────────────────────────────────────────
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

            // ── Información personal ──────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Información personal'),
                  const SizedBox(height: 16),

                  // Nombre
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

                  // Teléfono Chile
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

                  const SizedBox(height: 32),

                  // Botón guardar perfil
                  _saving
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ElevatedButton(
                    onPressed: _save,
                    child: const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            const Divider(color: Color(0xFFDDC4B0)),
            const SizedBox(height: 32),

            // ── Cambiar contraseña ────────────────────────────────────
            Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Cambiar contraseña'),
                  const SizedBox(height: 16),

                  // Nueva contraseña
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_showNewPassword,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.primary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textLight, size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showNewPassword = !_showNewPassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
                      if (!_hasMinLength || !_hasUppercase || !_hasLowercase ||
                          !_hasNumber || !_hasSpecial) {
                        return 'La contraseña no cumple los requisitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Indicadores de requisitos en tiempo real
                  _passwordRequirements(),
                  const SizedBox(height: 16),

                  // Confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.primary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textLight, size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                      if (v != _newPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Botón cambiar contraseña
                  _savingPassword
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ElevatedButton(
                    onPressed: _changePassword,
                    child: const Text('Cambiar contraseña'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Indicadores visuales de requisitos
  Widget _passwordRequirements() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Requisitos de la contraseña:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium)),
          const SizedBox(height: 8),
          _requirementRow('Mínimo 10 caracteres', _hasMinLength),
          _requirementRow('Al menos una mayúscula (A-Z)', _hasUppercase),
          _requirementRow('Al menos una minúscula (a-z)', _hasLowercase),
          _requirementRow('Al menos un número (0-9)', _hasNumber),
          _requirementRow('Al menos un carácter especial', _hasSpecial),
        ],
      ),
    );
  }

  Widget _requirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? Colors.green : AppColors.textLight,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green : AppColors.textLight,
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
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