import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'pets_screen.dart';

class HomeScreen extends StatefulWidget {
  // Datos del usuario logueado (puedes pasarlos desde LoginScreen)
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    this.userName = 'Usuario',
    this.userEmail = 'usuario@email.com',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0=Inicio, 1=Mascotas

  final List<String> _titles = ['Inicio', 'Mascotas'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      drawer: _buildDrawer(),
      body: _selectedIndex == 0 ? _buildHome() : const PetsScreen(),
    );
  }

  // ─── DRAWER (menú lateral) ────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón cerrar
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.accent),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Perfil del usuario
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.userEmail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFDDC4B0), height: 1),
            const SizedBox(height: 8),

            // Ítem: Inicio
            _drawerItem(
              icon: Icons.home_outlined,
              label: 'Inicio',
              index: 0,
            ),

            // Ítem: Mascotas (con submenú / flecha)
            _drawerItem(
              icon: Icons.pets_outlined,
              label: 'Mascotas',
              index: 1,
            ),

            const Spacer(),
            const Divider(color: Color(0xFFDDC4B0), height: 1),

            // Ítem: Configuración
            _drawerItem(
              icon: Icons.settings_outlined,
              label: 'Configuración',
              index: -1, // sin pantalla por ahora
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración próximamente'),
                    backgroundColor: AppColors.primaryLight,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textMedium,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight:
            isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textMedium,
          ),
        ),
        trailing: index >= 0
            ? Icon(
          isSelected
              ? Icons.chevron_left
              : Icons.chevron_right,
          color: isSelected ? AppColors.primary : AppColors.textLight,
          size: 20,
        )
            : null,
        onTap: onTap ??
                () {
              setState(() => _selectedIndex = index);
              Navigator.pop(context);
            },
      ),
    );
  }

  // ─── PANTALLA INICIO ──────────────────────────────────────────────────────
  Widget _buildHome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, ${widget.userName.split(' ').first}! 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gestiona los datos de tus mascotas',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 32),

          // Tarjeta acceso rápido a Mascotas
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.pets, color: AppColors.white, size: 36),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Mascotas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ver, agregar o editar mascotas',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFEDD5C0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: AppColors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}