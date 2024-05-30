import 'package:GolNet/main.dart';
import 'package:GolNet/models/padresModels/PadresHomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('PadresHomePage renders correctly', (WidgetTester tester) async {
    // Simulamos la construcción del widget
    await tester.pumpWidget(MaterialApp(
        home: PadresHomePage(
      1, // groupId
      1, // userId
      Future.value('NombreEntrenador'), // nombreEntrenador
      Future.value('NombreEquipo'), // nombreEquipo
    )));

    expect(find.text('Foro del Grupo'), findsOneWidget);
  });

  testWidgets('MyHomePage renders correctly', (WidgetTester tester) async {
    // Simulamos la construcción del widget
    await tester.pumpWidget(MaterialApp(
      home: MyHomePage(),
    ));

    // Verificamos que el texto '¡Bienvenido a la aplicación del foro de fútbol! Aquí podrás mejorar la conexión entre el entrenador y los padres de los jugadores para facilitar la comunicación.' se renderice correctamente
    expect(
        find.text(
            '¡Bienvenido a la aplicación del foro de fútbol! Aquí podrás mejorar la conexión entre el entrenador y los padres de los jugadores para facilitar la comunicación.'),
        findsOneWidget);

    // Verificamos que los botones 'Iniciar sesión' y 'Registrarse' estén presentes
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Registrarse'), findsOneWidget);
  });

}
