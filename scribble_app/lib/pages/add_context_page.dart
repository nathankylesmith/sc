import 'package:flutter/material.dart';
import '../services/database_service.dart';

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
      // TODO: Implement adding context to the database
      // await widget.databaseService.addContextItem(content);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Context added successfully')),
      );
      _contentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Context'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addContext,
                child: Text('Add Context'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}