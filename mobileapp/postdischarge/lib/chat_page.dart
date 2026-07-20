import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String myId;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.myId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  List messages = [];
  bool isLoading = true;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final Color primaryGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      SharedPreferences sp = await SharedPreferences.getInstance();
      String? baseUrl = sp.getString("url");

      final response = await http.post(
        Uri.parse("$baseUrl/users_view_chat/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": widget.myId,
          "receiver_id": widget.receiverId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        setState(() {
          messages = data["data"];
          isLoading = false;
        });

        await Future.delayed(const Duration(milliseconds: 200));
        scrollToBottom();
      }
    } catch (e) {
      debugPrint("Chat fetch error: $e");
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    try {
      SharedPreferences sp = await SharedPreferences.getInstance();
      String? baseUrl = sp.getString("url");

      await http.post(
        Uri.parse("$baseUrl/users_send_chat/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": widget.myId,
          "receiver_id": widget.receiverId,
          "message": messageController.text.trim(),
        }),
      );

      messageController.clear();
      fetchMessages();
    } catch (e) {
      debugPrint("Send error: $e");
    }
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: primaryGreen,
      ),
      body: Column(
        children: [

          /// Messages Area
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: fetchMessages,
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {

                  var chat = messages[index];
                  bool isMe =
                      chat["sender_id"].toString() == widget.myId;

                  return Align(
                    alignment:
                    isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [

                        Container(
                          margin:
                          const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: const BoxConstraints(
                              maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isMe
                                ? primaryGreen
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            chat["message"],
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),

                        Padding(
                          padding:
                          const EdgeInsets.only(bottom: 6),
                          child: Text(
                            chat["date_time"] ?? "",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          /// Message Input Area
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: Row(
                children: [

                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Type message...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  CircleAvatar(
                    backgroundColor: primaryGreen,
                    child: IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white),
                      onPressed: sendMessage,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}