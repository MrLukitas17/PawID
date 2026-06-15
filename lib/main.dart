import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar locale español para el calendario
  await initializeDateFormatting('es_ES', null);

  await Supabase.initialize(
    url: 'https://ujsokaxksqwqojvctvtx.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqc29rYXhrc3F3cW9qdmN0dnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5NDczMjYsImV4cCI6MjA5NjUyMzMyNn0.-Z2vF2M6KuBgv0xikU603xgJV2SegB3P0a8CNlTL9IM',
  );

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
      // Soporte de localización para español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
      home: const LoginScreen(),
    );
  }
}