import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PawID/models/pet.dart';
import 'package:PawID/screens/pet_detail_screen.dart';

// PetDetailScreen recibe la mascota directamente por props (no llama a
// ningún servicio en initState), así que estas pruebas no tocan red en
// ningún momento.

void main() {
  final pet = Pet(
    id: 'xyz789',
    name: 'Luna',
    species: 'Gato',
    breed: 'Siames',
    birthDate: '15/03/2021',
    ownerName: 'Pedro Ramírez',
    ownerPhone: '+56987654321',
    ownerEmail: 'pedro@email.com',
  );

  testWidgets('muestra los datos de la mascota y del dueño', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PetDetailScreen(pet: pet)));

    expect(find.text('Luna'), findsWidgets); // aparece en el AppBar y en el encabezado
    expect(find.text('Gato'), findsOneWidget);
    expect(find.text('Siames'), findsOneWidget);
    expect(find.text('15/03/2021'), findsOneWidget);
    expect(find.text('Pedro Ramírez'), findsOneWidget);
    expect(find.text('+56987654321'), findsOneWidget);
    expect(find.text('pedro@email.com'), findsOneWidget);
  });

  testWidgets('oculta la fila de email cuando el dueño no tiene uno', (tester) async {
    final petSinEmail = Pet(
      id: 'xyz789',
      name: 'Luna',
      species: 'Gato',
      breed: 'Siames',
      birthDate: '15/03/2021',
      ownerName: 'Pedro Ramírez',
      ownerPhone: '+56987654321',
      ownerEmail: '',
    );

    await tester.pumpWidget(MaterialApp(home: PetDetailScreen(pet: petSinEmail)));

    expect(find.text('Email'), findsNothing);
  });

  testWidgets('muestra la sección de código QR con el ID de la mascota', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PetDetailScreen(pet: pet)));

    expect(find.text('Código QR'), findsOneWidget);
    expect(find.text('ID: xyz789'), findsOneWidget);
  });
}
