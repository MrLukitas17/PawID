import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PawID/screens/add_pet_screen.dart';

// _save() solo llama a PetStorageService después de que
// _formKey.currentState!.validate() pasa; con campos vacíos, validate()
// falla antes de tocar red, así que estas pruebas son seguras tal cual.

void main() {
  testWidgets('muestra "Nueva Mascota" cuando no se pasa una mascota existente', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddPetScreen()));

    expect(find.text('Nueva Mascota'), findsOneWidget);
    expect(find.text('Agregar Mascota'), findsOneWidget);
  });

  testWidgets('la especie inicia en "Perro"', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddPetScreen()));

    expect(find.text('Perro'), findsOneWidget);
  });

  testWidgets('permite cambiar la especie desde el dropdown', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddPetScreen()));

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gato').last);
    await tester.pumpAndSettle();

    expect(find.text('Gato'), findsOneWidget);
  });

  testWidgets('con todos los campos vacíos, muestra "Campo requerido" en cada uno', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddPetScreen()));

    await tester.tap(find.text('Agregar Mascota'));
    await tester.pump();

    // Nombre, Raza, Fecha de Nacimiento, Nombre del dueño y Teléfono
    expect(find.text('Campo requerido'), findsNWidgets(5));
  });
}
