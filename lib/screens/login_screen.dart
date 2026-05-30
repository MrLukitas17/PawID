import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/paw_text_field.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // TODO: Conectar con Firebase Auth u otro backend
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: 'Usuario',
              userEmail: _emailController.text,
            ),
          ),
        );
      }
    }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad próximamente'),
        backgroundColor: AppColors.primaryLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                _buildLogo(),
                const SizedBox(height: 48),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                PawTextField(
                  label: 'Email',
                  hint: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu email';
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                PawTextField(
                  label: 'Contraseña',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                    if (value.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : ElevatedButton(
                  onPressed: _handleLogin,
                  child: const Text('Entrar'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _handleForgotPassword,
                      child: const Text(
                        '¿Olvidaste Tu Contraseña?',
                        style: TextStyle(color: AppColors.textMedium, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        'Regístrate',
                        style: TextStyle(
                          color: AppColors.linkColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Icon(Icons.pets, size: 42, color: AppColors.primary),
        ),
        const SizedBox(height: 10),
        const Text(
          'PawID',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}