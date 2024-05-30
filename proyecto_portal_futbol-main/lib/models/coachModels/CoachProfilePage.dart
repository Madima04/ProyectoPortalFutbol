import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  final int groupId;
  final Future<String> nombreEntrenador;
  final Future<String> nombreEquipo;

  ProfilePage(
      this.userId,
      this.groupId,
      this.nombreEquipo,
      this.nombreEntrenador, {
        Key? key,
      }) : super(key: key);


  @override
  _ProfilePageState createState() => _ProfilePageState(
    userId,
    groupId,
    nombreEquipo,
    nombreEntrenador,
  );
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<String> nombreEquipo;
  late Future<String> nombreEntrenador;
  late int userId;
  late int groupId;

  _ProfilePageState(
      this.userId,
      this.groupId,
      this.nombreEquipo,
      this.nombreEntrenador,
      );

  @override
  void initState() {
    super.initState();
    nombreEquipo = widget.nombreEquipo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.green,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Text(
                'Perfil',
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
                  child: FutureBuilder<List<String>>(
                    future: Future.wait([nombreEntrenador, nombreEquipo]),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<String>> snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else {
                        if (snapshot.hasError)
                          return Text('Error: ${snapshot.error}');
                        else if (snapshot.hasData && snapshot.data!.length >= 2)
                          return Column(
                            children: <Widget>[
                              ListTile(
                                leading: Icon(Icons.group),
                                title: Text(
                                  'Nombre del equipo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  snapshot.data![0],
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          );
                        else
                          return Text('Los datos aún no están disponibles');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}