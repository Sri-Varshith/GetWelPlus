import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }
}

class ChatService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'stepfun/step-3.5-flash:free';
  
  final List<ChatMessage> _conversationHistory = [];

  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// System prompt for the mental health assistant
  static const String _systemPrompt = '''
You are a compassionate and supportive mental health assistant for the GetWel+ app. 
Your role is to:
- Listen empathetically to users' concerns
- Provide supportive and non-judgmental responses
- Offer helpful coping strategies and mindfulness techniques
- Encourage professional help when appropriate
- Never provide medical diagnoses or replace professional mental health care

Always maintain a warm, understanding tone and prioritize the user's emotional well-being.
If someone expresses serious distress or mentions self-harm, gently encourage them to reach out to a mental health professional or crisis helpline.
Keep the response to around 70-80 words only.
''';

  ChatService() {
    // Initialize with system prompt
    _conversationHistory.add(ChatMessage(
      role: 'system',
      content: _systemPrompt,
    ));
  }

  /// Send a message and get AI response
  Future<String> sendMessage(String userMessage) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenRouter API key not configured. Please add OPENROUTER_API_KEY to your .env file.');
    }

    // Add user message to history
    _conversationHistory.add(ChatMessage(
      role: 'user',
      content: userMessage,
    ));

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://getwelplus.app', // Optional: for OpenRouter analytics
          'X-Title': 'GetWel+ Mental Health App', // Optional: for OpenRouter analytics
        },
        body: jsonEncode({
          'model': _model,
          'messages': _conversationHistory.map((m) => m.toJson()).toList(),
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = data['choices'][0]['message']['content'] as String;
        
        // Add assistant response to history
        _conversationHistory.add(ChatMessage(
          role: 'assistant',
          content: assistantMessage,
        ));

        return assistantMessage;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('API Error: ${errorBody['error']?['message'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      // Remove the user message if request failed
      _conversationHistory.removeLast();
      rethrow;
    }
  }

  /// Clear conversation history (keeps system prompt)
  void clearHistory() {
    _conversationHistory.clear();
    _conversationHistory.add(ChatMessage(
      role: 'system',
      content: _systemPrompt,
    ));
  }

  /// Get conversation history without system prompt
  List<ChatMessage> get history => 
      _conversationHistory.where((m) => m.role != 'system').toList();
}
