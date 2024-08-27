import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/context_item.dart';

class ViewContextPage extends StatelessWidget {
  final DatabaseService databaseService;

  const ViewContextPage({Key? key, required this.databaseService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Context'),
      ),
      body: FutureBuilder<List<ContextItem>>(
        future: databaseService.getContextItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No context items found.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return ListTile(
                  title: Text(item.content.length > 20
                      ? '${item.content.substring(0, 20)}...'
                      : item.content),
                  subtitle: Text(item.createdAt.toString()),
                );
              },
            );
          }
        },
      ),
    );
  }
}