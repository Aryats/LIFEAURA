import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();

FlutterTts flutterTts = FlutterTts();

class PrescriptionPage extends StatefulWidget {
  const PrescriptionPage({super.key});

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {

  File? selectedImage;
  bool isLoading = false;
  List medicines = [];

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null) {
          await flutterTts.speak(details.payload!);
        }
      },
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> pickImage() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> uploadPrescription() async {

    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select image")),
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
      Uri.parse("$baseUrl/upload_prescription/"),
    );

    request.fields["lid"] = lid ?? "";
    request.files.add(
      await http.MultipartFile.fromPath(
        "image",
        selectedImage!.path,
      ),
    );

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var data = jsonDecode(responseData);

    setState(() => isLoading = false);

    if (data["status"] == "ok") {

      setState(() {
        medicines = data["medicines"];
      });

      scheduleAllNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reminder Scheduled Successfully"),
          backgroundColor: Colors.green,
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])),
      );
    }
  }

  Future<void> scheduleAllNotifications() async {

    for (int i = 0; i < medicines.length; i++) {

      DateTime reminderTime =
      DateTime.parse(medicines[i]["reminder_time"]);

      await notificationsPlugin.zonedSchedule(
        i,
        "Medicine Reminder",
        medicines[i]["medicine_name"],
        tz.TZDateTime.from(reminderTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine Reminder',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode:
        AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload:
        "Time to take ${medicines[i]["medicine_name"]}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Prescription Analyzer"),
        backgroundColor: Colors.green[700],
      ),

      body: Stack(
        children: [

          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: selectedImage == null
                      ? const Center(
                      child: Text("No Image Selected"))
                      : Image.file(selectedImage!,
                      fit: BoxFit.cover),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Select Prescription"),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : uploadPrescription,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("Upload & Auto Schedule"),
                  ),
                ),

                const SizedBox(height: 25),

                if (medicines.isNotEmpty)
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Scheduled Medicines",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      ...medicines.map((med) => Card(
                        elevation: 3,
                        child: ListTile(
                          leading: const Icon(
                              Icons.medication,
                              color: Colors.green),
                          title:
                          Text(med["medicine_name"]),
                          subtitle: Text(
                              "Reminder: ${med["reminder_time"]}"),
                        ),
                      ))
                    ],
                  )
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
