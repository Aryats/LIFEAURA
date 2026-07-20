import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'userhomescreen.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  // ================= LOAD CHAT HISTORY =================

  Future<void> _loadChatHistory() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String lid = sp.getString("lid") ?? "";
    String baseUrl = sp.getString("url") ?? "http://10.0.2.2:8000";

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/get_chat_history/?lid=$lid"),
      );

      final data = jsonDecode(res.body);

      if (data["status"] == "ok") {
        setState(() {
          _messages.clear();
          _messages.addAll(
              List<Map<String, String>>.from(data["messages"])
          );
        });

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("History load error: $e");
    }
  }

  // ================= SEND MESSAGE =================

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    SharedPreferences sp = await SharedPreferences.getInstance();
    String lid = sp.getString("lid") ?? "";
    String baseUrl = sp.getString("url") ?? "http://10.0.2.2:8000";

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/chatbot_response/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lid": lid,
          "message": text,
        }),
      );

      final data = jsonDecode(res.body);

      if (data["status"] == "ok") {
        setState(() {
          _messages.add({
            "role": "bot",
            "text": data["reply"] ?? "No response"
          });
        });
      } else {
        _addErrorMessage("Server error. Please try again.");
      }
    } catch (e) {
      _addErrorMessage("Connection failed. Check server.");
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _addErrorMessage(String message) {
    setState(() {
      _messages.add({
        "role": "bot",
        "text": message,
      });
    });
  }

  // ================= CLEAR CHAT =================

  Future<void> _clearChat() async {
    setState(() {
      _messages.clear();
    });
  }

  // ================= SCROLL HELPER =================

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= CHAT BUBBLE =================

  Widget _chatBubble(String text, bool isUser) {
    return Align(
      alignment:
      isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[600] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isUser)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
              )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Health Assistant"),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearChat,
          )
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const HomePage()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("AI is typing..."),
                  );
                }

                final msg = _messages[index];
                return _chatBubble(
                  msg["text"]!,
                  msg["role"] == "user",
                );
              },
            ),
          ),

          // ===== INPUT AREA =====

          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask about your health...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send,
                      color: Colors.green),
                  onPressed: () =>
                      _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}