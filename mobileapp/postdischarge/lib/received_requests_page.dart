import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_chat_page.dart';

class ReceivedRequestsPage extends StatefulWidget {
  const ReceivedRequestsPage({super.key});

  @override
  State<ReceivedRequestsPage> createState() =>
      _ReceivedRequestsPageState();
}

class _ReceivedRequestsPageState
    extends State<ReceivedRequestsPage> {

  List requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ================= FETCH =================
  Future<void> fetchRequests() async {

    SharedPreferences sh =
    await SharedPreferences.getInstance();

    String baseUrl =
        sh.getString("url") ?? "http://10.0.2.2:8000";
    String userId =
        sh.getString("lid") ?? "";

    final response = await http.post(
      Uri.parse("$baseUrl/view_received_requests/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": int.parse(userId),
      }),
    );

    final data = jsonDecode(response.body);

    if (data["status"] == "ok") {
      setState(() {
        requests = data["requests"];
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  // ================= UPDATE STATUS =================
  Future<void> updateStatus(int requestId, String action) async {

    SharedPreferences sh =
    await SharedPreferences.getInstance();

    String baseUrl =
        sh.getString("url") ?? "http://10.0.2.2:8000";

    final response = await http.post(
      Uri.parse("$baseUrl/update_received_request_status/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "request_id": requestId,
        "action": action,
      }),
    );

    final data = jsonDecode(response.body);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data["message"]),
        backgroundColor:
        data["status"] == "ok"
            ? Colors.green
            : Colors.red,
      ),
    );

    fetchRequests();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Received Requests"),
        backgroundColor: Colors.redAccent,
      ),

      body: loading
          ? const Center(
          child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(
        child: Text("No requests received"),
      )
          : RefreshIndicator(
        onRefresh: fetchRequests,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {

            final req = requests[index];

            return Card(
              margin:
              const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding:
                const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      "From: ${req["sender_name"]}",
                      style: const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 16),
                    ),

                    const SizedBox(height: 8),

                    Text(
                        "Blood Group: ${req["blood_group"]}"),
                    Text("Units: ${req["units"]}"),
                    Text(
                        "Required Date: ${req["required_date"]}"),

                    const SizedBox(height: 10),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6),
                      decoration: BoxDecoration(
                        color: getStatusColor(
                            req["status"])
                            .withOpacity(0.2),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(
                        req["status"]
                            .toString()
                            .toUpperCase(),
                        style: TextStyle(
                          color:
                          getStatusColor(
                              req["status"]),
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    if (req["status"] ==
                        "pending") ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [

                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton
                                  .styleFrom(
                                  backgroundColor:
                                  Colors.green),
                              onPressed: () =>
                                  updateStatus(
                                      req[
                                      "request_id"],
                                      "approve"),
                              child: const Text(
                                  "Approve"),
                            ),
                          ),

                          const SizedBox(
                              width: 10),

                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton
                                  .styleFrom(
                                  backgroundColor:
                                  Colors.red),
                              onPressed: () =>
                                  updateStatus(
                                      req[
                                      "request_id"],
                                      "reject"),
                              child: const Text(
                                  "Reject"),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (req["status"] ==
                        "approved")
                      Padding(
                        padding:
                        const EdgeInsets.only(
                            top: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserChatPage(
                                        receiverId:
                                        req[
                                        "sender_id"],
                                        receiverName:
                                        req[
                                        "sender_name"],
                                      ),
                                ),
                              );
                            },
                            child:
                            const Text("Chat"),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
