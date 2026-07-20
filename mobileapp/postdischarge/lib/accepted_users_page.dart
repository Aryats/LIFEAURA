import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'chat_page.dart';

class AcceptedUsersPage extends StatefulWidget {
  const AcceptedUsersPage({super.key});

  @override
  State<AcceptedUsersPage> createState() => _AcceptedUsersPageState();
}

class _AcceptedUsersPageState extends State<AcceptedUsersPage> {

  List acceptedUsers = [];
  bool isLoading = true;

  final Color primaryGreen = const Color(0xFF1B5E20);
  final Color lightGreen = const Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    fetchAcceptedUsers();
  }

  Future<void> fetchAcceptedUsers() async {
    try {
      SharedPreferences sp = await SharedPreferences.getInstance();
      String? baseUrl = sp.getString("url");
      String? userId = sp.getString("lid");

      if (baseUrl == null || userId == null) {
        throw Exception("Configuration missing (url/lid)");
      }

      final response = await http.post(
        Uri.parse("$baseUrl/view_accepted_requests/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {

        print("=== ACCEPTED USERS RESPONSE ===");
        print(data["data"]);

        setState(() {
          acceptedUsers = data["data"];
          isLoading = false;
        });

      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Error")),
        );
      }

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        title: const Text("Accepted Donors"),
        backgroundColor: primaryGreen,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : acceptedUsers.isEmpty
          ? const Center(child: Text("No accepted donors yet"))
          : RefreshIndicator(
        onRefresh: fetchAcceptedUsers,
        child: ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: acceptedUsers.length,
          itemBuilder: (context, index) {

            var donor = acceptedUsers[index];

            print("DONOR FULL DATA: $donor");

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        CircleAvatar(
                          radius: 35,
                          backgroundColor: lightGreen,
                          backgroundImage:
                          (donor["donor_profile_picture"] != null &&
                              donor["donor_profile_picture"] != "")
                              ? NetworkImage(donor["donor_profile_picture"])
                              : null,
                          child: (donor["donor_profile_picture"] == null ||
                              donor["donor_profile_picture"] == "")
                              ? Icon(Icons.person,
                              size: 35,
                              color: primaryGreen)
                              : null,
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                donor["donor_name"] ?? "",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),

                              const SizedBox(height: 8),

                              _infoRow(Icons.phone, donor["donor_phone"] ?? ""),
                              _infoRow(Icons.email, donor["donor_email"] ?? ""),
                              _infoRow(Icons.bloodtype,
                                  "Blood Group: ${donor["blood_group"] ?? ""}"),
                              _infoRow(Icons.calendar_today,
                                  "Required Date: ${donor["required_date"] ?? ""}"),
                              _infoRow(Icons.access_time,
                                  "Time: ${donor["required_time"] ?? ""}"),
                              _infoRow(Icons.inventory_2,
                                  "Remaining Units: ${donor["remaining_units"] ?? ""}"),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {

                          var donorId = donor["donor_id"];

                          print("DONOR ID: $donorId");

                          if (donorId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Donor ID missing")),
                            );
                            return;
                          }

                          SharedPreferences sp =
                          await SharedPreferences.getInstance();
                          String? myId = sp.getString("lid");

                          if (myId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("User ID missing")),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                receiverId: donorId.toString(),
                                receiverName:
                                donor["donor_name"] ?? "",
                                myId: myId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text("Chat"),
                      ),
                    )

                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryGreen),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
              )),
        ],
      ),
    );
  }
}