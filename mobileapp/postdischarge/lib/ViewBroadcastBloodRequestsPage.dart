import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewBroadcastBloodRequestsPage extends StatefulWidget {
  const ViewBroadcastBloodRequestsPage({super.key});

  @override
  State<ViewBroadcastBloodRequestsPage> createState() =>
      _ViewBroadcastBloodRequestsPageState();
}

class _ViewBroadcastBloodRequestsPageState
    extends State<ViewBroadcastBloodRequestsPage> {

  List requests = [];
  Timer? refreshTimer;
  bool loading = true;
  bool responding = false;

  @override
  void initState() {
    super.initState();
    fetchRequests();

    // 🔁 Auto refresh every 5 seconds
    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
          (timer) => fetchRequests(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRequests() async {
    try {
      SharedPreferences sp = await SharedPreferences.getInstance();

      String? baseUrl = sp.getString("url");
      String? userId = sp.getString("lid");

      if (baseUrl == null || userId == null) {
        throw Exception("Configuration missing");
      }

      final response = await http.post(
        Uri.parse("$baseUrl/view_broadcast_requests/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        setState(() {
          requests = data["requests"];
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });

        if (data["message"] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"])),
          );
        }
      }

    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  Future<void> respond(int requestId, String action) async {

    if (responding) return;

    setState(() => responding = true);

    try {
      SharedPreferences sp = await SharedPreferences.getInstance();
      String? baseUrl = sp.getString("url");
      String? userId = sp.getString("lid");

      if (baseUrl == null || userId == null) {
        throw Exception("Configuration missing");
      }

      final response = await http.post(
        Uri.parse("$baseUrl/respond_broadcast_request/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "request_id": requestId,
          "donor_id": userId,
          "action": action
        }),
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data["message"])));

      fetchRequests();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() => responding = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        title: const Text("Matching Blood Requests"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(
        child: Text(
          "No matching requests available",
          style: TextStyle(fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchRequests,
        child: ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {

            final req = requests[index];

            return Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Requested By: ${req["sender_name"]}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Blood Group: ${req["blood_group"]}",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text("Units Remaining: ${req["remaining_units"]}"),
                    Text("Date: ${req["required_date"]}"),
                    Text("Time: ${req["required_time"]}"),

                    const SizedBox(height: 16),

                    Row(
                      children: [

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: responding
                                ? null
                                : () => respond(
                                req["request_id"], "accepted"),
                            child: responding
                                ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ))
                                : const Text("Accept"),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: responding
                                ? null
                                : () => respond(
                                req["request_id"], "rejected"),
                            child: const Text("Reject"),
                          ),
                        ),
                      ],
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
}