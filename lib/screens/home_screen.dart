import 'package:flutter/material.dart';
import 'package:proyecto_1/screens/pest_screen.dart' hide PetsScreen;
import '../theme/app_theme.dart';
import 'pest_screen.dart';
import 'calendario_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userId;

  const HomeScreen({
    super.key,
    this.userName = 'Usuario',
    this.userEmail = 'usuario@email.com',
    this.userId = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<String> _titles = ['Inicio', 'Mascotas', 'Calendario'];

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
      case 1: return PetsScreen(userId: widget.userId);
      case 2: return CalendarioScreen(userId: widget.userId);
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
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.accent),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.userName,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(widget.userEmail,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFDDC4B0), height: 1),
            const SizedBox(height: 8),
            _drawerItem(icon: Icons.home_outlined, label: 'Inicio', index: 0),
            _drawerItem(icon: Icons.pets_outlined, label: 'Mascotas', index: 1),
            _drawerItem(icon: Icons.calendar_month_outlined, label: 'Calendario', index: 2),
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
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Configuración próximamente'),
                      backgroundColor: AppColors.primaryLight),
                );
              },
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
            '¡Hola, ${widget.userName.split(' ').first}! 👋',
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