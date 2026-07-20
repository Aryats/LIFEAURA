import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:intl/intl.dart';
import 'dart:async';

class PatinetViewReminders extends StatefulWidget {
  const PatinetViewReminders({Key? key}) : super(key: key);

  @override
  State<PatinetViewReminders> createState() => _PatinetViewRemindersState();
}

class _PatinetViewRemindersState extends State<PatinetViewReminders> {
  List<dynamic> summaries = [];
  Map<String, String> foodTimings = {};
  bool isLoading = true;
  bool remindersOn = true;
  int? patientId;
  Timer? _refreshTimer;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // ------- Demo mirror & countdown state -------
  tz.TZDateTime? _nextDueDemoAt;
  bool _demoFiredForNext = false;
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  String _demoMedName = "";
  String _demoDosage = "";
  String _demoLabel = "";
  String _demoMealTime = "";
  // --------------------------------------------

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadStatusAndReminders();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _loadStatusAndReminders();
      // _checkAndFireDemoIfDue();
    });
  }

  Future<void> _initializeNotifications() async {
    debugPrint("🔧 Initializing notifications...");

    // Timezone
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    debugPrint("✅ Timezone set to Asia/Kolkata");


    // tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    // debugPrint("✅ Timezone set to Europe/Berlin");


    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) async {
        debugPrint("📬 Notification tapped: ${response.payload}");
      },
    );
    debugPrint("✅ Notification plugin initialized: $initialized");

    // Android 13+ runtime permissions
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final bool? granted = await android.requestNotificationsPermission();
      debugPrint("✅ Notification permission granted: $granted");

      // Exact alarms
      final bool? exactAlarmGranted =
      await android.requestExactAlarmsPermission();
      debugPrint("✅ Exact alarm permission granted: $exactAlarmGranted");
    }
  }

  Future<void> _loadStatusAndReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      patientId = prefs.getInt('patient_id');
      final ip = prefs.getString('ipAddress') ?? 'http://127.0.0.1:8000';

      final sUrl = Uri.parse(
        '${ip.startsWith('http') ? ip : 'http://$ip'}/get_patient_reminder_status?patient_id=$patientId',
      );
      final sResp = await http.get(sUrl);
      if (sResp.statusCode == 200) {
        remindersOn = jsonDecode(sResp.body)['reminders_on'] ?? true;
      }

      await _loadFoodTimings(ip);

      final url = Uri.parse(
        '${ip.startsWith('http') ? ip : 'http://$ip'}/get_patient_notifications?patient_id=$patientId',
      );
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        setState(() {
          summaries = jsonDecode(resp.body)['discharge_summaries'];
          isLoading = false;
        });

        if (remindersOn) {
          await _scheduleAllNotifications();
        } else {
          await flutterLocalNotificationsPlugin.cancelAll();
          _nextDueDemoAt = null;
          _demoFiredForNext = false;
          _stopCountdown();
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error loading reminders: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFoodTimings(String ip) async {
    try {
      final url = Uri.parse(
        '${ip.startsWith('http') ? ip : 'http://$ip'}/get_patient_food_timings?patient_id=$patientId',
      );
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final List<dynamic> timings =
            jsonDecode(resp.body)['food_timings'] ?? [];
        foodTimings.clear();
        for (var timing in timings) {
          final String mealType = timing['meal_type'].toString().toLowerCase();
          final String time = timing['time'].toString();
          foodTimings[mealType] = time;
          debugPrint("✅ Loaded food timing: $mealType -> $time");
        }
        debugPrint("📋 All food timings: $foodTimings");
      }
    } catch (e) {
      debugPrint("❌ Error loading food timings: $e");
    }
  }

  // Robust time parsing (supports 12h with/without seconds and 24h)
  TimeOfDay? _parseTimeString(String timeString) {
    try {
      final String cleaned = timeString.trim().toUpperCase();
      debugPrint("🕒 Parsing time: '$timeString' -> '$cleaned'");

      if (cleaned.contains('AM') || cleaned.contains('PM')) {
        try {
          final parsed = DateFormat('hh:mm:ss a').parse(cleaned);
          return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
        } catch (_) {
          try {
            final parsed = DateFormat('hh:mm a').parse(cleaned);
            return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
          } catch (_) {
            final parsed = DateFormat('h:mm a').parse(cleaned);
            return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
          }
        }
      }

      // 24-hour fallback
      final normalized = timeString.split('.').first.trim();
      final parts = normalized.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      debugPrint("  ❌ Failed to parse time '$timeString': $e");
    }
    return null;
  }

  Map<String, dynamic> _calculateSingleReminderTime(
      String freqPart,
      DateTime baseDate,
      ) {
    String? mealType;
    int minutesOffset = 0;
    String label = "";

    final part = freqPart.toLowerCase();

    if (part.contains('before breakfast')) {
      mealType = 'breakfast';
      minutesOffset = -30;
      label = 'Before Breakfast';
    } else if (part.contains('after breakfast')) {
      mealType = 'breakfast';
      minutesOffset = 5;
      label = 'After Breakfast';
    } else if (part.contains('before lunch')) {
      mealType = 'lunch';
      minutesOffset = -30;
      label = 'Before Lunch';
    } else if (part.contains('after lunch')) {
      mealType = 'lunch';
      minutesOffset = 5;
      label = 'After Lunch';
    } else if (part.contains('before dinner')) {
      mealType = 'dinner';
      minutesOffset = -30;
      label = 'Before Dinner';
    } else if (part.contains('after dinner')) {
      mealType = 'dinner';
      minutesOffset = 5;
      label = 'After Dinner';
    }

    if (mealType != null && foodTimings.containsKey(mealType)) {
      final timeOfDay = _parseTimeString(foodTimings[mealType]!);

      if (timeOfDay != null) {
        final tz.TZDateTime mealTime = tz.TZDateTime(
          tz.local,
          baseDate.year,
          baseDate.month,
          baseDate.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );

        final tz.TZDateTime reminderTime =
        mealTime.add(Duration(minutes: minutesOffset));

        final String mealTimeFormatted = DateFormat('hh:mm a').format(
          DateTime(2000, 1, 1, timeOfDay.hour, timeOfDay.minute),
        );

        debugPrint(
          "  ✅ Calculated: $label at ${DateFormat('HH:mm').format(reminderTime)}",
        );

        return {
          'time': reminderTime,
          'label': label,
          'mealTime': mealTimeFormatted,
          'mealType': mealType,
        };
      }
    }
    return {};
  }

  List<Map<String, dynamic>> _calculateReminderTimes(
      String frequency,
      DateTime baseDate,
      ) {
    final String freq = frequency.toLowerCase().trim();
    final List<Map<String, dynamic>> reminderTimes = [];

    final List<String> parts = freq.split(',').map((e) => e.trim()).toList();

    for (final String part in parts) {
      final reminderData = _calculateSingleReminderTime(part, baseDate);
      if (reminderData.isNotEmpty) {
        reminderTimes.add(reminderData);
      }
    }

    return reminderTimes;
  }

  Future<void> _scheduleAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();

    debugPrint("\n========================================");
    debugPrint("🔔 SCHEDULING MEDICINE REMINDERS");
    debugPrint("========================================");
    debugPrint("Food Timings Available: ${foodTimings.keys.join(', ')}");
    debugPrint("----------------------------------------\n");

    int notifId = 1;
    int scheduledCount = 0;
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime? earliest; // track earliest future time we schedule

    for (final summary in summaries) {
      debugPrint("🏥 Hospital: ${summary['hospital']}");
      debugPrint("📅 Discharge Date: ${summary['discharge_date']}\n");

      for (final med in (summary['medicines'] ?? []) as List) {
        debugPrint("💊 Medicine: ${med['medicine_name']}");
        debugPrint("  Dosage: ${med['dosage']}");
        debugPrint("  Frequency: ${med['frequency']}");
        debugPrint("  Duration: ${med['duration']} days");

        if (med['reminder_start'] != null &&
            med['reminder_end'] != null &&
            med['frequency'] != null) {
          final DateTime start = DateTime.parse(med['reminder_start']);
          final DateTime end = DateTime.parse(med['reminder_end']);
          final int duration =
              int.tryParse((med['duration'] ?? "1").toString()) ?? 1;

          debugPrint("  Start: ${start.toString().split(' ').first}");
          debugPrint("  End: ${end.toString().split(' ').first}");

          // Clamp loop start to today so we don't iterate past days
          final DateTime today = DateTime.now();
          DateTime loopStart = DateTime(start.year, start.month, start.day);
          final DateTime todayOnly =
          DateTime(today.year, today.month, today.day);
          if (todayOnly.isAfter(loopStart)) {
            loopStart = todayOnly;
          }

          for (DateTime d = loopStart;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1))) {
            final List<Map<String, dynamic>> reminderTimes =
            _calculateReminderTimes(med['frequency'], d);

            for (final reminderData in reminderTimes) {
              final tz.TZDateTime reminderTime =
              reminderData['time'] as tz.TZDateTime;
              final String label = reminderData['label'];
              final String mealTime = reminderData['mealTime'];

              if (reminderTime.isAfter(now)) {
                await _scheduleLocalNotification(
                  id: notifId++,
                  title: "💊 Medicine Reminder",
                  body:
                  "$label ($mealTime)\n${med['medicine_name']} - ${med['dosage']}\n${summary['hospital']}",
                  scheduledTime: reminderTime,
                  medicineName: med['medicine_name'],
                );
                scheduledCount++;

                // track earliest
                if (earliest == null || reminderTime.isBefore(earliest!)) {
                  earliest = reminderTime;
                  _demoMedName = med['medicine_name'] ?? "";
                  _demoDosage = med['dosage'] ?? "";
                  _demoLabel = label;
                  _demoMealTime = mealTime;

                }

                final Duration timeUntil = reminderTime.difference(now);
                // 🔁 Switched to seconds for your logs
                final String timeDesc = timeUntil.inSeconds >= 0
                    ? "in ${timeUntil.inSeconds} seconds"
                    : "now";

                debugPrint(
                  "  ✅ $label at $mealTime → ${DateFormat('yyyy-MM-dd HH:mm').format(reminderTime)} ($timeDesc)",
                );
              } else {
                debugPrint(
                  "  ⏭ $label: Time in past (${DateFormat('HH:mm').format(reminderTime)})",
                );
              }
            }
          }
        } else {
          debugPrint("  ⚠ Missing reminder data");
        }
        debugPrint("");
      }
    }

    // Set demo-mirror target
    _nextDueDemoAt = earliest;
    _demoFiredForNext = false;
    if (_nextDueDemoAt != null) {
      debugPrint("🎯 Next demo mirror scheduled for: $_nextDueDemoAt "
          "(${DateFormat('yyyy-MM-dd HH:mm:ss').format(_nextDueDemoAt!)})");
      _startSecondsCountdown(_nextDueDemoAt!); // 🔥 start 1s countdown
    } else {
      debugPrint("ℹ️ No future reminders found for demo mirror.");
      _stopCountdown();
    }

    debugPrint("========================================");
    debugPrint("✅ TOTAL NOTIFICATIONS SCHEDULED: $scheduledCount");
    debugPrint("========================================\n");

    if (!mounted) return;

    if (scheduledCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "⚠ No upcoming reminders. Check if meal timings and medicines are set.",
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ $scheduledCount medicine reminders scheduled successfully",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Schedules a single local notification at an absolute tz time
  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required String medicineName,
  }) async {
    try {
      debugPrint("\n📤 Scheduling notification ID: $id");
      debugPrint(
          "   Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(scheduledTime)}");

      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'medicine_reminder_channel',
        'Medicine Reminders',
        channelDescription: 'Notifications to remind you to take your medicines',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        channelShowBadge: true,
        ticker: 'Medicine Reminder',
        styleInformation: BigTextStyleInformation(''),
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // sound: 'notification.mp3',
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint("   ✅ Successfully scheduled!");
    } catch (e, stackTrace) {
      debugPrint("❌ Error scheduling notification ID $id: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  // ========= DEMO MIRROR LOGIC (seconds countdown) =========

  void _startSecondsCountdown(tz.TZDateTime target) {
    _countdownTimer?.cancel();

    void tick() {
      final now = tz.TZDateTime.now(tz.local);
      _secondsLeft = target.difference(now).inSeconds;

      if (_secondsLeft <= 0) {
        _secondsLeft = 0;
        _countdownTimer?.cancel();
        if (!_demoFiredForNext) {
          debugPrint("🎆 Demo mirror firing at $now (for $target)");
          _fireDemoNow();
          _demoFiredForNext = true;
        }
      }
      if (mounted) setState(() {});
    }

    // Prime once and then tick each second
    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _secondsLeft = 0;
    if (mounted) setState(() {});
  }

  Future<void> _fireDemoNow() async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'demo_channel',
      'Demo Notifications',
      channelDescription: 'Demo notifications fired at due time',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      // iOS: add if needed
    );

    await flutterLocalNotificationsPlugin.show(
      8888,
      "🔔 Medicine Reminder",
      "${_demoLabel} ($_demoMealTime)\nTake $_demoMedName – $_demoDosage",
      details,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔔 Demo notification fired at due time"),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Manual demo trigger (button)
  Future<void> _demoNowButton() async {
    await _fireDemoNow();
  }

  // =====================================

  Future<void> _toggleGlobalReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    patientId = prefs.getInt('patient_id');
    final ip = prefs.getString('ipAddress') ?? 'http://127.0.0.1:8000';
    final url = Uri.parse(
      '${ip.startsWith('http') ? ip : 'http://$ip'}/set_patient_reminder_status/',
    );
    final resp = await http.post(
      url,
      body: {'patient_id': '$patientId', 'is_on': value.toString()},
    );
    if (resp.statusCode == 200) {
      setState(() {
        remindersOn = value;
        isLoading = true;
      });
      await _loadStatusAndReminders();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update reminder status"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    debugPrint("\n🧪 ========== TEST NOTIFICATION ==========");
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime testTime = now.add(const Duration(seconds: 10));
    final String formattedTime = DateFormat('hh:mm:ss a').format(testTime);

    debugPrint("Current time: $now");
    debugPrint("Scheduled time: $testTime");
    debugPrint("Formatted: $formattedTime");

    await _scheduleLocalNotification(
      id: 9999,
      title: "🧪 Test Notification",
      body: "This is a test notification (default sound).",
      scheduledTime: testTime,
      medicineName: "Test",
    );

    // Immediate popup (helps confirm channel & permissions visually)
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'medicine_reminder_channel',
      'Medicine Reminders',
      channelDescription:
      'Notifications to remind you to take your medicines',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      9998,
      "🔔 Immediate Test",
      "This notification appears immediately.",
      notificationDetails,
    );
    debugPrint("✅ Immediate notification sent");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🧪 Test scheduled for $formattedTime\n✅ Check lock screen in ~10s",
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    debugPrint("🧪 Test notification scheduled for: $formattedTime");
    debugPrint("========================================\n");
  }

  Future<void> _showPendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotifications =
    await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    debugPrint("\n📬 Pending Notifications: ${pendingNotifications.length}");
    for (var notif in pendingNotifications) {
      debugPrint("  - ID: ${notif.id}, Title: ${notif.title}");
    }

    if (!mounted) return;

    if (pendingNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📭 No pending notifications"),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            "📬 Pending Notifications (${pendingNotifications.length})",
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: pendingNotifications.length,
              itemBuilder: (context, index) {
                final notif = pendingNotifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text("${index + 1}"),
                    ),
                    title: Text(
                      notif.title ?? "No title",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      notif.body ?? "No body",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      "ID: ${notif.id}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _refreshReminders() async {
    setState(() => isLoading = true);
    await _loadStatusAndReminders();
  }

  @override
  Widget build(BuildContext context) {
    final String nextAtStr = _nextDueDemoAt == null
        ? "-"
        : DateFormat('yyyy-MM-dd hh:mm:ss a')
        .format(_nextDueDemoAt!.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medicine Reminders"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReminders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReminders,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Container(
              color: Colors.teal.shade50,
              padding: const EdgeInsets.symmetric(
                vertical: 18.0,
                horizontal: 16,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Medicine Reminders",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Switch(
                        value: remindersOn,
                        onChanged: _toggleGlobalReminder,
                        activeColor: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // ElevatedButton.icon(
                      //   onPressed: _testNotification,
                      //   icon: const Icon(Icons.science, size: 18),
                      //   label: const Text("Test (10s)"),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.orange,
                      //     foregroundColor: Colors.white,
                      //   ),
                      // ),
                      ElevatedButton.icon(
                        onPressed: _showPendingNotifications,
                        icon: const Icon(Icons.list, size: 18),
                        label: const Text("View Pending"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      // ElevatedButton.icon(
                      //   onPressed: _demoNowButton,
                      //   icon: const Icon(Icons.flash_on, size: 18),
                      //   label: const Text("Demo Now"),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.purple,
                      //     foregroundColor: Colors.white,
                      //   ),
                      // ),
                    ],
                  ),

                  // // 🔥 COUNTDOWN PANEL
                  // if (_nextDueDemoAt != null)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 12),
                  //     child: Container(
                  //       padding: const EdgeInsets.all(10),
                  //       decoration: BoxDecoration(
                  //         color: Colors.white,
                  //         borderRadius: BorderRadius.circular(8),
                  //         border:
                  //         Border.all(color: Colors.teal.shade200),
                  //       ),
                  //       child: Column(
                  //         children: [
                  //           const Text(
                  //             "Next reminder in:",
                  //             style: TextStyle(
                  //               fontWeight: FontWeight.bold,
                  //               fontSize: 13,
                  //             ),
                  //           ),
                  //           const SizedBox(height: 6),
                  //           Text(
                  //             "$_secondsLeft seconds",
                  //             style: const TextStyle(
                  //               fontSize: 24,
                  //               color: Colors.red,
                  //               fontWeight: FontWeight.bold,
                  //             ),
                  //           ),
                  //           const SizedBox(height: 4),
                  //           Text(
                  //             "Fire at: $nextAtStr",
                  //             style: const TextStyle(
                  //               fontSize: 12,
                  //               color: Colors.black54,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),

                  if (foodTimings.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border:
                          Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Your Meal Times:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                              children: foodTimings.entries.map((e) {
                                String time =
                                e.value.split(':').take(2).join(':');
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.restaurant,
                                      size: 14,
                                      color: Colors.teal,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${e.key.capitalize()}: $time",
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_nextDueDemoAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Next demo fire at: ${DateFormat('yyyy-MM-dd hh:mm a').format(_nextDueDemoAt!.toLocal())}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: summaries.isEmpty
                  ? ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No medicine reminders.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Pull down to refresh",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: summaries.length,
                itemBuilder: (_, i) {
                  final s = summaries[i];
                  final List medList = s['medicines'] ?? [];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_hospital,
                                color: Colors.teal[400],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${s['hospital']} | Discharge: ${s['discharge_date']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          medList.isEmpty
                              ? const Center(
                            child: Text("No medicines."),
                          )
                              : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor:
                              MaterialStateProperty.all(
                                Colors.teal[50],
                              ),
                              columnSpacing: 18,
                              columns: const [
                                DataColumn(
                                  label: Text("Medicine"),
                                ),
                                DataColumn(
                                  label: Text("Dosage"),
                                ),
                                DataColumn(
                                  label: Text("When to Take"),
                                ),
                                DataColumn(
                                  label: Text("Duration"),
                                ),
                              ],
                              rows: List.generate(
                                medList.length,
                                    (j) {
                                  final m = medList[j];
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          m["medicine_name"] ??
                                              "-",
                                          style:
                                          const TextStyle(
                                            fontWeight:
                                            FontWeight
                                                .w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          m["dosage"] ?? "-",
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          m["frequency"] ??
                                              "-",
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          "${m["duration"] ?? "-"} days",
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
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
      ),
      backgroundColor: const Color(0xfff7fdfc),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}
