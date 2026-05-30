import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PawIDApp());
}

class PawIDApp extends StatelessWidget {
  const PawIDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawID',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}