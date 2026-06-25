import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'pets_screen.dart';
import 'calendario_screen.dart';
import 'qr_scanner_screen.dart';
import 'historial_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userId;
  final String userPhone;
  final String userPhotoPath;

  const HomeScreen({
    super.key,
    this.userName = 'Usuario',
    this.userEmail = 'usuario@email.com',
    this.userId = '',
    this.userPhone = '',
    this.userPhotoPath = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<String> _titles = ['Inicio', 'Mascotas', 'Calendario', 'Historial'];

  // Estado del perfil (puede cambiar desde Configuración)
  late String _userName;
  late String _userPhone;
  late String _userPhotoPath;

  @override
  void initState() {
    super.initState();
    final nombre = widget.userName.trim();
    _userName = nombre.isNotEmpty ? nombre : 'Usuario';
    _userPhone = widget.userPhone;
    _userPhotoPath = widget.userPhotoPath;
  }

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
              fontSize: 22),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            tooltip: 'Escanear QR',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QrScannerScreen())),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 1: return PetsScreen(
        userId: widget.userId,
        ownerName: _userName != 'Usuario' ? _userName : '',
        ownerPhone: _userPhone,
      );
      case 2: return CalendarioScreen(userId: widget.userId);
    // Corregido: usuarioId en lugar de userId
      case 3: return HistorialScreen(usuarioId: widget.userId);
      default: return _buildHome();
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón cerrar drawer
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.accent),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Perfil centrado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      backgroundImage: _userPhotoPath.isNotEmpty
                          ? FileImage(File(_userPhotoPath))
                          : null,
                      child: _userPhotoPath.isEmpty
                          ? const Icon(Icons.person, size: 44, color: AppColors.primary)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: Color(0xFFDDC4B0), height: 1),
            const SizedBox(height: 8),

            // Menú de navegación
            _drawerItem(icon: Icons.home_outlined, label: 'Inicio', index: 0),
            _drawerItem(icon: Icons.pets_outlined, label: 'Mascotas', index: 1),
            _drawerItem(icon: Icons.calendar_month_outlined, label: 'Calendario', index: 2),
            _drawerItem(icon: Icons.medical_services_outlined, label: 'Historial Médico', index: 3),
            _drawerItemAction(
              icon: Icons.qr_code_scanner_outlined,
              label: 'Escanear QR',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const QrScannerScreen()));
              },
            ),

            const Spacer(),
            const Divider(color: Color(0xFFDDC4B0), height: 1),

            // Configuración
            _drawerItemAction(
              icon: Icons.settings_outlined,
              label: 'Configuración',
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      userId: widget.userId,
                      currentName: _userName,
                      currentPhone: _userPhone,
                      currentPhotoPath: _userPhotoPath,
                    ),
                  ),
                );
                // Actualizar perfil en el drawer si hubo cambios
                if (result != null && mounted) {
                  setState(() {
                    final nombre = (result['nombre'] ?? '').toString().trim();
                    _userName = nombre.isNotEmpty ? nombre : 'Usuario';
                    _userPhone = result['telefono'] ?? _userPhone;
                    _userPhotoPath = result['foto_path'] ?? _userPhotoPath;
                  });
                }
              },
            ),

            // Botón cerrar sesión
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFB94040), size: 22),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB94040)),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFFB94040), size: 20),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('Cerrar sesión',
                          style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700)),
                      content: const Text('¿Estás seguro que quieres cerrar sesión?',
                          style: TextStyle(color: AppColors.textMedium)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar',
                              style: TextStyle(color: AppColors.textMedium)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Cerrar sesión',
                              style: TextStyle(
                                  color: Color(0xFFB94040),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                  if (confirmar == true) {
                    // Cerrar sesión en Supabase y volver al login
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false, // Elimina todo el stack de navegación
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isSelected ? AppColors.primary : AppColors.textMedium, size: 22),
        title: Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMedium)),
        trailing: Icon(
            isSelected ? Icons.chevron_left : Icons.chevron_right,
            color: isSelected ? AppColors.primary : AppColors.textLight,
            size: 20),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _drawerItemAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textMedium, size: 22),
        title: Text(label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textMedium)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildHome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, ${_userName.split(' ').first}! 👋',
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          const Text('Gestiona los datos de tus mascotas',
              style: TextStyle(fontSize: 14, color: AppColors.textMedium)),
          const SizedBox(height: 32),
          _buildHomeCard(
            icon: Icons.pets,
            title: 'Mis Mascotas',
            subtitle: 'Ver, agregar o editar mascotas',
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 16),
          _buildHomeCard(
            icon: Icons.calendar_month,
            title: 'Calendario',
            subtitle: 'Vacunas, controles y medicamentos',
            onTap: () => setState(() => _selectedIndex = 2),
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 16),
          _buildHomeCard(
            icon: Icons.medical_services,
            title: 'Historial Médico',
            subtitle: 'Registros y documentos médicos',
            onTap: () => setState(() => _selectedIndex = 3),
            color: const Color(0xFF5A7A3A),
          ),
          const SizedBox(height: 16),
          _buildHomeCard(
            icon: Icons.qr_code_scanner,
            title: 'Escanear QR',
            subtitle: 'Abre la ficha PDF de una mascota',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const QrScannerScreen())),
            color: const Color(0xFF8B5A3A),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFEDD5C0))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.white, size: 18),
          ],
        ),
      ),
    );
  }
}