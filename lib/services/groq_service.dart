import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GroqService {
  // API key is now managed through AppConfig
  final String apiKey;
  final String baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Constructor with optional API key parameter
  GroqService({String? apiKey}) : this.apiKey = apiKey ?? AppConfig().groqApiKey;
  
  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama3-8b-8192', // Using Llama 3 8B model
          'messages': [
            {
              'role': 'system',
              'content': 'You are Quike AI, a helpful and friendly assistant. Provide concise, accurate, and helpful responses.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        print('Error: ${response.statusCode}');
        print('Response: ${response.body}');
        return 'Sorry, I encountered an error while processing your request. Please try again later.';
      }
    } catch (e) {
      print('Exception: $e');
      return 'Sorry, I encountered an error while processing your request. Please try again later.';
    }
  }
}
