import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scribble_app/services/database_service.dart';
import 'package:scribble_app/services/llama_service.dart';
import 'package:scribble_app/pages/add_context_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final databaseService = DatabaseService();
  await databaseService.initialize();

  runApp(MyApp(databaseService: databaseService));
}

class MyApp extends StatelessWidget {
  final DatabaseService databaseService;

  const MyApp({Key? key, required this.databaseService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building MyApp');
    return MaterialApp(
      title: 'Scribble App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(databaseService: databaseService),
    );
  }
}

class HomePage extends StatefulWidget {
  final DatabaseService databaseService;

  const HomePage({Key? key, required this.databaseService}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LlamaService _llamaService = LlamaService(
    apiUrl: 'http://localhost:1234/v1/chat/completions',
  );

  List<String> _completions = [];
  int _currentCompletionIndex = 0;
  String _inputText = '';
  bool _isCompletionActive = false;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _registerKeyBindings();
    } else {
      _unregisterKeyBindings();
    }
  }

  void _registerKeyBindings() {
    RawKeyboard.instance.addListener(_handleKeyPress);
  }

  void _unregisterKeyBindings() {
    RawKeyboard.instance.removeListener(_handleKeyPress);
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyI) {
        _cycleCompletions();
      } else if (event.logicalKey == LogicalKeyboardKey.tab) {
        _selectCompletion();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _removeCompletion();
      } else if (event.isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyN) {
        _resumeCompletions();
      }
    }
  }

  void _cycleCompletions() {
    if (_completions.isNotEmpty) {
      setState(() {
        _currentCompletionIndex = (_currentCompletionIndex + 1) % _completions.length;
        _updateTextFieldWithCompletion();
      });
    }
  }

  void _selectCompletion() {
    if (_completions.isNotEmpty) {
      setState(() {
        _inputText = _controller.text;
        _completions.clear();
        _currentCompletionIndex = 0;
        _isCompletionActive = false;
      });
    }
  }

  void _removeCompletion() {
    setState(() {
      _controller.text = _inputText;
      _completions.clear();
      _currentCompletionIndex = 0;
      _isCompletionActive = false;
    });
  }

  void _resumeCompletions() {
    if (!_isCompletionActive) {
      _getCompletions();
    }
  }

  void _updateTextFieldWithCompletion() {
    if (_completions.isNotEmpty) {
      _controller.text = _inputText + _completions[_currentCompletionIndex];
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  Future<void> _getCompletions() async {
    if (_inputText.isEmpty) return;

    try {
      List<double> embedding = convertToEmbedding(_inputText); // Convert the string to a List<double>
      final context = await widget.databaseService.getRelatedContext(embedding); // Use the converted List<double>
      final completion = await _llamaService.getCompletion(_inputText, context);
      if (completion != null) {
        setState(() {
          _completions = [completion]; // For simplicity, we're using a single completion
          _currentCompletionIndex = 0;
          _isCompletionActive = true;
          _updateTextFieldWithCompletion();
        });
      }
    } catch (e) {
      print('Error getting completions: $e');
    }
  }

  List<double> convertToEmbedding(String input) {
    // Implement your conversion logic here
    // This is just a placeholder example
    return input.split(' ').map((e) => double.tryParse(e) ?? 0.0).toList();
  }

  @override
  Widget build(BuildContext context) {
    print('Building HomePage');
    return Scaffold(
      appBar: AppBar(
        title: Text('Scribble App'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddContextPage(
                    databaseService: widget.databaseService,
                    llamaService: _llamaService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: 'Enter text',
                border: OutlineInputBorder(),
              ),
              onChanged: (text) {
                setState(() {
                  _inputText = text;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCompletions,
              child: Text('Get Completions'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _unregisterKeyBindings();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}