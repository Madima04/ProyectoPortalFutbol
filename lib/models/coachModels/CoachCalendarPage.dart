import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarPage extends StatefulWidget {
  final int groupId;
  final int userId;
  final Future<String> nombreEntrenador;
  final Future<String> nombreEquipo;

  CalendarPage(
      this.groupId, this.userId, this.nombreEntrenador, this.nombreEquipo,
      {Key? key})
      : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState(
    groupId,
    userId,
    nombreEntrenador,
    nombreEquipo,
  );
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, Evento> _eventos = {};
  late int groupId;
  late int userId;
  late Future<String> nombreEntrenador;
  late Future<String> nombreEquipo;

  _CalendarPageState(
      this.groupId,
      this.userId,
      this.nombreEntrenador,
      this.nombreEquipo,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvents();
  }

  Future<void> eliminarEventoBD(DateTime fecha) async {
    final response = await Supabase.instance.client
        .from('Calendario')
        .delete()
        .eq('IdGrupo', widget.groupId)
        .eq('Fecha y hora', fecha.toString())
        .execute();

    if (response.error != null) {
      print('Error al eliminar el evento en Supabase: ${response.error}');
    } else {
      print('Evento eliminado en Supabase con éxito.');
    }
  }

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

  Future<void> _loadEvents() async {
    final response = await Supabase.instance.client
        .from('Calendario')
        .select()
        .eq('IdGrupo', widget.groupId)
        .execute();

    if (response.error != null) {
      print('Error al cargar los eventos desde Supabase: ${response.error}');
      return;
    }

    final List<dynamic>? eventosData = response.data;
    if (eventosData != null) {
      setState(() {
        _eventos = {};
        for (final evento in eventosData) {
          final DateTime fecha = DateTime.parse(evento['Fecha y hora'] ?? '');
          final String titulo = evento['Título'] ?? '';
          final String mensaje = evento['Mensaje'] ?? '';
          final int colorInt = evento['Color'] is int
              ? evento['Color']
              : int.parse(evento['Color']);
          final Color color =
          Color(colorInt); // Convierte el valor entero a un color
          _eventos[fecha] = Evento(titulo, mensaje, color);
        }
      });
    }
  }

  Future<void> _saveEvents() async {
    final List<Map<String, dynamic>> eventosData =
    _eventos.entries.map((entry) {
      return {
        'IdGrupo': widget.groupId,
        'Título': entry.value.titulo,
        'Fecha y hora': entry.key.toString(),
        // Ajusta el formato según lo necesites
        'Color': entry.value.color.value, // Almacena el valor entero del color
        // Ajusta según lo necesites
      };
    }).toList();

    final response = await Supabase.instance.client
        .from('Calendario')
        .upsert(eventosData)
        .execute();

    if (response.error != null) {
      // Manejar el error si ocurre
      print('Error al guardar los eventos en Supabase: ${response.error}');
    } else {
      // Actualizar la página después de guardar los eventos
      setState(() {
        _eventos = _eventos;
      });
      print('Eventos guardados en Supabase con éxito.');
    }
  }

  void anadirEvento(String titulo, String mensaje, Color color) {
    if (_selectedDay != null &&
        titulo.isNotEmpty &&
        !_eventos.containsKey(_selectedDay)) {
      setState(() {
        _eventos[_selectedDay!] = Evento(titulo, mensaje, color);
        _saveEvents();
      });
    }
  }

  void eliminarEvento(DateTime fecha) {
    if (_eventos.containsKey(fecha)) {
      setState(() {
        _eventos.remove(fecha);
        eliminarEventoBD(fecha);
        _saveEvents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.green,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Text(
              'Calendario',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black,
                    offset: Offset(5.0, 5.0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(vertical: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2010, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      eventLoader: (day) {
                        return _eventos[day] != null ? [_eventos[day]!] : [];
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        if (_eventos[_selectedDay!] != null) {
                          showDialog(
                            context: context,
                            builder: (context) => SimpleDialog(
                              title: Text('Eventos'),
                              children: [
                                ListTile(
                                  title: Text(_eventos[_selectedDay!]!.titulo),
                                  subtitle:
                                  Text(_eventos[_selectedDay!]!.mensaje),
                                  tileColor: _eventos[_selectedDay!]!
                                      .color
                                      .withOpacity(0.3),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    eliminarEvento(_selectedDay!);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Eliminar evento'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_eventos.containsKey(_selectedDay)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Este día ya tiene un evento')),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) {
                              TextEditingController tituloController =
                              TextEditingController();
                              TextEditingController mensajeController =
                              TextEditingController();
                              Color colorEvento = Colors.green;
                              return StatefulBuilder(
                                builder: (BuildContext context,
                                    StateSetter setState) {
                                  return AlertDialog(
                                    title: Text('Añadir evento'),
                                    content: SingleChildScrollView(
                                      child: ListBody(
                                        children: <Widget>[
                                          TextField(
                                            controller: tituloController,
                                            decoration: InputDecoration(
                                                hintText: "Título"),
                                          ),
                                          TextField(
                                            controller: mensajeController,
                                            decoration: InputDecoration(
                                                hintText: "Mensaje"),
                                          ),
                                          DropdownButton<Color>(
                                            value: colorEvento,
                                            items: <DropdownMenuItem<Color>>[
                                              DropdownMenuItem<Color>(
                                                value: Colors.green,
                                                child: Text('Partido'),
                                              ),
                                              DropdownMenuItem<Color>(
                                                value: Colors.blue,
                                                child: Text('Entrenamiento'),
                                              ),
                                              DropdownMenuItem<Color>(
                                                value: Colors.red,
                                                child: Text('Torneo'),
                                              ),
                                              DropdownMenuItem<Color>(
                                                value: Colors.yellow,
                                                child: Text('Evento'),
                                              ),
                                            ],
                                            onChanged: (Color? newValue) {
                                              setState(() {
                                                colorEvento = newValue!;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text('Cancelar'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text('Guardar'),
                                        onPressed: () {
                                          if (tituloController
                                              .text.isNotEmpty) {
                                            anadirEvento(
                                                tituloController.text,
                                                mensajeController.text,
                                                colorEvento);
                                            Navigator.of(context).pop();
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Color verde
                        padding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Nuevo Evento Calendario',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Evento {
  final String titulo;
  final String mensaje;
  final Color color;

  Evento(this.titulo, this.mensaje, this.color);
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CalendarPage(0, 0, Future.value(''), Future.value('')),
  ));
}
