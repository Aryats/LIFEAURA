// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class CreateBroadcastBloodRequestPage extends StatefulWidget {
//   const CreateBroadcastBloodRequestPage({super.key});
//
//   @override
//   State<CreateBroadcastBloodRequestPage> createState() =>
//       _CreateBroadcastBloodRequestPageState();
// }
//
// class _CreateBroadcastBloodRequestPageState
//     extends State<CreateBroadcastBloodRequestPage> {
//
//   String selectedGroup = "A+";
//   final TextEditingController unitsController = TextEditingController();
//   DateTime? selectedDate;
//   TimeOfDay? selectedTime;
//   bool loading = false;
//
//   Future<void> createRequest() async {
//
//     // 🔹 Validation
//     if (unitsController.text.isEmpty ||
//         selectedDate == null ||
//         selectedTime == null) {
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("All fields are required")),
//       );
//       return;
//     }
//
//     if (int.tryParse(unitsController.text) == null ||
//         int.parse(unitsController.text) <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Enter valid units")),
//       );
//       return;
//     }
//
//     setState(() => loading = true);
//
//     try {
//
//       SharedPreferences sp = await SharedPreferences.getInstance();
//
//       String? baseUrl = sp.getString("url");
//       String? senderId = sp.getString("lid");
//
//       if (baseUrl == null || senderId == null) {
//         throw Exception("Server configuration missing");
//       }
//
//       final formattedTime =
//           "${selectedTime!.hourOfPeriod == 0 ? 12 : selectedTime!.hourOfPeriod}:"
//           "${selectedTime!.minute.toString().padLeft(2, '0')} "
//           "${selectedTime!.period == DayPeriod.am ? "AM" : "PM"}";
//
//       final response = await http.post(
//         Uri.parse("$baseUrl/create_broadcast_request/"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "sender_id": senderId,
//           "blood_group": selectedGroup,
//           "units": unitsController.text,
//           "required_date":
//           "${selectedDate!.year}-"
//               "${selectedDate!.month.toString().padLeft(2, '0')}-"
//               "${selectedDate!.day.toString().padLeft(2, '0')}",
//           "required_time": formattedTime,
//         }),
//       );
//
//       final data = jsonDecode(response.body);
//
//       if (data["status"] == "ok") {
//
//         // ✅ Clear form after success
//         unitsController.clear();
//         setState(() {
//           selectedDate = null;
//           selectedTime = null;
//         });
//       }
//
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text(data["message"])));
//
//     } catch (e) {
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${e.toString()}")),
//       );
//
//     } finally {
//       setState(() => loading = false);
//     }
//   }
//
//   @override
//   void dispose() {
//     unitsController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         elevation: 0,
//         title: const Text("Create Blood Request"),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Card(
//           elevation: 8,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//
//                 /// 🔴 Blood Group Dropdown
//                 DropdownButtonFormField(
//                   value: selectedGroup,
//                   decoration: InputDecoration(
//                     labelText: "Blood Group",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   items: [
//                     'A+', 'A-', 'B+', 'B-',
//                     'O+', 'O-', 'AB+', 'AB-'
//                   ].map((e) => DropdownMenuItem(
//                     value: e,
//                     child: Text(e),
//                   )).toList(),
//                   onChanged: (val) {
//                     setState(() => selectedGroup = val!);
//                   },
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 /// 🔴 Units Field
//                 TextField(
//                   controller: unitsController,
//                   keyboardType: TextInputType.number,
//                   decoration: InputDecoration(
//                     labelText: "Units Required",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 /// 🔴 Date Picker
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     icon: const Icon(Icons.calendar_today),
//                     label: Text(selectedDate == null
//                         ? "Select Date"
//                         : selectedDate.toString().split(" ")[0]),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.redAccent,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                     onPressed: () async {
//                       DateTime? picked = await showDatePicker(
//                         context: context,
//                         initialDate: DateTime.now(),
//                         firstDate: DateTime.now(),
//                         lastDate: DateTime(2030),
//                       );
//
//                       if (picked != null) {
//                         setState(() => selectedDate = picked);
//                       }
//                     },
//                   ),
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 /// 🔴 Time Picker
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton.icon(
//                     icon: const Icon(Icons.access_time),
//                     label: Text(selectedTime == null
//                         ? "Select Time"
//                         : selectedTime!.format(context)),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.redAccent,
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                     onPressed: () async {
//                       TimeOfDay? picked = await showTimePicker(
//                         context: context,
//                         initialTime: TimeOfDay.now(),
//                       );
//
//                       if (picked != null) {
//                         setState(() => selectedTime = picked);
//                       }
//                     },
//                   ),
//                 ),
//
//                 const SizedBox(height: 30),
//
//                 /// 🔴 Submit Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.redAccent,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: loading ? null : createRequest,
//                     child: loading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text(
//                       "Create Request",
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ),
//
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'accepted_broadcasts_page.dart'; // ✅ IMPORT ADDED

class CreateBroadcastBloodRequestPage extends StatefulWidget {
  const CreateBroadcastBloodRequestPage({super.key});

  @override
  State<CreateBroadcastBloodRequestPage> createState() =>
      _CreateBroadcastBloodRequestPageState();
}

class _CreateBroadcastBloodRequestPageState
    extends State<CreateBroadcastBloodRequestPage> {

  String selectedGroup = "A+";
  final TextEditingController unitsController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool loading = false;

  Future<void> createRequest() async {

    // ✅ Validation
    if (unitsController.text.isEmpty ||
        selectedDate == null ||
        selectedTime == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    if (int.tryParse(unitsController.text) == null ||
        int.parse(unitsController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid units")),
      );
      return;
    }

    setState(() => loading = true);

    try {

      SharedPreferences sp = await SharedPreferences.getInstance();

      String? baseUrl = sp.getString("url");
      String? senderId = sp.getString("lid");

      if (baseUrl == null || senderId == null) {
        throw Exception("Server configuration missing");
      }

      final formattedTime =
          "${selectedTime!.hourOfPeriod == 0 ? 12 : selectedTime!.hourOfPeriod}:"
          "${selectedTime!.minute.toString().padLeft(2, '0')} "
          "${selectedTime!.period == DayPeriod.am ? "AM" : "PM"}";

      final response = await http.post(
        Uri.parse("$baseUrl/create_broadcast_request/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": senderId,
          "blood_group": selectedGroup,
          "units": unitsController.text,
          "required_date":
          "${selectedDate!.year}-"
              "${selectedDate!.month.toString().padLeft(2, '0')}-"
              "${selectedDate!.day.toString().padLeft(2, '0')}",
          "required_time": formattedTime,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok") {
        unitsController.clear();
        setState(() {
          selectedDate = null;
          selectedTime = null;
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(data["message"])));

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );

    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    unitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // ✅ UPDATED APP BAR
      appBar: AppBar(
        elevation: 0,
        title: const Text("Create Blood Request"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B5E20), // ✅ GREEN
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyAcceptedBroadcastsPage(),
                ),
              );
            },
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                /// 🟢 Blood Group Dropdown
                DropdownButtonFormField(
                  value: selectedGroup,
                  decoration: InputDecoration(
                    labelText: "Blood Group",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    'A+', 'A-', 'B+', 'B-',
                    'O+', 'O-', 'AB+', 'AB-'
                  ].map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  )).toList(),
                  onChanged: (val) {
                    setState(() => selectedGroup = val!);
                  },
                ),

                const SizedBox(height: 20),

                /// 🟢 Units Field
                TextField(
                  controller: unitsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Units Required",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// 🟢 Date Picker
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(selectedDate == null
                        ? "Select Date"
                        : selectedDate.toString().split(" ")[0]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32), // ✅ GREEN
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );

                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                /// 🟢 Time Picker
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(selectedTime == null
                        ? "Select Time"
                        : selectedTime!.format(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (picked != null) {
                        setState(() => selectedTime = picked);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 30),

                /// 🟢 Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: loading ? null : createRequest,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Create Request",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}