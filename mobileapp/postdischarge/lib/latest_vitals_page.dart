import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LatestVitalsPage extends StatefulWidget {
  const LatestVitalsPage({super.key});

  @override
  State<LatestVitalsPage> createState() => _LatestVitalsPageState();
}

class _LatestVitalsPageState extends State<LatestVitalsPage> {

  bool isLoading = true;

  String hemoglobin = "";
  String bloodPressure = "";
  String sugarLevel = "";
  String weight = "";
  String date = "";
  String imageUrl = "";

  @override
  void initState() {
    super.initState();
    fetchLatestVitals();
  }

  // ================= FETCH LATEST VITALS =================
  Future<void> fetchLatestVitals() async {

    try {
      SharedPreferences sh =
      await SharedPreferences.getInstance();

      String baseUrl =
          sh.getString("url") ?? "http://10.0.2.2:8000";

      String? lid = sh.getString("lid");

      if (lid == null) return;

      final response = await http.post(
        Uri.parse("$baseUrl/view_latest_vitals/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.parse(lid),
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        setState(() {
          hemoglobin = data["hemoglobin"] ?? "";
          bloodPressure = data["blood_pressure"] ?? "";
          sugarLevel = data["sugar_level"] ?? "";
          weight = data["weight"] ?? "";
          date = data["date"] ?? "";
          imageUrl = data["image"] ?? "";
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }

    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Latest Health Vitals"),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(18)),
          child: Padding(
            padding:
            const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  "Recorded On: $date",
                  style: const TextStyle(
                      fontWeight:
                      FontWeight.bold),
                ),

                const SizedBox(height: 15),

                buildVitalRow(
                    "Hemoglobin", hemoglobin),
                buildVitalRow(
                    "Blood Pressure",
                    bloodPressure),
                buildVitalRow(
                    "Sugar Level", sugarLevel),
                buildVitalRow(
                    "Weight", weight),

                const SizedBox(height: 20),

                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= REUSABLE ROW =================
  Widget buildVitalRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
                fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
