import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:GolNet/ventanas/BottomNavigationBarWindow.dart';
import 'package:GolNet/ventanas/PadresBottomNavigationBarWindow.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://swncbshilpsblejrhfog.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN3bmNic2hpbHBzYmxlanJoZm9nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDcxMjk0NjgsImV4cCI6MjAyMjcwNTQ2OH0.3RgdUaqYDK-o1ik95qOT68Wusg1MfxnYMB4ah8PgcVs',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GolNet',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Image.asset(
            'assets/imagenFondoInicio.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          '¡Bienvenido a la aplicación del foro de fútbol! Aquí podrás mejorar la conexión entre el entrenador y los padres de los jugadores para facilitar la comunicación.',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 40),
                            textStyle: TextStyle(fontSize: 20),
                            elevation: 5,
                          ),
                          child: Text('Iniciar sesión'),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegisterPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 15, horizontal: 40),
                            textStyle: TextStyle(fontSize: 20),
                            elevation: 5,
                          ),
                          child: Text('Registrarse'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<String> getNombreEntrenador(int id) async {
    final response = await Supabase.instance.client
        .from('Usuario')
        .select('Nombre')
        .eq('id', id)
        .execute();
    return response.data![0]['Nombre'] as String;
  }

  Future<bool> esEntrenador(int id) async {
    final response = await Supabase.instance.client
        .from('Usuario')
        .select('esEntrenador')
        .eq('id', id)
        .execute();
    print(response.data![0]['esEntrenador'] as bool);
    return response.data![0]['esEntrenador'] as bool;
  }

  Future<String> getNombreEquipo(int id) async {
    final response = await Supabase.instance.client
        .from('Grupo')
        .select('Nombre')
        .eq('id', id)
        .execute();
    return response.data![0]['Nombre'] as String;
  }

  void _signIn(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return;
    }

    final response = await Supabase.instance.client.auth.signIn(
      email: email,
      password: password,
    );

    if (response.error != null) {
      String errorMessage = '';
      switch (response.error!.message) {
        case 'Invalid credentials.':
          errorMessage =
              'Las credenciales proporcionadas son incorrectas. Por favor, inténtalo de nuevo.';
          break;
        case 'User not found.':
          errorMessage =
              'No se encontró ningún usuario con este correo electrónico.';
          break;
        default:
          errorMessage = 'Error al iniciar sesión: ${response.error!.message}';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else {
      final response = await Supabase.instance.client
          .from('Usuario')
          .select('id, idGrupo')
          .eq('Correo', email)
          .execute();
      final userId = response.data![0]['id'] as int;
      final groupId = response.data![0]['idGrupo'] as int;
      esEntrenador(userId).then((value) {
        if (value == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => BottomNavigationBarWindow(
                    groupId,
                    userId,
                    getNombreEntrenador(userId),
                    getNombreEquipo(groupId))),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => PadresBottomNavigationBarWindow(
                    groupId,
                    userId,
                    getNombreEntrenador(userId),
                    getNombreEquipo(groupId))),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MyHomePage()));
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.lightGreenAccent,
                    Colors.green,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: 50, // Mueve la flecha un poco hacia abajo
              left: 10,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon:
                      Icon(Icons.arrow_back_ios, color: Colors.black, size: 30),
                  onPressed: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => MyHomePage()));
                  },
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(top: 50),
                      alignment: Alignment.center,
                      child: Text(
                        'GolNet',
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
                      ),
                    ),
                    SizedBox(height: 20),
                    Image.asset(
                      'assets/logo.png',
                      height: 150,
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                            obscureText: true,
                          ),
                          SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: () => _signIn(context),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.green,
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.green),
                              ),
                            ),
                            child: Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
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

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, 4),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _userType =
      'Entrenador'; // Variable para almacenar el tipo de usuario seleccionado

  void _register(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final isCoach = _userType == 'Entrenador' ? true : false;

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos.')),
      );
      return;
    }

    final response =
        await Supabase.instance.client.auth.signUp(email, password);

    if (response.error == null) {
      final user = response.data;

      final insertResponse =
          await Supabase.instance.client.from('Usuario').insert([
        {'Nombre': name, 'esEntrenador': isCoach, 'Correo': email}
      ]).execute();

      if (insertResponse.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso.')),
        );

        final userId = insertResponse.data![0]['id'] as int;

        if (isCoach == true) {
          showDialog(
            context: context,
            builder: (context) {
              return CreateTeamDialog(userId: userId);
            },
          );
        } else if (isCoach == false) {
          showDialog(
            context: context,
            builder: (context) {
              return CreateParentDialog(userId: userId);
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar usuario.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.error!.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MyHomePage()));
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.lightGreenAccent, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: 50, // Mueve la flecha un poco hacia abajo
              left: 10,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 30),
                onPressed: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => MyHomePage()));
                },
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 20),
                    Text(
                      'GolNet',
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
                    ),
                    SizedBox(height: 20),
                    Image.asset(
                      'assets/logo.png',
                      height: 150,
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                            obscureText: true,
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _userType = 'Entrenador';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: _userType == 'Entrenador'
                                      ? Colors.white
                                      : Colors.black,
                                  backgroundColor: _userType == 'Entrenador'
                                      ? Colors.green
                                      : Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.green),
                                  ),
                                ),
                                child: Text('Entrenador'),
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _userType = 'Padre o Madre';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: _userType == 'Padre o Madre'
                                      ? Colors.white
                                      : Colors.black,
                                  backgroundColor: _userType == 'Padre o Madre'
                                      ? Colors.green
                                      : Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: Colors.green),
                                  ),
                                ),
                                child: Text('Padre o Madre'),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _register(context),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.green,
                              backgroundColor: Colors.white,
                              // Color del texto del botón
                              padding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 40),
                              // Padding del botón
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                // Bordes redondeados
                                side: BorderSide(
                                    color: Colors.green), // Borde del botón
                              ),
                            ),
                            child: Text(
                              'Registrarse',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

class CreateTeamDialog extends StatefulWidget {
  final int userId;

  const CreateTeamDialog({required this.userId});

  @override
  _CreateTeamDialogState createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends State<CreateTeamDialog> {
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();

  Future<String> getNombreEntrenador(int id) async {
    final response = await Supabase.instance.client
        .from('Usuario')
        .select('Nombre')
        .eq('id', id)
        .execute();
    return response.data![0]['Nombre'] as String;
  }

  Future<bool> esEntrenador(int id) async {
    final response = await Supabase.instance.client
        .from('Usuario')
        .select('esEntrenador')
        .eq('id', id)
        .execute();
    print(response.data![0]['esEntrenador'] as bool);
    return response.data![0]['esEntrenador'] as bool;
  }

  Future<String> getNombreEquipo(int id) async {
    final response = await Supabase.instance.client
        .from('Grupo')
        .select('Nombre')
        .eq('id', id)
        .execute();
    return response.data![0]['Nombre'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Crear Equipo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _teamNameController,
              decoration: InputDecoration(labelText: 'Nombre del Equipo'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _participantsController,
              maxLines: null, // Para permitir múltiples líneas de entrada
              keyboardType: TextInputType.multiline, // Teclado multilinea
              decoration: InputDecoration(labelText: 'Lista de Participantes'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cerrar el diálogo
          },
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Obtener los datos del equipo y los participantes
            final teamName = _teamNameController.text.trim();
            final participants =
                _participantsController.text.trim().split('\n');

            // Insertar el nuevo equipo en la base de datos
            final insertResponse =
                await Supabase.instance.client.from('Grupo').insert([
              {'Nombre': teamName, 'NombreJugadores': participants}
            ]).execute();

            if (insertResponse.error == null) {
              // Obtener el ID del grupo recién creado
              final groupId = insertResponse.data![0]['id'] as int;

              // Actualizar el usuario con el ID del grupo
              final updateResponse = await Supabase.instance.client
                  .from('Usuario')
                  .update({
                    'idGrupo': groupId,
                  })
                  .eq('id', widget.userId)
                  .execute();

              if (updateResponse.error == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Equipo creado exitosamente.')),
                );

                esEntrenador(widget.userId).then((value) {
                  if (value == true) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BottomNavigationBarWindow(
                              groupId,
                              widget.userId,
                              getNombreEntrenador(widget.userId),
                              getNombreEquipo(groupId))),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PadresBottomNavigationBarWindow(
                              groupId,
                              widget.userId,
                              getNombreEntrenador(widget.userId),
                              getNombreEquipo(groupId))),
                    );
                  }
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Error al actualizar el usuario: ${updateResponse.error!.message}')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Error al crear el equipo: ${insertResponse.error!.message}')),
              );
            }
          },
          child: Text('Crear Equipo'),
        ),
      ],
    );
  }
}

