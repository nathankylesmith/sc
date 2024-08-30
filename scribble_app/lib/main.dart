import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'pages/home_page.dart';
import 'objectbox.g.dart'; // Make sure this import is present
import 'package:just_audio/just_audio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseService = await DatabaseService.create();
  runApp(MyApp(databaseService: databaseService));
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;

  const MyApp({Key? key, required this.databaseService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scribble App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(databaseService: databaseService),
    );
  }
}