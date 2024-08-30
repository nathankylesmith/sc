import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/context_item.dart';
import './view_context_page.dart'; // Add this import

class AddContextPage extends StatefulWidget {
  final DatabaseService databaseService;

  const AddContextPage({
    Key? key,
    required this.databaseService,
  }) : super(key: key);

  @override
  _AddContextPageState createState() => _AddContextPageState();
}

class _AddContextPageState extends State<AddContextPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  Future<void> _addContext() async {
    if (_formKey.currentState!.validate()) {
      final content = _contentController.text;
      final contextItem = ContextItem(
        filename: 'context_${DateTime.now().millisecondsSinceEpoch}.txt',
        content: content,
        createdAt: DateTime.now(),
      );
      await widget.databaseService.contextItemBox.put(contextItem);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Context added successfully')),
      );
      _contentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Context'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Context Content',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addContext,
                child: const Text('Add Context'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewContextPage(databaseService: widget.databaseService),
            ),
          );
        },
        icon: const Icon(Icons.visibility),
        label: const Text('Show Content'),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}