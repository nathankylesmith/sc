import 'dart:convert';
import 'package:http/http.dart' as http;

class LlamaService {
  final String apiUrl;

  LlamaService({required this.apiUrl});

  Future<List<double>> getEmbedding(String text) async {
    final response = await http.post(
      Uri.parse('$apiUrl/embeddings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'input': text}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return List<double>.from(jsonResponse['data'][0]['embedding']);
    } else {
      throw Exception('Failed to get embedding');
    }
  }

  Future<String?> getCompletion(String input, List<String> context) async {
    final response = await http.post(
      Uri.parse('$apiUrl/chat/completions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': 'Context: ${context.join("\n")}'},
          {'role': 'user', 'content': input},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get completion');
    }
  }
}