import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'latest_vitals_page.dart';

class vitals extends StatefulWidget {
  const vitals({super.key});

  @override
  State<vitals> createState() => _vitalsState();
}

class _vitalsState extends State<vitals> {

  final TextEditingController hemoController = TextEditingController();
  final TextEditingController bpController = TextEditingController();
  final TextEditingController sugarController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  File? selectedImage;
  bool isLoading = false;
  int? healthScore;

  // ================= IMAGE PICKER =================
  Future<void> pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // ================= SUBMIT TO DJANGO =================
  Future<void> submitVitals() async {

    if (hemoController.text.isEmpty ||
        bpController.text.isEmpty ||
        sugarController.text.isEmpty ||
        weightController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    SharedPreferences sh =
    await SharedPreferences.getInstance();

    String baseUrl =
        sh.getString("url") ?? "http://10.0.2.2:8000";

    String? lid = sh.getString("lid");

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/upload_vitals/"),
    );

    request.fields["lid"] = lid ?? "";
    request.fields["hemoglobin"] = hemoController.text;
    request.fields["blood_pressure"] = bpController.text;
    request.fields["sugar_level"] = sugarController.text;
    request.fields["weight"] = weightController.text;

    if (selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "image",
          selectedImage!.path,
        ),
      );
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var data = jsonDecode(responseData);

    setState(() => isLoading = false);

    if (data["status"] == "ok") {

      setState(() {
        healthScore = data["health_score"];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Health Score: ${data["health_score"]}"),
          backgroundColor: Colors.green,
        ),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["message"]),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Health Assistant"),
        backgroundColor: Colors.green[700],

        // ✅ RIGHT SIDE BUTTON
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: "View Latest Vitals",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const LatestVitalsPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            const Text(
              "Health Vitals",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            buildInputField(
                hemoController,
                "Hemoglobin",
                "e.g. 13.5 g/dL"),

            const SizedBox(height: 10),

            buildInputField(
                bpController,
                "Blood Pressure",
                "e.g. 120/80"),

            const SizedBox(height: 10),

            buildInputField(
                sugarController,
                "Sugar Level",
                "e.g. 95 mg/dL"),

            const SizedBox(height: 10),

            buildInputField(
                weightController,
                "Weight",
                "e.g. 65 kg"),

            const SizedBox(height: 20),

            const Text(
              "Upload Medical Image",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                border:
                Border.all(color: Colors.grey),
                borderRadius:
                BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: selectedImage == null
                  ? const Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(Icons.image,
                      size: 50,
                      color: Colors.grey),
                  SizedBox(height: 8),
                  Text("No image selected"),
                ],
              )
                  : ClipRRect(
                borderRadius:
                BorderRadius.circular(8),
                child: Image.file(
                  selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.upload),
                label: const Text("Upload Image"),
              ),
            ),

            const SizedBox(height: 20),

            if (healthScore != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding:
                  const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.favorite,
                          color: Colors.green),
                      const SizedBox(width: 10),
                      Text(
                        "Health Score: $healthScore",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                isLoading ? null : submitVitals,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.green[700],
                  padding:
                  const EdgeInsets.symmetric(
                      vertical: 14),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Text(
                  "Analyze Vitals",
                  style:
                  TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget buildInputField(
      TextEditingController controller,
      String label,
      String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border:
        const OutlineInputBorder(),
      ),
    );
  }
}
