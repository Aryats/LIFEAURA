import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'userhomescreen.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {

  bool _isEditing = false;
  bool _loading = true;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController bloodCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();

  String userId = "";
  String healthScore = "0";
  String rewardPoints = "0";
  String profileImageUrl = "";

  File? selectedImage;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  // ================= FETCH PROFILE =================
  Future<void> fetchProfile({bool edit = false}) async {

    SharedPreferences sh = await SharedPreferences.getInstance();
    final baseUrl = sh.getString("url") ?? "http://10.0.2.2:8000";
    userId = sh.getString("lid") ?? "";

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/user_profile/"),
    );

    request.fields["lid"] = userId;
    request.fields["action"] = edit ? "edit" : "view";

    request.fields["name"] = nameCtrl.text;
    request.fields["email"] = emailCtrl.text;
    request.fields["phone"] = phoneCtrl.text;
    request.fields["blood_group"] = bloodCtrl.text;
    request.fields["address"] = addressCtrl.text;

    if (selectedImage != null && edit) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "profile_picture",
          selectedImage!.path,
        ),
      );
    }

    var response = await request.send();
    var responseData =
    await response.stream.bytesToString();
    var data = jsonDecode(responseData);

    if (data["status"] == "ok") {
      setState(() {
        nameCtrl.text = data["name"];
        emailCtrl.text = data["email"];
        phoneCtrl.text = data["phone"];
        bloodCtrl.text = data["blood_group"];
        addressCtrl.text = data["address"];
        healthScore = data["health_score"];
        rewardPoints = data["reward_points"];
        profileImageUrl = data["profile_picture"] ?? "";
        selectedImage = null; // reset
      });
    }

    setState(() => _loading = false);
  }

  // ================= IMAGE PICKER =================
  Future<void> pickImage() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F7),

      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_isEditing) {
                await fetchProfile(edit: true);
              }
              setState(() => _isEditing = !_isEditing);
            },
            child: Text(
              _isEditing ? "SAVE" : "EDIT",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [

            // -------- HEADER --------
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1B5E20),
                    Color(0xFF43A047),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [

                  GestureDetector(
                    onTap: _isEditing ? pickImage : null,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : (profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null) as ImageProvider?,
                      child: selectedImage == null &&
                          profileImageUrl.isEmpty
                          ? const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF1B5E20),
                      )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (_isEditing)
                    const Text(
                      "Tap image to change",
                      style: TextStyle(color: Colors.white70),
                    ),

                ],
              ),
            ),

            const SizedBox(height: 20),

            // -------- CARD --------
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      buildField("Name", nameCtrl),
                      buildField("Email", emailCtrl),
                      buildField("Phone", phoneCtrl),
                      buildField("Blood Group", bloodCtrl),
                      buildField("Address", addressCtrl),

                      const Divider(height: 30),

                      infoRow("Health Score", healthScore),
                      infoRow("Reward Points", rewardPoints),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String label,
      TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
