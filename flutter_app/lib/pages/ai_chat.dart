import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/chat_bubble.dart';
import 'package:flutter_app/services/chat_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add initial greeting from AI
    _messages.add({
      "text": "Hello! I'm your mental health companion. How are you feeling today? I'm here to listen and support you. 💚",
      "isUser": false,
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        "text": text,
        "isUser": true,
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(text);
      
      if (mounted) {
        setState(() {
          _messages.add({
            "text": response,
            "isUser": false,
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            "text": "I'm sorry, I couldn't process your message. Please check your internet connection and try again.",
            "isUser": false,
          });
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat"),
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear chat',
            onPressed: () {
              setState(() {
                _chatService.clearHistory();
                _messages.clear();
                _messages.add({
                  "text": "Hello! I'm your mental health companion. How are you feeling today? I'm here to listen and support you. 💚",
                  "isUser": false,
                });
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            /// Messages Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the end
                    if (index == _messages.length && _isLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Thinking...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final message = _messages[index];

                    return ChatBubble(
                      message: message["text"],
                      isUser: message["isUser"],
                    );
                  },
                ),
              ),
            ),

            /// Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

              child: Row(
                children: [

                  /// Real Text Field
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.black),
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        hintStyle: TextStyle(color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// Send Button
                  Material(
                    color: _isLoading ? Colors.grey : Colors.green,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                      ),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
