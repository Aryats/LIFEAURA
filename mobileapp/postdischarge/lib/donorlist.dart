import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'userhomescreen.dart';

class DonorList extends StatefulWidget {
  const DonorList({super.key});

  @override
  State<DonorList> createState() => _DonorListState();
}

class _DonorListState extends State<DonorList> {
  bool _loading = true;
  String userId = "";
  List donors = [];

  @override
  void initState() {
    super.initState();
    fetchDonors();
  }

  // ================= FETCH DONORS =================
  Future<void> fetchDonors() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final url = sh.getString("url") ?? "http://10.0.2.2:8000";
      userId = sh.getString("lid") ?? "";

      final response = await http.post(
        Uri.parse("$url/donor_list/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"lid": userId}),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        setState(() {
          donors = data["profiles"];
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
    setState(() => _loading = false);
  }

  // ================= SEND REQUEST =================
  Future<void> sendBloodRequest(int donorId, String bloodGroup) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final url = sh.getString("url") ?? "http://10.0.2.2:8000";
      userId = sh.getString("lid") ?? "";

      final response = await http.post(
        Uri.parse("$url/send_request/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": int.parse(userId),
          "receiver_id": donorId,
          "blood_group": bloodGroup,
        }),
      );

      final data = jsonDecode(response.body);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request failed")),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor List"),
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
          : donors.isEmpty
          ? const Center(child: Text("No donors found"))
          : ListView.builder(
        itemCount: donors.length,
        itemBuilder: (context, index) {
          final donor = donors[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(donor["name"]),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Blood Group: ${donor["blood_group"]}"),
                  Text("Address: ${donor["address"]}"),
                  const SizedBox(height: 6),
                  ElevatedButton(
                    onPressed: () {
                      sendBloodRequest(
                        donor["id"],
                        donor["blood_group"],
                      );
                    },
                    child: const Text("Send Request"),
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
