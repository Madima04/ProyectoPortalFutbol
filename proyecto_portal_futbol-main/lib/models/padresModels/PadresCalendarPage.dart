import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PadresCalendarPage extends StatefulWidget {
  final int groupId;
  final int userId;
  final Future<String> nombreEntrenador;
  final Future<String> nombreEquipo;

  PadresCalendarPage(
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

class _CalendarPageState extends State<PadresCalendarPage> {
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
          _eventos[fecha] = Evento(titulo, mensaje, color, fecha);
        }
      });
    }
  }

  Future<void> _saveEvents() async {
    // Convertir los eventos a un formato adecuado para guardarlos en la base de datos
    final List<Map<String, dynamic>> eventosData = _eventos.entries.map((entry) {
      return {
        'IdGrupo': widget.groupId,
        'Título': entry.value.titulo,
        'Fecha y hora': entry.key.toString(),
        'Color': entry.value.color.value,
        'personasConfirmadas': entry.value.personasConfirmadas ?? [], // Incluir personasConfirmadas
      };
    }).toList();

    // Insertar o actualizar los eventos en la tabla de Supabase
    final response = await Supabase.instance.client
        .from('Calendario')
        .upsert(eventosData)
        .execute();

    if (response.error != null) {
      // Manejar el error si ocurre
      print('Error al guardar los eventos en Supabase: ${response.error}');
    } else {
      print('Eventos guardados en Supabase con éxito.');
    }
  }

  void anadirEvento(String titulo, String mensaje, Color color) {
    if (_selectedDay != null &&
        titulo.isNotEmpty &&
        !_eventos.containsKey(_selectedDay)) {
      setState(() {
        _eventos[_selectedDay!] = Evento(titulo, mensaje, color, _selectedDay!);
        _saveEvents();
      });
    }
  }

  void confirmarAsistencia(BuildContext context) async {
    if (_selectedDay != null && _eventos.containsKey(_selectedDay)) {
      final confirmedPeople = _eventos[_selectedDay!]!.personasConfirmadas ?? [];

      // Obtener el nombre del entrenador
      final nombre = await widget.nombreEntrenador;

      // Agregar el nombre del entrenador a la lista de confirmaciones si no está presente
      if (!confirmedPeople.contains(nombre)) {
        confirmedPeople.add(nombre);
        // Actualizar el evento con la nueva lista de confirmaciones
        final eventoActualizado = _eventos[_selectedDay!]!.copyWith(personasConfirmadas: confirmedPeople);
        await _updateEvent(eventoActualizado);

        // Mostrar un diálogo emergente de confirmación
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirmación de asistencia'),
              content: Text('Te has añadido correctamente al evento.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Aceptar'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _updateEvent(Evento eventoActualizado) async {
    // Primero, obtenemos los datos existentes del evento de la base de datos
    final response1 = await Supabase.instance.client
        .from('Calendario')
        .select('personasConfirmadas')
        .eq('Fecha y hora', eventoActualizado.fecha.toString())
        .execute();

    if (response1.error != null) {
      print('Error al obtener los datos del evento de Supabase: ${response1.error}');
      return;
    }

    final List<dynamic>? data = response1.data;
    List<String> personasConfirmadas = [];

    if (data != null && data.isNotEmpty && data[0]['personasConfirmadas'] != null) {
      // Si hay datos existentes, obtenemos la lista de personas confirmadas
      personasConfirmadas = List<String>.from(data[0]['personasConfirmadas']);
    }

    // Agregamos las nuevas personas confirmadas a la lista existente
    if (eventoActualizado.personasConfirmadas != null) {
      personasConfirmadas.addAll(eventoActualizado.personasConfirmadas!);
    }

    // Actualizamos los datos del evento con la nueva lista de personas confirmadas
    final Map<String, dynamic> eventData = {
      'Título': eventoActualizado.titulo,
      'Color': eventoActualizado.color.value,
      'personasConfirmadas': personasConfirmadas,
    };

    // Luego, actualizamos el evento en la base de datos
    final response2 = await Supabase.instance.client
        .from('Calendario')
        .update(eventData)
        .eq('Fecha y hora', eventoActualizado.fecha.toString())
        .execute();

    if (response2.error != null) {
      // Manejar el error si ocurre
      print('Error al actualizar el evento en Supabase: ${response2.error}');
    } else {
      print('Evento actualizado en Supabase con éxito.');
    }
  }

  MapEntry<DateTime, Evento>? getProximoEvento() {
    final hoy = DateTime.now();
    final fechasFuturas =
    _eventos.keys.where((fecha) => fecha.isAfter(hoy)).toList();
    fechasFuturas.sort();
    return fechasFuturas.isNotEmpty
        ? MapEntry(fechasFuturas.first, _eventos[fechasFuturas.first]!)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final proximoEvento = getProximoEvento();
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
                        _showEventDialog(context);
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
                    ProximoEvento(proximoEvento: proximoEvento),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDialog(BuildContext context) {
    if (_eventos[_selectedDay!] != null) {
      showDialog(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('Eventos'),
          children: [
            ListTile(
              title: Text(_eventos[_selectedDay!]!.titulo),
              subtitle: Text(_eventos[_selectedDay!]!.mensaje),
              tileColor: _eventos[_selectedDay!]!.color.withOpacity(0.3),
            ),
            ElevatedButton(
              onPressed: () => confirmarAsistencia(context),
              child: Text('Confirmar asistencia'),
            ),
          ],
        ),
      );
    }
  }
}

class ProximoEvento extends StatelessWidget {
  final MapEntry<DateTime, Evento>? proximoEvento;

  ProximoEvento({this.proximoEvento});

  @override
  Widget build(BuildContext context) {
    if (proximoEvento != null) {
      return Card(
        color: proximoEvento!.value.color.withOpacity(0.3),
        child: ListTile(
          title: Text(proximoEvento!.value.titulo),
          subtitle: Text(
              'Próximo evento: ${DateFormat('dd/MM/yyyy').format(proximoEvento!.key)}'),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}

class Evento {
  final String titulo;
  final String mensaje;
  final Color color;
  final List<String>? personasConfirmadas;
  final DateTime fecha; // Variable de fecha

  Evento(this.titulo, this.mensaje, this.color, this.fecha, {this.personasConfirmadas});

  Evento copyWith({List<String>? personasConfirmadas}) {
    return Evento(
      titulo,
      mensaje,
      color,
      fecha,
      personasConfirmadas: personasConfirmadas ?? this.personasConfirmadas,
    );
  }
}
