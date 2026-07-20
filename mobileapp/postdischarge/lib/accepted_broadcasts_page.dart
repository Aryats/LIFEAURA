import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'user_chat_page.dart';

class MyAcceptedBroadcastsPage extends StatefulWidget {
  const MyAcceptedBroadcastsPage({super.key});

  @override
  State<MyAcceptedBroadcastsPage> createState() =>
      _MyAcceptedBroadcastsPageState();
}

class _MyAcceptedBroadcastsPageState
    extends State<MyAcceptedBroadcastsPage> {

  List accepted = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchAccepted();
  }

  Future<void> fetchAccepted() async {
    try {
      SharedPreferences sp =
      await SharedPreferences.getInstance();

      String baseUrl = sp.getString("url") ?? "";
      String userId = sp.getString("lid") ?? "";

      final response = await http.post(
        Uri.parse("$baseUrl/view_my_accepted_broadcasts/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        setState(() {
          accepted = data["data"];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }

    } catch (e) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Accepted Users"),
        backgroundColor: const Color(0xFF1B5E20),
        centerTitle: true,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())

          : accepted.isEmpty
          ? const Center(
        child: Text(
          "No accepted users",
          style: TextStyle(fontSize: 16),
        ),
      )

          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: accepted.length,
        itemBuilder: (context, index) {

          var item = accepted[index];

          return Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.only(bottom: 16),

            child: ListTile(

              contentPadding:
              const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15),

              leading: const CircleAvatar(
                backgroundColor:
                Color(0xFF1B5E20),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),

              title: Text(
                item["sender_name"],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF1B5E20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserChatPage(
                            receiverId:
                            item["sender_id"],
                            receiverName:
                            item["sender_name"],
                          ),
                    ),
                  );
                },
                child: const Text("Chat"),
              ),
            ),
          );
        },
      ),
    );
  }
}