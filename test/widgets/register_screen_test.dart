import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PawID/screens/register_screen.dart';

// Estas pruebas evitan escribir en el campo de email: al perder el foco
// dispara _validateEmail(), que si el formato es válido llama a
// AuthService.emailExists() contra Supabase real. Dejándolo vacío seguimos
// cubriendo su validador (Form.validate() sí lo ejecuta) sin tocar red.

void main() {
  Future<void> pumpRegister(WidgetTester tester) async {
//    await tester.pumpWidget(const MaterialApp(home: register_screen()));
  }

  testWidgets('muestra el título y subtítulo de registro al cargar', (tester) async {
    await pumpRegister(tester);

    expect(find.text('Registro'), findsOneWidget);
    expect(find.text('Crea tu cuenta en PawID'), findsOneWidget);
  });

  testWidgets('si no se aceptan los términos, muestra el aviso y no valida el formulario', (tester) async {
    await pumpRegister(tester);

    await tester.tap(find.text('Crear Cuenta'));
    await tester.pump();

    expect(find.text('Debes aceptar los Términos de Servicio'), findsOneWidget);
  });

  testWidgets('con términos aceptados y campos vacíos, muestra todos los mensajes requeridos', (tester) async {
    await pumpRegister(tester);

    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('Crear Cuenta'));
    await tester.pump();

    expect(find.text('Ingresa tu nombre'), findsOneWidget);
    expect(find.text('Ingresa tu email'), findsOneWidget);
    expect(find.text('Ingresa una contraseña'), findsOneWidget);
    expect(find.text('Confirma tu contraseña'), findsOneWidget);
  });

  testWidgets('contraseña menor a 8 caracteres muestra el mensaje correspondiente', (tester) async {
    await pumpRegister(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo *'), 'Camila Soto');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña *'), '1234567');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirmar contraseña *'), '1234567');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('Crear Cuenta'));
    await tester.pump();

    expect(find.text('Mínimo 8 caracteres'), findsOneWidget);
  });

  testWidgets('si las contraseñas no coinciden, muestra el mensaje correspondiente', (tester) async {
    await pumpRegister(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo *'), 'Camila Soto');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña *'), 'password123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirmar contraseña *'), 'otraClave123');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('Crear Cuenta'));
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
  });
}
