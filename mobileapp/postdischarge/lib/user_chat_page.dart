import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserChatPage extends StatefulWidget {
  final int receiverId;
  final String receiverName;

  const UserChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {

  List messages = [];
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  Timer? timer;
  int? senderId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  // ================= INITIALIZE =================
  Future<void> initialize() async {
    SharedPreferences sh = await SharedPreferences.getInstance();

    String? lid = sh.getString("lid");
    if (lid == null || lid.isEmpty) return;

    senderId = int.tryParse(lid);
    if (senderId == null) return;

    await fetchMessages();

    timer = Timer.periodic(
      const Duration(seconds: 3),
          (t) => fetchMessages(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ================= FETCH CHAT =================
  Future<void> fetchMessages() async {

    if (senderId == null) return;

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String baseUrl = sh.getString("url") ?? "";

      final response = await http.post(
        Uri.parse("$baseUrl/user_chat_messages/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": senderId,
          "receiver_id": widget.receiverId,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok" && mounted) {
        setState(() {
          messages = data["messages"] ?? [];
          isLoading = false;
        });

        scrollToBottom();
      }

    } catch (e) {
      debugPrint("Fetch Chat Error: $e");
    }
  }

  // ================= SEND MESSAGE =================
  Future<void> sendMessage() async {

    if (senderId == null) return;
    if (messageController.text.trim().isEmpty) return;

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String baseUrl = sh.getString("url") ?? "";

      await http.post(
        Uri.parse("$baseUrl/user_send_message/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": senderId,
          "receiver_id": widget.receiverId,
          "message": messageController.text.trim(),
        }),
      );

      messageController.clear();
      fetchMessages();

    } catch (e) {
      debugPrint("Send Message Error: $e");
    }
  }

  // ================= AUTO SCROLL =================
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= FORMAT DATE ONLY =================
  String formatDateOnly(String? dateTimeString) {

    if (dateTimeString == null || dateTimeString.isEmpty) {
      return "";
    }

    try {
      DateTime dt = DateTime.parse(dateTimeString);
      return "${dt.day.toString().padLeft(2, '0')}-"
          "${dt.month.toString().padLeft(2, '0')}-"
          "${dt.year}";
    } catch (e) {
      return "";
    }
  }

  // ================= MESSAGE BUBBLE =================
  Widget buildMessageBubble(Map msg) {

    bool isMe =
        msg["sender_id"].toString() == senderId.toString();

    String formattedDate =
    formatDateOnly(msg["date_time"]);

    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFF2E7D32)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              msg["message"] ?? "",
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),

            if (formattedDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  formattedDate,   // ✅ DATE ONLY
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F7),

      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: const Color(0xFF1B5E20),
      ),

      body: Column(
        children: [

          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : messages.isEmpty
                ? const Center(
              child: Text("No messages yet"),
            )
                : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessageBubble(messages[index]);
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 3,
                  color: Colors.black12,
                )
              ],
            ),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(25),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 15),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                CircleAvatar(
                  backgroundColor:
                  const Color(0xFF2E7D32),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
