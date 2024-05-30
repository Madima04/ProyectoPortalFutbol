import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';

class PadresHomePage extends StatefulWidget {
  final int groupId;
  final int userId;
  final Future<String> nombreEntrenador;
  final Future<String> nombreEquipo;

  PadresHomePage(
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

class _HomePageState extends State<PadresHomePage> {
  late Future<List<Map<String, dynamic>>> _forumPostsFuture;
  late int groupId;
  late int userId;
  late Future<String> nombreEntrenador;
  late Future<String> nombreEquipo;
  bool _showLikeAnimation = false; // Variable para controlar la animación de like

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

  Future<List<Map<String, dynamic>>> fetchForumPosts() async {
    final response = await Supabase.instance.client
        .from('Mensajes')
        .select('id, Nombre, Titulo, Mensaje')
        .eq('idGrupo', widget.groupId)
        .execute();

    if (response.error != null) {
      print('Error al cargar los mensajes del foro: ${response.error}');
      return [];
    }

    final List<Map<String, dynamic>> posts = [];
    if (response.data != null) {
      for (var item in response.data as List) {
        posts.add({
          'id': item['id'],
          'nombre': item['Nombre'],
          'titulo': item['Titulo'],
          'mensaje': item['Mensaje'],
        });
      }
    }
    print('Mensajes del foro: $posts');
    return posts;
  }

  Future<void> _refreshForumPosts() async {
    setState(() {
      _forumPostsFuture = fetchForumPosts();
    });
  }

  Future<void> saveReaction(String reactionValue, post) async {
    List listReactions = [];
    final response1 = await Supabase.instance.client
        .from('Mensajes')
        .select('reacciones')
        .eq('id', post)
        .execute();

    if (response1.error != null) {
      print('Error al cargar las reacciones: ${response1.error}');
      return;
    }

    if (response1.data[0]['reacciones'] != null) {
      if (response1.data[0]['reacciones'].length > 0) {
        listReactions = response1.data[0]['reacciones'];
      }
    }
    listReactions.add(reactionValue);

    final response2 = await Supabase.instance.client
        .from('Mensajes')
        .update({'reacciones': listReactions})
        .eq('id', post)
        .execute();

    if (response2.error != null) {
      print('Error al guardar la reacción: ${response2.error}');
    } else {
      print('Reacción guardada exitosamente');
      // Mostrar la animación de "like"
      setState(() {
        _showLikeAnimation = true;
      });
      // Después de un tiempo, ocultar la animación
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _showLikeAnimation = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                  child: RefreshIndicator(
                    onRefresh: _refreshForumPosts,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: 20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _forumPostsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text(
                                'Error al cargar los mensajes del foro');
                          } else {
                            final forumPosts = snapshot.data ?? [];
                            return ListView.builder(
                              itemCount: forumPosts.length,
                              itemBuilder: (BuildContext context, int index) {
                                final post = forumPosts[index];
                                return ListTile(
                                  title: Text(post['titulo'] ?? 'Sin título'),
                                  subtitle:
                                  Text(post['mensaje'] ?? 'Sin mensaje'),
                                  trailing: ReactionButton(
                                    itemSize: Size(40, 40),
                                    onReactionChanged: (reaction) {
                                      if (reaction != null) {
                                        saveReaction(reaction.value ?? "", post['id']);
                                      }
                                    },
                                    reactions: <Reaction>[
                                      Reaction(
                                        icon: Icon(Icons.thumb_up),
                                        previewIcon: Icon(Icons.thumb_up),
                                        value: "Like",
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 500),
              opacity: _showLikeAnimation ? 1.0 : 0.0,
              child: Icon(
                Icons.thumb_up,
                color: Colors.blue,
                size: 100, // Ajusta el tamaño según tu preferencia
              ),
            ),
          ),
        ],
      ),
    );
  }
}
