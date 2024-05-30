import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coachModels/CoachHomePage.dart';
import '../models/coachModels/CoachProfilePage.dart';
import '../models/coachModels/CoachCalendarPage.dart';

class BottomNavigationBarWindow extends StatefulWidget {
  final int groupId;
  final int userId;
  final Future<String> nombreEntrenador;
  final Future<String> nombreEquipo;

  BottomNavigationBarWindow(
      this.groupId, this.userId, this.nombreEntrenador, this.nombreEquipo,
      {Key? key})
      : super(key: key);

  @override
  _BottomNavigationBarWindowState createState() =>
      _BottomNavigationBarWindowState(
          groupId, userId, nombreEntrenador, nombreEquipo);
}

class _BottomNavigationBarWindowState extends State<BottomNavigationBarWindow> {
  int _selectedIndex = 0;

  late int groupId;
  late int userId;
  late Future<String> nombreEntrenador;
  late Future<String> nombreEquipo;

  _BottomNavigationBarWindowState(
      this.groupId, this.userId, this.nombreEntrenador, this.nombreEquipo);

  Future<bool> esEntrenador() async {
    final response = await Supabase.instance.client
        .from('Usuario')
        .select('esEntrenador')
        .eq('id', widget.userId)
        .execute();

    if (response.error != null) {
      print('Error al cargar el ID del entrenador: ${response.error}');
      return false;
    }

    final idEntrenador = response.data?[0]['esEntrenador'] as bool?;
    return idEntrenador ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      HomePage(groupId, userId, nombreEntrenador, nombreEquipo),
      CalendarPage(groupId, userId, nombreEntrenador, nombreEquipo),
      ProfilePage(groupId, userId, nombreEntrenador, nombreEquipo),
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    // Establecer idioma en español
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BottomNavigationBarWindow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), // Cambiado a calendario
              label: 'Calendario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          // Cambiar color del ítem seleccionado a verde
          backgroundColor: Colors.white,
          // Cambiar color de fondo a blanco
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}