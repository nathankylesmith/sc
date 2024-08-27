import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'pages/home_page.dart';
import 'pages/add_context_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scribble App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<DatabaseService>(
        future: DatabaseService.create(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final databaseService = snapshot.data!;
            return Navigator(
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/':
                    return MaterialPageRoute(builder: (_) => HomePage(databaseService: databaseService));
                  case '/add_context':
                    return MaterialPageRoute(builder: (_) => AddContextPage(databaseService: databaseService));
                  default:
                    return MaterialPageRoute(builder: (_) => HomePage(databaseService: databaseService));
                }
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}