class CreateParentDialog extends StatefulWidget {
  final int userId;

  const CreateParentDialog({required this.userId});

  @override
  _CreateParentDialogState createState() => _CreateParentDialogState();
}

class _CreateParentDialogState extends State<CreateParentDialog> {
  final TextEditingController _teamNameController = TextEditingController();
  String _selectedTeam = '';
  List<String> _players = [];

  Future<String> getNombreEntrenador(int id) async {
    final response = await Supabase.instance.client
        .from('Usuario')
        .select('Nombre')
        .eq('id', id)
        .execute();
    return response.data![0]['Nombre'] as String;
  }

  Future<String> getNombreEquipo(int id) async {
    final response = await Supabase.instance.client
        .from('Grupo')
        .select('Nombre')
        .eq('id', id)
        .execute();
    return response.data![0]['Nombre'] as String;
  }

  Future<bool> esEntrenador(int id) async {
    final response = await Supabase.instance.client
        .from('Usuario')
        .select('esEntrenador')
        .eq('id', id)
        .execute();
    return response.data![0]['esEntrenador'] as bool;
  }

  Future<List<String>> getPlayersByTeamName(String teamName) async {
    try {
      final response = await Supabase.instance.client
          .from('Grupo')
          .select('NombreJugadores')
          .eq('Nombre', teamName)
          .execute();

      if (response.error != null) {
        throw Exception('Error al obtener los jugadores: ${response.error}');
      }

      final players = response.data?[0]['NombreJugadores'] as List?;
      return players?.cast<String>() ?? [];
    } catch (error) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Crear Equipo y Agregar Hijo/a'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _teamNameController,
              onChanged: (value) {
                setState(() {
                  _selectedTeam = value;
                  _players = []; // Clear players on team change
                });
              },
              decoration: InputDecoration(labelText: 'Nombre del Equipo'),
            ),
            SizedBox(height: 10),
            // Use FutureBuilder to ensure data is available
            _selectedTeam.isNotEmpty
                ? FutureBuilder<List<String>>(
                    future: getPlayersByTeamName(_selectedTeam),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasData) {
                        _players = snapshot.data!;
                        return buildDropdown(context,
                            _players); // Call separate widget for DropdownButton
                      } else {
                        return Text(
                            'No hay jugadores disponibles para este equipo.');
                      }
                    },
                  )
                : SizedBox(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Cerrar el diálogo
          },
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final teamName = _teamNameController.text.trim();
            final response = await Supabase.instance.client
                .from('Grupo')
                .select('id')
                .eq('Nombre', teamName)
                .execute();
            int groupId = response.data![0]['id'] as int;
            Supabase.instance.client
                .from('Usuario')
                .update({
                  'idGrupo': groupId,
                })
                .eq('id', widget.userId)
                .execute();
            if (teamName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Por favor, ingresa el nombre del equipo.'),
                ),
              );
              return;
            }
            if (_selectedTeam.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Por favor, selecciona un jugador.'),
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Equipo creado exitosamente.')),
            );
            if (esEntrenador(widget.userId) == true) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => BottomNavigationBarWindow(
                        groupId,
                        widget.userId,
                        getNombreEntrenador(widget.userId),
                        getNombreEquipo(groupId))),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => PadresBottomNavigationBarWindow(
                        groupId,
                        widget.userId,
                        getNombreEntrenador(widget.userId),
                        getNombreEquipo(groupId))),
              );
            }
          },
          child: Text('Crear Equipo y Agregar Hijo/a'),
        ),
      ],
    );
  }

  Widget buildDropdown(BuildContext context, List<String> players) {
    return DropdownButton<String>(
      value: players.isNotEmpty ? players[0] : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedTeam = newValue ?? '';
          if (newValue != null) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Usuario seleccionado'),
                  content: Text(newValue),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        Supabase.instance.client
                            .from('Usuario')
                            .update({
                              'Hijo': newValue,
                            })
                            .eq('id', widget.userId)
                            .execute();
                        Navigator.of(context).pop();
                      },
                      child: Text('Cerrar'),
                    ),
                  ],
                );
              },
            );
          }
        });
      },
      items: players.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
