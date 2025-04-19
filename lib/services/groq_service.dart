import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class GroqService {
  // API key is now managed through AppConfig
  final String apiKey;
  final String baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Default system prompt
  final String defaultSystemPrompt = '''You are Quike AI, a helpful assistant embedded in a chat app.

Your main goal is to understand whether the user's latest message is:
1. A direct response to your previous question or suggestion.
2. A new, unrelated question or command.

Use this logic:
- If you recently asked a question, treat the user's input as a response **unless** it clearly starts a new topic (like "By the way," "Also," or asks something totally different).
- If you didn't ask a question before, treat the input as a new request.

Always keep the previous message context in mind.

Provide concise, accurate, and helpful responses. For direct questions, answer directly without asking for confirmation.''';
  
  // Constructor with optional API key parameter
  GroqService({String? apiKey}) : apiKey = apiKey ?? AppConfig().groqApiKey;
  
  /// Send a message with a custom system prompt
  Future<String> sendMessageWithSystemPrompt(String prompt, String systemPrompt) async {
    return _sendRequest(prompt, systemPrompt: systemPrompt);
  }
  
  /// Send a message with the default system prompt
  Future<String> generateResponse(String prompt) async {
    return _sendRequest(prompt, systemPrompt: defaultSystemPrompt);
  }
  
  /// Generate a response using conversation history (last 10 messages)
  Future<String> generateResponseWithHistory(String prompt, List<Map<String, String>> conversationHistory) async {
    return _sendRequestWithHistory(prompt, conversationHistory, systemPrompt: defaultSystemPrompt);
  }
  
  /// Internal method to send the API request
  Future<String> _sendRequest(String prompt, {required String systemPrompt}) async {
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
              'content': systemPrompt
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
  
  /// Internal method to send the API request with conversation history
  Future<String> _sendRequestWithHistory(String prompt, List<Map<String, String>> conversationHistory, {required String systemPrompt}) async {
    try {
      // Create messages array with system prompt and conversation history
      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': systemPrompt
        },
        ...conversationHistory,
        {
          'role': 'user',
          'content': prompt
        }
      ];
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama3-8b-8192', // Using Llama 3 8B model
          'messages': messages,
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
