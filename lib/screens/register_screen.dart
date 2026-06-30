import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _acceptedTerms = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailError;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _validateEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) return;
    final exists = await AuthService.emailExists(email);
    if (mounted) {
      setState(() {
        _emailError = exists ? 'Este email ya está registrado.' : null;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los Términos de Servicio'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_emailError != null) return;

    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _errorMessage = null; });

    final error = await AuthService.register(
      nombre: _nombreController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Cuenta creada exitosamente. Inicia sesión.'),
        backgroundColor: Color(0xFF007777),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.pop(context);
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFE0F7FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Términos de Servicio',
            style: TextStyle(color: Color(0xFF007777), fontWeight: FontWeight.w700)),
        content: const SingleChildScrollView(
          child: Text(
            'Al usar PawID aceptas que:\n\n'
                '• Tus datos se almacenan de forma segura.\n'
                '• La información de tus mascotas es de uso personal.\n'
                '• No compartimos tus datos con terceros.\n',
            style: TextStyle(color: Color(0xFF333333), fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() => _acceptedTerms = true);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007777),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/registro.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // Contenido scrollable
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Icon(Icons.pets, color: Color(0xFF007777), size: 32),
                      Icon(Icons.add, color: Color(0xFF007777), size: 32),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Card con formulario — blanco semitransparente
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crear Cuenta',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF007777),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildField(
                            controller: _nombreController,
                            label: 'Nombre completo',
                            icon: Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty ? 'Ingresa tu nombre' : null,
                          ),
                          const SizedBox(height: 14),
                          Focus(
                            onFocusChange: (hasFocus) {
                              if (!hasFocus) _validateEmail();
                            },
                            child: _buildField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Ingresa tu email';
                                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Email inválido';
                                if (_emailError != null) return _emailError;
                                return null;
                              },
                            ),
                          ),
                          if (_emailError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(_emailError!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                            ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _passwordController,
                            label: 'Contraseña',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                              if (v.length < 8) return 'Mínimo 8 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _confirmController,
                            label: 'Confirmar contraseña',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                              if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24, height: 24,
                                child: Checkbox(
                                  value: _acceptedTerms,
                                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                                  activeColor: const Color(0xFF007777),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                  side: const BorderSide(color: Color(0xFF007777), width: 1.5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Acepto los Términos de Servicio y la Política de Privacidad.',
                                  style: TextStyle(
                                      color: Color(0xFF333333), fontSize: 12, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Text(_errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                  textAlign: TextAlign.center),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón crear cuenta
                  _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF007777))
                      : _boton(
                    texto: 'CREAR CUENTA',
                    color: const Color(0xFF007777),
                    onTap: _handleRegister,
                  ),
                  const SizedBox(height: 12),

                  // Volver al inicio — verde claro
                  _boton(
                    texto: 'VOLVER AL INICIO',
                    color: const Color(0xFF00A3A3),
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 12),

                  // Ver términos — salmón
                  _boton(
                    texto: 'VER TÉRMINOS',
                    color: const Color(0xFFFF8C69),
                    onTap: _showTermsDialog,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boton({required String texto, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          elevation: 0,
        ),
        child: Text(texto,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    bool obscure = true;
    return StatefulBuilder(
      builder: (context, setFieldState) {
        return TextFormField(
          controller: controller,
          obscureText: isPassword && obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF333333), fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: const Color(0xFF007777), size: 20),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF007777),
                size: 20,
              ),
              onPressed: () => setFieldState(() => obscure = !obscure),
            )
                : null,
            labelStyle: const TextStyle(color: Color(0xFF007777), fontSize: 13),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00A3A3), width: 1.5)),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF007777), width: 2)),
            errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF8C69), width: 1.5)),
            focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF8C69), width: 2)),
          ),
        );
      },
    );
  }
}