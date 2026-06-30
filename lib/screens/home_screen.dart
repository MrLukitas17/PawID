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
      case 1:
        return PetsScreen(
          userId: widget.userId,
          ownerName: _userName != 'Usuario' ? _userName : '',
          ownerPhone: _userPhone,
          onBack: () => setState(() => _selectedIndex = 0),
        );
      case 2:
      // ✅ MODIFICADO: Añadido onBack para redirigir al menú principal (Inicio)
        return CalendarioScreen(
          userId: widget.userId,
          onBack: () => setState(() => _selectedIndex = 0),
        );
      case 3:
        return HistorialScreen(
          usuarioId: widget.userId,
          onBack: () => setState(() => _selectedIndex = 0),
        );
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    return Stack(
      children: [
        // Imagen de fondo
        Positioned.fill(
          child: Image.asset(
            'assets/images/menu.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),

        // Contenido
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saludo
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  '¡Hola, ${_userName.split(' ').first}! 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Text(
                  'Gestiona los datos de tus mascotas',
                  style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                ),
              ),

              // Cards centradas verticalmente
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _navCard(
                            icon: Icons.pets,
                            title: 'Mis Mascotas',
                            subtitle: 'Ver, agregar o editar mascotas',
                            onTap: () => setState(() => _selectedIndex = 1),
                            color: const Color(0xFF4A9B8E),
                          ),
                          const SizedBox(height: 12),
                          _navCard(
                            icon: Icons.calendar_month_outlined,
                            title: 'Calendario',
                            subtitle: 'Vacunas, controles y medicamentos',
                            onTap: () => setState(() => _selectedIndex = 2),
                            color: const Color(0xFF5BA89A),
                          ),
                          const SizedBox(height: 12),
                          _navCard(
                            icon: Icons.medical_services_outlined,
                            title: 'Historial Médico',
                            subtitle: 'Registros y documentos médicos',
                            onTap: () => setState(() => _selectedIndex = 3),
                            color: const Color(0xFF007777),
                          ),
                          const SizedBox(height: 12),
                          _navCard(
                            icon: Icons.qr_code_scanner_outlined,
                            title: 'Escanear QR',
                            subtitle: 'Abre la ficha PDF de una mascota',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const QrScannerScreen()),
                            ),
                            color: const Color(0xFF6BB5A8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.accent),
                onPressed: () => Navigator.pop(context),
              ),
            ),
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFB94040), size: 22),
                title: const Text('Cerrar sesión',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB94040))),
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
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
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
        trailing: Icon(isSelected ? Icons.chevron_left : Icons.chevron_right,
            color: isSelected ? AppColors.primary : AppColors.textLight, size: 20),
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
}