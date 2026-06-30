import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/paw_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _emailVerified = false;
  String? _userId;
  bool _loading = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Lógica de requisitos
  bool get _hasMinLength => _newPasswordController.text.length >= 10;
  bool get _hasUppercase => _newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _newPasswordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _newPasswordController.text.contains(RegExp(r'[!@#%&*.,;:_=+?\-/\\()\[\]{}^~|<>]'));
  bool get _allMet => _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber && _hasSpecial;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final user = await AuthService.findUserByEmail(_emailController.text.trim().toLowerCase());
      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No existe una cuenta con ese email'), backgroundColor: Colors.redAccent));
      } else {
        setState(() { _emailVerified = true; _userId = user['id']; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    if (!_allMet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña no cumple todos los requisitos'), backgroundColor: Colors.orange));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthService.changePassword(userId: _userId!, newPassword: _newPasswordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Contraseña actualizada correctamente'), backgroundColor: AppColors.primary));
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar contraseña: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Recuperar contraseña', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.lock_reset, size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),

            if (!_emailVerified) ...[
              const Text('Ingresa tu email registrado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 8),
              const Text('Verificaremos que exista una cuenta con ese email.', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
              const SizedBox(height: 32),
              Form(
                key: _emailFormKey,
                child: Column(
                  children: [
                    PawTextField(label: 'Email', hint: 'ejemplo@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 32),
                    _loading ? const CircularProgressIndicator(color: AppColors.primary) : ElevatedButton(onPressed: _verifyEmail, child: const Text('Verificar email')),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Email verificado: ${_emailController.text}', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Crea tu nueva contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 24),
              Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_showNewPassword,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        suffixIcon: IconButton(icon: Icon(_showNewPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showNewPassword = !_showNewPassword)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _passwordRequirements(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        suffixIcon: IconButton(icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword)),
                      ),
                      validator: (v) => v != _newPasswordController.text ? 'Las contraseñas no coinciden' : null,
                    ),
                    const SizedBox(height: 32),
                    _loading ? const CircularProgressIndicator(color: AppColors.primary) : ElevatedButton(onPressed: _changePassword, child: const Text('Cambiar contraseña')),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _passwordRequirements() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _allMet ? Colors.green.withOpacity(0.05) : AppColors.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _allMet ? Colors.green.withOpacity(0.3) : AppColors.primary.withOpacity(0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_allMet ? '¡Contraseña segura!' : 'Requisitos:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _allMet ? Colors.green : AppColors.primary)),
        const SizedBox(height: 8),
        _requirementRow('Mínimo 10 caracteres', _hasMinLength),
        _requirementRow('Al menos una mayúscula (A-Z)', _hasUppercase),
        _requirementRow('Al menos una minúscula (a-z)', _hasLowercase),
        _requirementRow('Al menos un número (0-9)', _hasNumber),
        _requirementRow('Al menos un carácter especial', _hasSpecial),
      ],
    ),
  );

  Widget _requirementRow(String text, bool met) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(met ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: met ? Colors.green : AppColors.textLight),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: met ? Colors.green : AppColors.textLight)),
      ],
    ),
  );
}