
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'userhomescreen.dart';

class IncomingRequestPage extends StatefulWidget {
  const IncomingRequestPage({super.key});

  @override
  State<IncomingRequestPage> createState() => _IncomingRequestPageState();
}

class _IncomingRequestPageState extends State<IncomingRequestPage> {
  bool _loading = true;
  List<dynamic> requests = [];
  String userId = "";

  @override
  void initState() {
    super.initState();
    fetchIncomingRequests();
  }

  // ================= API CALL : FETCH INCOMING REQUESTS =================
  Future<void> fetchIncomingRequests() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final url = sh.getString("url") ?? "http://10.0.2.2:8000";
      userId = sh.getString("lid") ?? "";

      final response = await http.post(
        Uri.parse("$url/incoming_request/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"lid": userId}),
      );

      debugPrint("RAW RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        final incoming = data["incoming_requests"];
        setState(() {
          requests = (incoming as List?) ?? [];
        });
      } else {
        debugPrint("Error: ${data["message"]}");
      }
    } catch (e) {
      debugPrint("Incoming Requests Error: $e");
    }

    setState(() => _loading = false);
  }

  // ================= API CALL : UPDATE REQUEST STATUS =================
  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final url = sh.getString("url") ?? "http://10.0.2.2:8000";

      final response = await http.post(
        Uri.parse("$url/update_request_status/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "request_id": requestId,
          "status": status, // "accepted" or "rejected"
        }),
      );

      debugPrint("UPDATE STATUS RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request $status successfully")),
        );

        // Refresh the list after update
        fetchIncomingRequests();
      } else {
        String msg = data["message"]?.toString() ?? "Update failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      debugPrint("Update Status Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error while updating status")),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Requests"),
        backgroundColor: Colors.green[700],
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
          : requests.isEmpty
          ? const Center(child: Text("No incoming requests"))
          : ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index] as Map<String, dynamic>;

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.bloodtype, color: Colors.white),
              ),
              title: Text(req["name"] ?? "Unknown User"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Blood Group: ${req["blood_group"] ?? "-"}"),
                  Text("Phone: ${req["phone"] ?? "-"}"),
                  Text("Address: ${req["address"] ?? "-"}"),
                  Text("Status: ${req["status"] ?? "-"}"),
                  if (req["request_date"] != null)
                    Text("Requested: ${req["request_date"]}"),

                  const SizedBox(height: 8),

                  // ================= Buttons =================
                  Row(
                    children: [
                      // If not accepted, show Accept / Reject
                      if (req["status"] != "accepted") ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            updateRequestStatus(
                              req["request_id"].toString(),
                              "accepted",
                            );
                          },
                          child: const Text("Accept"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            updateRequestStatus(
                              req["request_id"].toString(),
                              "rejected",
                            );
                          },
                          child: const Text("Reject"),
                        ),
                      ] else ...[
                        // If accepted, show Chat icon
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Chat feature coming soon!")),
                            );
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text("Chat"),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
