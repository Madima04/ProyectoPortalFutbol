import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  final int groupId;
  final int userId;
  final Future<String> nombreEntrenador;
  final Future<String> nombreEquipo;

  HomePage(
      this.groupId,
      this.userId,
      this.nombreEntrenador,
      this.nombreEquipo, {
        Key? key,
      }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState(
    groupId,
    userId,
    nombreEntrenador,
    nombreEquipo,
  );
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _forumPostsFuture;
  late int groupId;
  late int userId;
  late Future<String> nombreEntrenador;
  late Future<String> nombreEquipo;
  List<String> playersList = [];
  List<Map<String, String>> playersData = [];

  _HomePageState(
      this.groupId,
      this.userId,
      this.nombreEntrenador,
      this.nombreEquipo,
      );

  @override
  void initState() {
    super.initState();
    _forumPostsFuture = fetchForumPosts();
  }

  Future<String> _fetchUserName() async {
    final response = await Supabase.instance.client
        .from('Usuario')
        .select('Nombre')
        .eq('id', widget.userId)
        .execute();

    if (response.error != null) {
      print('Error al cargar el nombre del usuario: ${response.error}');
      return 'Error';
    }

    print('Nombre del usuario: ${response.data[0]['Nombre']}');
    return response.data[0]['Nombre'] as String;
  }

  Future<void> editPlayerInfo(String playerName) async {
    TextEditingController infoController = TextEditingController();
    String initialInfo = '';

    // Obtener la información actual del jugador
    final playersInfoResponse = await fetchPlayersInfo();
    if (playersInfoResponse.isNotEmpty) {
      final playerData = playersInfoResponse.firstWhere(
            (player) => player['name'] == playerName,
        orElse: () => {},
      );
      initialInfo = playerData['info'] ?? '';
    }

    // Mostrar un diálogo para editar la información
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Información de $playerName'),
        content: TextField(
          controller: infoController..text = initialInfo,
          decoration: InputDecoration(labelText: 'Nueva información'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newInfo = infoController.text;

              // Actualizar la información del jugador en la lista de datos de jugadores
              final playerIndex = playersData.indexWhere(
                    (player) => player['name'] == playerName,
              );
              if (playerIndex != -1) {
                playersData[playerIndex]['info'] = newInfo;
              }

              if (playersInfoResponse.isNotEmpty) {
                final playerData = playersInfoResponse.firstWhere(
                      (player) => player['name'] == playerName,
                  orElse: () => {},
                );
                final currentInfJugador =
                    (playerData['infJugador'] as Map<dynamic, dynamic>?) ?? {};

                // Actualizar o añadir la información del jugador en el mapa "infJugador"
                currentInfJugador[playerName] = newInfo;

                final response = await Supabase.instance.client
                    .from('Grupo')
                    .update({'infJugador': currentInfJugador})
                    .eq('id', groupId)
                    .execute();

                if (response.error != null) {
                  print(
                      'Error al actualizar la información del jugador: ${response.error}');
                  // Manejar el error según sea necesario
                } else {
                  print('Información del jugador actualizada exitosamente');
                }
              } else {
                print('La consulta no devolvió resultados');
              }

              Navigator.pop(context); // Cerrar el diálogo
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, String>>> fetchPlayersInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('Grupo')
          .select('NombreJugadores, infJugador')
          .eq('id', groupId)
          .execute();

      if (response.error != null) {
        print(
            'Error al cargar la información de los jugadores: ${response.error}');
        return [];
      }

      final List<String>? playerNames =
      response.data?[0]['NombreJugadores']?.cast<String>();
      final List<String>? playerInfo =
      response.data?[0]['infJugador']?.cast<String>();

      if (playerNames == null) {
        print(
            'No se encontró información de los nombres de los jugadores para el grupo con ID: $groupId');
        return [];
      }

      // Combinar los nombres de los jugadores y su información en una lista de mapas
      final List<Map<String, String>> playersData = [];
      for (int i = 0; i < playerNames.length; i++) {
        final playerName = playerNames[i];
        final playerInfoText =
        playerInfo != null && i < playerInfo.length ? playerInfo[i] : '';
        playersData.add({'name': playerName, 'info': playerInfoText});
      }

      return playersData;
    } catch (error) {
      print('Error al cargar los jugadores del equipo: $error');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchForumPosts() async {
    final response = await Supabase.instance.client
        .from('Mensajes')
        .select('id, Nombre, Titulo, Mensaje, reacciones')
        .eq('idGrupo', widget.groupId)
        .execute();

    if (response.error != null) {
      print('Error al cargar los mensajes del foro: ${response.error}');
      return [];
    }

    // Mapear los datos de la respuesta a una lista de Map<String, dynamic>
    final List<Map<String, dynamic>> posts = [];
    if (response.data != null) {
      for (var item in response.data as List) {
        posts.add({
          'id': item['id'],
          'nombre': item['Nombre'],
          'titulo': item['Titulo'],
          'mensaje': item['Mensaje'],
          'reacciones': item['reacciones'] ?? [],
          // Obtener las reacciones o una lista vacía si no hay
        });
      }
    }
    print('Mensajes del foro: $posts');
    return posts;
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

  Future<void> createMessage(String title, String message) async {
    final String userName =
    await _fetchUserName(); // Esperar la obtención del nombre de usuario

    final response = await Supabase.instance.client.from('Mensajes').insert([
      {
        'Nombre': userName, // Usar el nombre de usuario obtenido
        'Titulo': title,
        'Mensaje': message,
        'idGrupo': widget.groupId
      }
    ]).execute();

    if (response.error != null) {
      print('Error al crear el mensaje: ${response.error}');
    } else {
      setState(() {
        _forumPostsFuture = fetchForumPosts();
      });
    }
  }

  Future<void> deleteMessage(int messageId) async {
    final response = await Supabase.instance.client
        .from('Mensajes')
        .delete()
        .eq('id', messageId)
        .execute();

    if (response.error != null) {
      print('Error al eliminar el mensaje: ${response.error}');
    } else {
      setState(() {
        _forumPostsFuture = fetchForumPosts();
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
            FutureBuilder<String>(
              future: nombreEquipo,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Foro del Grupo');
                } else if (snapshot.hasError) {
                  return Text('Error al obtener el nombre del equipo');
                } else {
                  final nombreEquipo = snapshot.data ?? 'Nombre del Equipo';
                  return Text(
                    'Foro del Grupo $nombreEquipo',
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
                  );
                }
              },
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
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _forumPostsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Error al cargar los mensajes del foro');
                          } else {
                            final forumPosts = snapshot.data ?? [];
                            return ListView.builder(
                              itemCount: forumPosts.length,
                              itemBuilder: (BuildContext context, int index) {
                                final post = forumPosts[index];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              post['titulo'] ?? 'Sin título',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.green),
                                              onPressed: () {
                                                deleteMessage(post['id']);
                                              },
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          post['mensaje'] ?? 'Sin mensaje',
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Text(
                                              '${post['reacciones'].length} Likes',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            // Aquí puedes agregar más iconos o widgets para otras reacciones
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => CreateMessageDialog(
                                (title, message) {
                              createMessage(title, message);
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Nuevo Mensaje',
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

class CreateMessageDialog extends StatelessWidget {
  final Function(String, String) onCreate;

  CreateMessageDialog(this.onCreate);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuevo Mensaje'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Título'),
          ),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(labelText: 'Mensaje'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text;
            final message = _messageController.text;
            onCreate(title, message);
            Navigator.pop(context);
          },
          child: Text('Crear'),
        ),
      ],
    );
  }
}
