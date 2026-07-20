import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'userhomescreen.dart';

class RequestedUsersPage extends StatefulWidget {
  const RequestedUsersPage({super.key});

  @override
  State<RequestedUsersPage> createState() => _RequestedUsersPageState();
}

class _RequestedUsersPageState extends State<RequestedUsersPage> {
  bool _loading = true;
  List<dynamic> users = [];
  String userId = "";

  @override
  void initState() {
    super.initState();
    fetchRequestedUsers();
  }

  // ================= API CALL : FETCH REQUESTED USERS =================
  Future<void> fetchRequestedUsers() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final url = sh.getString("url") ?? "http://10.0.2.2:8000";
      userId = sh.getString("lid") ?? "";

      final response = await http.post(
        Uri.parse("$url/user_requested_users/"), // 🔹 Your new API
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"lid": userId}),
      );

      debugPrint("RAW REQUESTED USERS RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        final list = data["requested_users"];
        setState(() {
          users = (list as List?) ?? [];
        });
      } else {
        debugPrint("Error: ${data["message"]}");
      }
    } catch (e) {
      debugPrint("Requested Users Error: $e");
    }

    setState(() => _loading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Requested Users"),
        backgroundColor: Colors.orange[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          ),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text("No requested users found"))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final u = users[index] as Map<String, dynamic>;
          final status = u["request_status"] ?? "pending";

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(u["name"] ?? "Unknown"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Blood Group: ${u["blood_group"] ?? "-"}"),
                  Text("Phone: ${u["phone"] ?? "-"}"),
                  Text("Email: ${u["email"] ?? "-"}"),
                  const SizedBox(height: 4),
                  Text(
                    "Status: ${status.toUpperCase()}",
                    style: TextStyle(
                      color: status == "accepted"
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // 🔹 CHAT ICON ONLY IF ACCEPTED
              trailing: status == "accepted"
                  ? IconButton(
                icon: const Icon(Icons.chat_bubble_outline,
                    color: Colors.blue),
                onPressed: () {
                  // 🔜 Later navigate to Chat Page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Opening chat..."),
                    ),
                  );
                },
              )
                  : const Icon(Icons.hourglass_empty,
                  color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}
