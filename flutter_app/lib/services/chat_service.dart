import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// simple model to hold chat messages
class ChatMessage {
  final String role; // either 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String,
        content: json['content'] as String,
      );
}

class ChatService {
  // openrouter endpoint
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const _model = 'stepfun/step-3.5-flash:free'; // free tier model

  final List<ChatMessage> _conversationHistory = [];
  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  // this sets the personality for our AI
  static const _systemPrompt = '''
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
    // kick things off with the system prompt
    _conversationHistory.add(ChatMessage(role: 'system', content: _systemPrompt));
  }

  // sends user msg to openrouter and returns AI response
  Future<String> sendMessage(String userMessage) async {
    if (_apiKey.isEmpty) {
      throw Exception('API key missing! Add OPENROUTER_API_KEY to your .env file.');
    }

    // add what user said
    _conversationHistory.add(ChatMessage(role: 'user', content: userMessage));

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://getwelplus.app',
          'X-Title': 'GetWel+',
        },
        body: jsonEncode({
          'model': _model,
          'messages': _conversationHistory.map((m) => m.toJson()).toList(),
          'temperature': 0.7, // bit of creativity but not too wild
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiReply = data['choices'][0]['message']['content'] as String;

        // save AI's response for context
        _conversationHistory.add(ChatMessage(role: 'assistant', content: aiReply));
        return aiReply;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error']?['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      // oops, remove user msg since we couldn't get a response
      _conversationHistory.removeLast();
      rethrow;
    }
  }

  // wipe the chat but keep system prompt
  void clearHistory() {
    _conversationHistory.clear();
    _conversationHistory.add(ChatMessage(role: 'system', content: _systemPrompt));
  }

  // get messages without the system prompt (for display)
  List<ChatMessage> get history =>
      _conversationHistory.where((m) => m.role != 'system').toList();
}
