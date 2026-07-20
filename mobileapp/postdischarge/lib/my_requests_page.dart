// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'user_chat_page.dart';
//
// class MyRequestsPage extends StatefulWidget {
//   const MyRequestsPage({super.key});
//
//   @override
//   State<MyRequestsPage> createState() => _MyRequestsPageState();
// }
//
// class _MyRequestsPageState extends State<MyRequestsPage> {
//
//   List requests = [];
//   bool loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchRequests();
//   }
//
//   // ================= FETCH REQUESTS =================
//   Future<void> fetchRequests() async {
//     try {
//       SharedPreferences sh = await SharedPreferences.getInstance();
//
//       String baseUrl =
//           sh.getString("url") ?? "http://10.0.2.2:8000";
//       String userId =
//           sh.getString("lid") ?? "";
//
//       if (userId.isEmpty) {
//         setState(() => loading = false);
//         return;
//       }
//
//       final response = await http.post(
//         Uri.parse("$baseUrl/view_my_requests/"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "user_id": int.parse(userId),
//         }),
//       );
//
//       final data = jsonDecode(response.body);
//
//       if (data["status"] == "ok") {
//         setState(() {
//           requests = data["requests"] ?? [];
//           loading = false;
//         });
//       } else {
//         setState(() => loading = false);
//       }
//
//     } catch (e) {
//       setState(() => loading = false);
//       debugPrint("Fetch Requests Error: $e");
//     }
//   }
//
//   // ================= STATUS COLOR =================
//   Color getStatusColor(String status) {
//     switch (status) {
//       case "approved":
//         return Colors.green;
//       case "rejected":
//         return Colors.red;
//       default:
//         return Colors.orange;
//     }
//   }
//
//   // ================= REQUEST CARD =================
//   Widget buildRequestCard(Map req) {
//
//     String status = req["status"] ?? "";
//     String receiverName = req["receiver_name"] ?? "";
//     String receiverType = req["receiver_type"] ?? "user";
//
//     int? receiverId;
//     if (req["receiver_id"] != null) {
//       receiverId =
//           int.tryParse(req["receiver_id"].toString());
//     }
//
//     return Card(
//       elevation: 5,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment:
//           CrossAxisAlignment.start,
//           children: [
//
//             // 🔥 Receiver Title Row
//             Row(
//               children: [
//
//                 Icon(
//                   receiverType == "organization"
//                       ? Icons.local_hospital
//                       : Icons.person,
//                   color: const Color(0xFF1B5E20),
//                 ),
//
//                 const SizedBox(width: 8),
//
//                 Expanded(
//                   child: Text(
//                     receiverName,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF1B5E20),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 10),
//
//             Row(
//               children: [
//                 const Icon(Icons.bloodtype, size: 18),
//                 const SizedBox(width: 8),
//                 Text("Blood Group: ${req["blood_group"] ?? '-'}"),
//               ],
//             ),
//
//             const SizedBox(height: 6),
//
//             Row(
//               children: [
//                 const Icon(Icons.monitor_weight, size: 18),
//                 const SizedBox(width: 8),
//                 Text("Units: ${req["units"] ?? '-'}"),
//               ],
//             ),
//
//             const SizedBox(height: 6),
//
//             Row(
//               children: [
//                 const Icon(Icons.calendar_today, size: 18),
//                 const SizedBox(width: 8),
//                 Text("Required: ${req["required_date"] ?? '-'}"),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // ================= STATUS ROW =================
//             Row(
//               mainAxisAlignment:
//               MainAxisAlignment.spaceBetween,
//               children: [
//
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color:
//                     getStatusColor(status).withOpacity(0.15),
//                     borderRadius:
//                     BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     status.toUpperCase(),
//                     style: TextStyle(
//                       color: getStatusColor(status),
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//
//                 Text(
//                   req["request_date"] ?? "",
//                   style: const TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey),
//                 ),
//               ],
//             ),
//
//             // Accepted Date
//             if (req["accepted_date"] != null &&
//                 req["accepted_date"]
//                     .toString()
//                     .isNotEmpty)
//               Padding(
//                 padding:
//                 const EdgeInsets.only(top: 8),
//                 child: Text(
//                   "Accepted On: ${req["accepted_date"]}",
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Colors.green,
//                   ),
//                 ),
//               ),
//
//             // ================= CHAT BUTTON =================
//             if (status == "approved" &&
//                 receiverId != null)
//               Padding(
//                 padding:
//                 const EdgeInsets.only(top: 12),
//                 child: SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                     ),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) =>
//                               UserChatPage(
//                                 receiverId:
//                                 receiverId!,
//                                 receiverName:
//                                 receiverName,
//                               ),
//                         ),
//                       );
//                     },
//                     child: const Text(
//                         "Chat"),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       backgroundColor:
//       const Color(0xFFF4F8F7),
//
//       appBar: AppBar(
//         title: const Text("My Blood Requests"),
//         backgroundColor:
//         const Color(0xFF1B5E20),
//       ),
//
//       body: loading
//           ? const Center(
//           child: CircularProgressIndicator())
//           : requests.isEmpty
//           ? const Center(
//         child: Text(
//           "You have not sent any requests.",
//           style:
//           TextStyle(fontSize: 16),
//         ),
//       )
//           : RefreshIndicator(
//         onRefresh: fetchRequests,
//         child: ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: requests.length,
//           itemBuilder:
//               (context, index) {
//             return buildRequestCard(
//                 requests[index]);
//           },
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'user_chat_page.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {

  List requests = [];
  bool loading = true;

  final Color primaryGreen = const Color(0xFF1B5E20);
  final Color backgroundColor = const Color(0xFFF4F8F7);

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ================= FETCH REQUESTS =================
  Future<void> fetchRequests() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();

      String? baseUrl = sh.getString("url");
      String? userId = sh.getString("lid");

      if (baseUrl == null || userId == null || userId.isEmpty) {
        setState(() => loading = false);
        return;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/view_my_requests/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.parse(userId),
        }),
      );

      final data = jsonDecode(response.body);

      print("==== MY REQUESTS RESPONSE ====");
      print(data);

      if (data["status"] == "ok") {
        setState(() {
          requests = data["requests"] ?? [];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }

    } catch (e) {
      setState(() => loading = false);
      debugPrint("Fetch Requests Error: $e");
    }
  }

  // ================= STATUS COLOR =================
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      case "pending":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ================= REQUEST CARD =================
  Widget buildRequestCard(Map req) {

    String status = (req["status"] ?? "").toString();
    String receiverName = (req["receiver_name"] ?? "").toString();
    String receiverType = (req["receiver_type"] ?? "user").toString();

    int? receiverId;
    if (req["receiver_id"] != null) {
      receiverId = int.tryParse(req["receiver_id"].toString());
    }

    print("Receiver ID: $receiverId");

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== Receiver Row =====
            Row(
              children: [
                Icon(
                  receiverType == "organization"
                      ? Icons.local_hospital
                      : Icons.person,
                  color: primaryGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    receiverName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _infoRow(Icons.bloodtype,
                "Blood Group: ${req["blood_group"] ?? '-'}"),

            const SizedBox(height: 6),

            _infoRow(Icons.monitor_weight,
                "Units: ${req["units"] ?? '-'}"),

            const SizedBox(height: 6),

            _infoRow(Icons.calendar_today,
                "Required: ${req["required_date"] ?? '-'}"),

            const SizedBox(height: 12),

            // ===== Status Row =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  req["request_date"] ?? "",
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey),
                ),
              ],
            ),

            // Accepted Date
            if (req["accepted_date"] != null &&
                req["accepted_date"].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Accepted On: ${req["accepted_date"]}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ),

            // ===== Chat Button =====
            if (status.toLowerCase() == "approved" &&
                receiverId != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      if (receiverId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Receiver ID missing")),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserChatPage(
                            receiverId: receiverId!,
                            receiverName: receiverName,
                          ),
                        ),
                      );
                    },
                    child: const Text("Chat"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("My Blood Requests"),
        backgroundColor: primaryGreen,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(
        child: Text(
          "You have not sent any requests.",
          style: TextStyle(fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchRequests,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return buildRequestCard(requests[index]);
          },
        ),
      ),
    );
  }
}