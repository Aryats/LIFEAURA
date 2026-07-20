import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MatchingUsersPage extends StatefulWidget {
  const MatchingUsersPage({super.key});

  @override
  State<MatchingUsersPage> createState() => _MatchingUsersPageState();
}

class _MatchingUsersPageState extends State<MatchingUsersPage> {

  List matchingEligible = [];
  List matchingNotEligible = [];
  List otherEligible = [];
  List otherNotEligible = [];

  bool senderCanSend = true;
  String? senderNextDate;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMatchingUsers();
  }

  Future<void> fetchMatchingUsers() async {

    SharedPreferences sh = await SharedPreferences.getInstance();
    String baseUrl = sh.getString("url") ?? "http://10.0.2.2:8000";
    String? userId = sh.getString("lid");

    if (userId == null) return;

    final response = await http.post(
      Uri.parse("$baseUrl/view_matching_users/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId}),
    );

    final data = jsonDecode(response.body);

    if (data["status"] == "ok") {
      setState(() {
        matchingEligible = data["matching"]["eligible"];
        matchingNotEligible = data["matching"]["not_eligible"];
        otherEligible = data["others"]["eligible"];
        otherNotEligible = data["others"]["not_eligible"];
        senderCanSend = data["sender_can_send_request"];
        senderNextDate = data["sender_next_request_allowed_date"];
        isLoading = false;
      });
    }
  }

  Future<void> sendBloodRequest(int receiverId, String bloodGroup) async {

    if (!senderCanSend) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Next request allowed on $senderNextDate"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    SharedPreferences sh = await SharedPreferences.getInstance();
    String baseUrl = sh.getString("url") ?? "http://10.0.2.2:8000";
    String? senderId = sh.getString("lid");

    TextEditingController unitsController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          title: const Text("Send Blood Request",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: unitsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Units Required",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );

                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text("Select Required Date"),
              )
            ],
          ),
          actions: [

            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {

                if (unitsController.text.isEmpty ||
                    selectedDate == null) {
                  return;
                }

                final response = await http.post(
                  Uri.parse("$baseUrl/send_user_blood_request/"),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode({
                    "sender_id": senderId,
                    "receiver_id": receiverId,
                    "blood_group": bloodGroup,
                    "units": unitsController.text,
                    "required_date":
                    selectedDate!.toIso8601String().split("T")[0],
                  }),
                );

                final data = jsonDecode(response.body);

                Navigator.pop(context);

                if (data["status"] == "ok") {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Request Sent Successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  fetchMatchingUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data["message"]),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  Widget buildUserCard(Map user, bool eligible) {

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [

            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green.shade100,
              backgroundImage: user["profile_picture"] != ""
                  ? NetworkImage(user["profile_picture"])
                  : null,
              child: user["profile_picture"] == ""
                  ? const Icon(Icons.person, color: Colors.green)
                  : null,
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    user["name"],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Blood Group: ${user["blood_group"]}",
                    style: const TextStyle(
                        color: Colors.black54),
                  ),
                ],
              ),
            ),

            eligible
                ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10)),
              ),
              onPressed: () =>
                  sendBloodRequest(user["user_id"],
                      user["blood_group"]),
              child: const Text("Request"),
            )
                : Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius:
                BorderRadius.circular(10),
              ),
              child: const Text(
                "Not Eligible",
                style:
                TextStyle(color: Colors.black54),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text("Matching Users"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            if (!senderCanSend)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Text(
                  "Next request allowed on $senderNextDate",
                  style:
                  const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 15),

            const Text("Matching & Eligible",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),

            ...matchingEligible
                .map((u) => buildUserCard(u, true)),

            const SizedBox(height: 15),

            const Text("Other Eligible Users",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),

            ...otherEligible
                .map((u) => buildUserCard(u, true)),
          ],
        ),
      ),
    );
  }
}
