
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:intl/intl.dart';
// import 'dart:async';
//
// class PatinetViewReminders extends StatefulWidget {
//   const PatinetViewReminders({Key? key}) : super(key: key);
//
//   @override
//   State<PatinetViewReminders> createState() => _PatinetViewRemindersState();
// }
//
// class _PatinetViewRemindersState extends State<PatinetViewReminders> {
//   List<dynamic> summaries = [];
//   Map<String, String> foodTimings = {};
//   bool isLoading = true;
//   bool remindersOn = true;
//   int? patientId;
//   Timer? _refreshTimer;
//
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeNotifications();
//     _loadStatusAndReminders();
//     _startAutoRefresh();
//   }
//
//   @override
//   void dispose() {
//     _refreshTimer?.cancel();
//     super.dispose();
//   }
//
//   void _startAutoRefresh() {
//     _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
//       _loadStatusAndReminders();
//     });
//   }
//
//   Future<void> _initializeNotifications() async {
//     print("Initializing notifications...");
//
//     tz.initializeTimeZones();
//     tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
//     print("Timezone set to Asia/Kolkata");
//
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const DarwinInitializationSettings initializationSettingsIOS =
//     DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     final InitializationSettings initializationSettings =
//     InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );
//
//     bool? initialized = await flutterLocalNotificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) async {
//         print("Notification tapped: ${response.payload}");
//       },
//     );
//     print("Notification plugin initialized: $initialized");
//
//     final androidPlugin = flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>();
//
//     if (androidPlugin != null) {
//       final bool? granted = await androidPlugin.requestNotificationsPermission();
//       print("Notification permission granted: $granted");
//
//       final bool? exactAlarmGranted =
//       await androidPlugin.requestExactAlarmsPermission();
//       print("Exact alarm permission granted: $exactAlarmGranted");
//     }
//   }
//
//   Future<void> _loadStatusAndReminders() async {
//     final prefs = await SharedPreferences.getInstance();
//     patientId = prefs.getInt('patient_id');
//     final ip = prefs.getString('ipAddress') ?? 'http://127.0.0.1:8000';
//
//     final sUrl = Uri.parse(
//       '${ip.startsWith('http') ? ip : 'http://$ip'}/get_patient_reminder_status?patient_id=$patientId',
//     );
//     final sResp = await http.get(sUrl);
//     if (sResp.statusCode == 200) {
//       remindersOn = jsonDecode(sResp.body)['reminders_on'] ?? true;
//     }
//
//     await _loadFoodTimings(ip);
//
//     final url = Uri.parse(
//       '${ip.startsWith('http') ? ip : 'http://$ip'}/get_patient_notifications?patient_id=$patientId',
//     );
//     final resp = await http.get(url);
//     if (resp.statusCode == 200) {
//       setState(() {
//         summaries = jsonDecode(resp.body)['discharge_summaries'];
//         isLoading = false;
//       });
//
//       if (remindersOn) {
//         await _scheduleAllNotifications();
//       } else {
//         await flutterLocalNotificationsPlugin.cancelAll();
//       }
//     }
//   }
//
//   Future<void> _loadFoodTimings(String ip) async {
//     final url = Uri.parse(
//       '${ip.startsWith('http') ? ip : 'http://$ip'}/get_patient_food_timings?patient_id=$patientId',
//     );
//     final resp = await http.get(url);
//     if (resp.statusCode == 200) {
//       final List<dynamic> timings = jsonDecode(resp.body)['food_timings'] ?? [];
//       foodTimings.clear();
//       for (var timing in timings) {
//         String mealType = timing['meal_type'].toString().toLowerCase();
//         String time = timing['time'].toString();
//         foodTimings[mealType] = time;
//         print("Loaded food timing: $mealType -> $time");
//       }
//       print("All food timings: $foodTimings");
//     }
//   }
//
//   Map<String, dynamic> _calculateSingleReminderTime(
//       String freqPart,
//       DateTime baseDate,
//       ) {
//     String? mealType;
//     int minutesOffset = 0;
//     String label = "";
//
//     if (freqPart.contains('before breakfast')) {
//       mealType = 'breakfast';
//       minutesOffset = -30;
//       label = 'Before Breakfast';
//     } else if (freqPart.contains('after breakfast')) {
//       mealType = 'breakfast';
//       minutesOffset = 5;
//       label = 'After Breakfast';
//     } else if (freqPart.contains('before lunch')) {
//       mealType = 'lunch';
//       minutesOffset = -30;
//       label = 'Before Lunch';
//     } else if (freqPart.contains('after lunch')) {
//       mealType = 'lunch';
//       minutesOffset = 5;
//       label = 'After Lunch';
//     } else if (freqPart.contains('before dinner')) {
//       mealType = 'dinner';
//       minutesOffset = -30;
//       label = 'Before Dinner';
//     } else if (freqPart.contains('after dinner')) {
//       mealType = 'dinner';
//       minutesOffset = 5;
//       label = 'After Dinner';
//     }
//
//     if (mealType != null && foodTimings.containsKey(mealType)) {
//       try {
//         String timeString = foodTimings[mealType]!;
//         int hour;
//         int minute;
//
//         final String upper = timeString.trim().toUpperCase();
//         if (upper.endsWith('AM') || upper.endsWith('PM')) {
//           try {
//             final DateTime parsed = DateFormat('hh:mm:ss a').parse(upper);
//             hour = parsed.hour;
//             minute = parsed.minute;
//           } catch (_) {
//             final DateTime parsed = DateFormat('hh:mm a').parse(upper);
//             hour = parsed.hour;
//             minute = parsed.minute;
//           }
//         } else {
//           final String normalized = timeString.split('.').first;
//           final List<String> parts = normalized.split(':');
//           hour = int.parse(parts[0]);
//           minute = int.parse(parts[1]);
//         }
//
//         tz.TZDateTime mealTime = tz.TZDateTime(
//           tz.local,
//           baseDate.year,
//           baseDate.month,
//           baseDate.day,
//           hour,
//           minute,
//         );
//
//         DateTime reminderTime = mealTime.add(Duration(minutes: minutesOffset));
//         String mealTimeFormatted = DateFormat('hh:mm a').format(DateTime(2000, 1, 1, hour, minute));
//
//         return {
//           'time': reminderTime,
//           'label': label,
//           'mealTime': mealTimeFormatted,
//           'mealType': mealType,
//         };
//       } catch (e) {
//         print("  Error parsing time for $mealType: $e");
//       }
//     }
//     return {};
//   }
//
//   List<Map<String, dynamic>> _calculateReminderTimes(
//       String frequency,
//       DateTime baseDate,
//       ) {
//     String freq = frequency.toLowerCase().trim();
//     List<Map<String, dynamic>> reminderTimes = [];
//
//     List<String> frequencyParts = freq.split(',').map((e) => e.trim()).toList();
//
//     for (String freqPart in frequencyParts) {
//       var reminderData = _calculateSingleReminderTime(freqPart, baseDate);
//       if (reminderData.isNotEmpty) {
//         reminderTimes.add(reminderData);
//       }
//     }
//
//     return reminderTimes;
//   }
//
//   Future<void> _scheduleAllNotifications() async {
//     await flutterLocalNotificationsPlugin.cancelAll();
//
//     print("\n========================================");
//     print("SCHEDULING MEDICINE REMINDERS");
//     print("========================================");
//     print("Food Timings Available: ${foodTimings.keys.join(', ')}");
//     print("----------------------------------------\n");
//
//     int notifId = 1;
//     int scheduledCount = 0;
//     tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//
//     for (var summary in summaries) {
//       print("Hospital: ${summary['hospital']}");
//       print("Discharge Date: ${summary['discharge_date']}\n");
//
//       for (var med in summary['medicines']) {
//         print("Medicine: ${med['medicine_name']}");
//         print("  Dosage: ${med['dosage']}");
//         print("  Frequency: ${med['frequency']}");
//         print("  Duration: ${med['duration']} days");
//
//         if (med['reminder_start'] != null &&
//             med['reminder_end'] != null &&
//             med['frequency'] != null) {
//           DateTime start = DateTime.parse(med['reminder_start']);
//           DateTime end = DateTime.parse(med['reminder_end']);
//           int duration = int.tryParse((med['duration'] ?? "1").toString()) ?? 1;
//
//           print("  Start: ${start.toString().split(' ')[0]}");
//           print("  End: ${end.toString().split(' ')[0]}");
//
//           for (int i = 0; i < duration; i++) {
//             DateTime thisDate = start.add(Duration(days: i));
//
//             if (thisDate.isAfter(end)) {
//               print("  Day ${i + 1}: After end date, stopping");
//               break;
//             }
//
//             List<Map<String, dynamic>> reminderTimes = _calculateReminderTimes(
//               med['frequency'],
//               thisDate,
//             );
//
//             for (var reminderData in reminderTimes) {
//               DateTime reminderTime = reminderData['time'];
//               String label = reminderData['label'];
//               String mealTime = reminderData['mealTime'];
//
//               if (reminderTime.isAfter(now)) {
//                 await _scheduleLocalNotification(
//                   id: notifId++,
//                   title: "Medicine Reminder",
//                   body:
//                   "$label (${mealTime})\n${med['medicine_name']} - ${med['dosage']}\n${summary['hospital']}",
//                   scheduledTime: reminderTime,
//                   medicineName: med['medicine_name'],
//                 );
//                 scheduledCount++;
//
//                 Duration timeUntil = reminderTime.difference(now);
//                 String timeDesc;
//                 if (timeUntil.inDays > 0) {
//                   timeDesc = "in ${timeUntil.inDays} days";
//                 } else if (timeUntil.inHours > 0) {
//                   timeDesc = "in ${timeUntil.inHours} hours";
//                 } else {
//                   timeDesc = "in ${timeUntil.inMinutes} minutes";
//                 }
//
//                 print(
//                   "  $label at $mealTime → ${reminderTime.toString().substring(0, 16)} ($timeDesc)",
//                 );
//               } else {
//                 print(
//                   "  $label: Time in past (${reminderTime.toString().substring(11, 16)})",
//                 );
//               }
//             }
//           }
//         } else {
//           print("  Missing reminder data");
//         }
//         print("");
//       }
//     }
//
//     print("========================================");
//     print("TOTAL NOTIFICATIONS SCHEDULED: $scheduledCount");
//     print("========================================\n");
//   }
//
//   Future<void> _scheduleLocalNotification({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime scheduledTime,
//     required String medicineName,
//   }) async {
//     try {
//       print("\nScheduling notification ID: $id");
//       print("   Title: $title");
//       print("   Time: $scheduledTime");
//
//       final tz.TZDateTime tzScheduledTime = tz.TZDateTime(
//         tz.local,
//         scheduledTime.year,
//         scheduledTime.month,
//         scheduledTime.day,
//         scheduledTime.hour,
//         scheduledTime.minute,
//         scheduledTime.second,
//       );
//
//       print("   TZ Time: $tzScheduledTime");
//
//       const AndroidNotificationDetails androidDetails =
//       AndroidNotificationDetails(
//         'medicine_reminder_channel',
//         'Medicine Reminders',
//         channelDescription:
//         'Notifications to remind you to take your medicines',
//         importance: Importance.max,
//         priority: Priority.high,
//         showWhen: true,
//         enableVibration: true,
//         playSound: true,
//         sound: RawResourceAndroidNotificationSound('notification'),
//         channelShowBadge: true,
//         ticker: 'Medicine Reminder',
//         styleInformation: BigTextStyleInformation(''),
//         icon: '@mipmap/ic_launcher',
//       );
//
//       const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         sound: 'notification.mp3',
//       );
//
//       const NotificationDetails notificationDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );
//
//       await flutterLocalNotificationsPlugin.zonedSchedule(
//         id,
//         title,
//         body,
//         tzScheduledTime,
//         notificationDetails,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         uiLocalNotificationDateInterpretation:
//         UILocalNotificationDateInterpretation.absoluteTime,
//         matchDateTimeComponents: DateTimeComponents.dateAndTime,
//       );
//
//       print("   Successfully scheduled!");
//     } catch (e, stackTrace) {
//       print("Error scheduling notification ID $id: $e");
//       print("Stack trace: $stackTrace");
//     }
//   }
//
//   Future<void> _toggleGlobalReminder(bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     patientId = prefs.getInt('patient_id');
//     final ip = prefs.getString('ipAddress') ?? 'http://127.0.0.1:8000';
//     final url = Uri.parse(
//       '${ip.startsWith('http') ? ip : 'http://$ip'}/set_patient_reminder_status/',
//     );
//     final resp = await http.post(
//       url,
//       body: {'patient_id': '$patientId', 'is_on': value.toString()},
//     );
//     if (resp.statusCode == 200) {
//       setState(() {
//         remindersOn = value;
//         isLoading = true;
//       });
//       await _loadStatusAndReminders();
//     }
//   }
//
//   Future<void> _testNotification() async {
//     print("\n========== TEST NOTIFICATION ==========");
//     tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//     DateTime testTime = now.add(const Duration(seconds: 10));
//     String formattedTime = DateFormat('hh:mm:ss a').format(testTime);
//
//     print("Current time: $now");
//     print("Scheduled time: $testTime");
//     print("Formatted: $formattedTime");
//
//     await _scheduleLocalNotification(
//       id: 9999,
//       title: "Test Notification",
//       body: "This is a test notification with custom sound!",
//       scheduledTime: testTime,
//       medicineName: "Test",
//     );
//
//     const AndroidNotificationDetails androidDetails =
//     AndroidNotificationDetails(
//       'medicine_reminder_channel',
//       'Medicine Reminders',
//       channelDescription:
//       'Notifications to remind you to take your medicines',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//       enableVibration: true,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('notification'),
//     );
//
//     const NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//     );
//
//     await flutterLocalNotificationsPlugin.show(
//       9998,
//       "Immediate Test",
//       "This notification will play custom sound!",
//       notificationDetails,
//     );
//     print("Immediate notification sent");
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           "Test scheduled for $formattedTime\nCustom sound will play!",
//         ),
//         backgroundColor: Colors.blue,
//         duration: const Duration(seconds: 5),
//       ),
//     );
//     print("Test notification scheduled for: $formattedTime");
//     print("========================================\n");
//   }
//
//   Future<void> _showPendingNotifications() async {
//     final List<PendingNotificationRequest> pendingNotifications =
//     await flutterLocalNotificationsPlugin.pendingNotificationRequests();
//
//     print("\nPending Notifications: ${pendingNotifications.length}");
//     for (var notif in pendingNotifications) {
//       print("  - ID: ${notif.id}, Title: ${notif.title}");
//     }
//
//     if (pendingNotifications.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("No pending notifications"),
//           backgroundColor: Colors.orange,
//         ),
//       );
//     } else {
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text(
//             "Pending Notifications (${pendingNotifications.length})",
//           ),
//           content: SizedBox(
//             width: double.maxFinite,
//             height: 400,
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount: pendingNotifications.length,
//               itemBuilder: (context, index) {
//                 final notif = pendingNotifications[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(vertical: 4),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.teal,
//                       child: Text("${index + 1}"),
//                     ),
//                     title: Text(
//                       notif.title ?? "No title",
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(
//                       notif.body ?? "No body",
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     trailing: Text(
//                       "ID: ${notif.id}",
//                       style: const TextStyle(fontSize: 12),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Close"),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   Future<void> _refreshReminders() async {
//     setState(() {
//       isLoading = true;
//     });
//     await _loadStatusAndReminders();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage('assets/bg1.png'),
//           fit: BoxFit.cover,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.teal.shade700, Colors.teal.shade400, Colors.white],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               stops: const [0.0, 0.3, 1.0],
//             ),
//           ),
//           child: SafeArea(
//             child: Column(
//               children: [
//                 // AppBar
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [Colors.teal.shade700, Colors.teal.shade500],
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.white),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                       const Text(
//                         "My Medicine Reminders",
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         icon: const Icon(Icons.refresh, color: Colors.white),
//                         onPressed: _refreshReminders,
//                         tooltip: 'Refresh',
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Main Content
//                 Expanded(
//                   child: RefreshIndicator(
//                     onRefresh: _refreshReminders,
//                     child: isLoading
//                         ? const Center(
//                       child: CircularProgressIndicator(color: Colors.white),
//                     )
//                         : Column(
//                       children: [
//                         // Header Card
//                         Container(
//                           margin: const EdgeInsets.all(16),
//                           padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.95),
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.1),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const Icon(Icons.notifications_active, color: Colors.teal),
//                                   const SizedBox(width: 10),
//                                   const Text(
//                                     "Medicine Reminders",
//                                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
//                                   ),
//                                   const SizedBox(width: 15),
//                                   Switch(
//                                     value: remindersOn,
//                                     onChanged: (v) => _toggleGlobalReminder(v),
//                                     activeColor: Colors.teal,
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   ElevatedButton.icon(
//                                     onPressed: _showPendingNotifications,
//                                     icon: const Icon(Icons.list, size: 18),
//                                     label: const Text("View Pending"),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.blue,
//                                       foregroundColor: Colors.white,
//                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               if (foodTimings.isNotEmpty)
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 12),
//                                   child: Container(
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       color: Colors.teal.shade50,
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Column(
//                                       children: [
//                                         const Text("Your Meal Times:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
//                                         const SizedBox(height: 6),
//                                         Row(
//                                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                                           children: foodTimings.entries.map((e) {
//                                             String time = e.value.split(':').take(2).join(':');
//                                             return Row(
//                                               children: [
//                                                 const Icon(Icons.restaurant, size: 14, color: Colors.teal),
//                                                 const SizedBox(width: 4),
//                                                 Text("${e.key.capitalize()}: $time", style: const TextStyle(fontSize: 12)),
//                                               ],
//                                             );
//                                           }).toList(),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//
//                         // List
//                         Expanded(
//                           child: summaries.isEmpty
//                               ? ListView(
//                             children: const [
//                               SizedBox(height: 100),
//                               Center(
//                                 child: Column(
//                                   children: [
//                                     Icon(Icons.medication, size: 64, color: Colors.white70),
//                                     SizedBox(height: 16),
//                                     Text("No medicine reminders.", style: TextStyle(fontSize: 16, color: Colors.white)),
//                                     SizedBox(height: 8),
//                                     Text("Pull down to refresh", style: TextStyle(fontSize: 12, color: Colors.white70)),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           )
//                               : ListView.builder(
//                             padding: const EdgeInsets.symmetric(horizontal: 16),
//                             itemCount: summaries.length,
//                             itemBuilder: (_, i) {
//                               final s = summaries[i];
//                               final List medList = s['medicines'] ?? [];
//                               return Card(
//                                 margin: const EdgeInsets.only(bottom: 16),
//                                 elevation: 6,
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(16),
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Icon(Icons.local_hospital, color: Colors.teal.shade600),
//                                           const SizedBox(width: 8),
//                                           Expanded(
//                                             child: Text(
//                                               "${s['hospital']} | Discharge: ${s['discharge_date']}",
//                                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 12),
//                                       medList.isEmpty
//                                           ? const Center(child: Text("No medicines."))
//                                           : SingleChildScrollView(
//                                         scrollDirection: Axis.horizontal,
//                                         child: DataTable(
//                                           headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
//                                           columnSpacing: 20,
//                                           columns: const [
//                                             DataColumn(label: Text("Medicine", style: TextStyle(fontWeight: FontWeight.bold))),
//                                             DataColumn(label: Text("Dosage", style: TextStyle(fontWeight: FontWeight.bold))),
//                                             DataColumn(label: Text("When", style: TextStyle(fontWeight: FontWeight.bold))),
//                                             DataColumn(label: Text("Days", style: TextStyle(fontWeight: FontWeight.bold))),
//                                           ],
//                                           rows: List.generate(medList.length, (j) {
//                                             final m = medList[j];
//                                             return DataRow(cells: [
//                                               DataCell(Text(m["medicine_name"] ?? "-", style: const TextStyle(fontWeight: FontWeight.w500))),
//                                               DataCell(Text(m["dosage"] ?? "-")),
//                                               DataCell(Text(m["frequency"] ?? "-")),
//                                               DataCell(Text("${m["duration"] ?? "-"} days")),
//                                             ]);
//                                           }),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// extension StringExtension on String {
//   String capitalize() {
//     return "${this[0].toUpperCase()}${substring(1)}";
//   }
// }