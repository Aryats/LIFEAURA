import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BloodBankListPage extends StatefulWidget {
  const BloodBankListPage({super.key});

  @override
  State<BloodBankListPage> createState() => _BloodBankListPageState();
}

class _BloodBankListPageState extends State<BloodBankListPage> {
  List organizations = [];
  bool loading = true;

  bool canSendRequest = true;
  String? nextAllowedDate;

  @override
  void initState() {
    super.initState();
    fetchBloodBanks();
  }

  // ============================================================
  // FETCH ORGANIZATIONS
  // ============================================================
  Future<void> fetchBloodBanks() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String baseUrl = sh.getString("url") ?? "http://10.0.2.2:8000";
      String senderId = sh.getString("lid") ?? "";

      final response = await http.post(
        Uri.parse("$baseUrl/view_blood_banks/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": int.parse(senderId),
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        setState(() {
          organizations = data["organizations"] ?? [];
          canSendRequest = data["can_send_request"] ?? true;
          nextAllowedDate = data["next_allowed_date"];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  // ============================================================
  // SEND BLOOD REQUEST (WITH TIME)
  // ============================================================
  Future<void> sendBloodRequest(
      int orgId,
      String bloodGroup,
      String units,
      String time,
      String requiredDate,
      ) async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String baseUrl = sh.getString("url") ?? "http://10.0.2.2:8000";
      String senderId = sh.getString("lid") ?? "";

      final response = await http.post(
        Uri.parse("$baseUrl/send_blood_request/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": int.parse(senderId),
          "organization_id": orgId,
          "blood_group": bloodGroup,
          "units": units,
          "time": time,
          "required_date": requiredDate,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["message"] ?? "Response received"),
          backgroundColor:
          data["status"] == "ok" ? Colors.green : Colors.red,
        ),
      );

      fetchBloodBanks();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server Error: $e")),
      );
    }
  }

  // ============================================================
  // REQUEST DIALOG WITH TIME PICKER (AM/PM)
  // ============================================================
  void showRequestDialog(int orgId) {
    final unitController = TextEditingController();
    String selectedGroup = "A+";
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Send Blood Request"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    // BLOOD GROUP
                    DropdownButtonFormField(
                      value: selectedGroup,
                      decoration: const InputDecoration(
                        labelText: "Blood Group",
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'A+', 'A-', 'B+', 'B-',
                        'O+', 'O-', 'AB+', 'AB-'
                      ].map((group) => DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedGroup = value.toString();
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    // UNITS
                    TextField(
                      controller: unitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Units Required",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // TIME PICKER (AM/PM)
                    InkWell(
                      onTap: () async {
                        TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(context)
                                  .copyWith(alwaysUse24HourFormat: false),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          setStateDialog(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Time (AM/PM)",
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedTime == null
                              ? "Select Time"
                              : selectedTime!.format(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // DATE PICKER
                    InkWell(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );

                        if (pickedDate != null) {
                          setStateDialog(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Required Date",
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                if (unitController.text.isEmpty ||
                    selectedDate == null ||
                    selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("All fields are required"),
                    ),
                  );
                  return;
                }

                String formattedTime = selectedTime!.format(context);

                sendBloodRequest(
                  orgId,
                  selectedGroup,
                  unitController.text,
                  formattedTime,
                  "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                );

                Navigator.pop(context);
              },
              child: const Text("Send Request"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F7),
      appBar: AppBar(
        title: const Text("Organisations"),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (!canSendRequest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Text(
                "You can send next request after $nextAllowedDate",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: organizations.length,
              itemBuilder: (context, index) {
                final org = organizations[index];

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          org["organisation_name"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(org["email"]),
                        Text(org["phone"]),
                        Text(org["address"]),
                        const SizedBox(height: 15),
                        if (canSendRequest)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.redAccent,
                              ),
                              onPressed: () {
                                showRequestDialog(
                                    org["organization_id"]);
                              },
                              child: const Text(
                                  "Send Blood Request"),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}