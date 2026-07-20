
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'CreateBroadcastBloodRequestPage.dart';
import 'ViewBroadcastBloodRequestsPage.dart';
import 'accepted_users_page.dart';
import 'meal_time.dart';
import 'received_requests_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'blood_bank_list.dart';
import 'main.dart';
import 'matching_users.dart';
import 'medicine_reminder.dart';
import 'my_requests_page.dart';
import 'profile.dart';
import 'login.dart';
import 'insert_vital.dart';
import 'chatbot.dart';
import 'calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name = "";
  String username = "";
  String profilePicture = "";
  int healthScore = 0;
  int rewardPoints = 0;
  bool isLoading = true;

  // ================= MEDICINE REMINDER VARIABLES =================
  List<Map<String, dynamic>> upcomingMedicines = [];
  String nextMedicineName = "";
  String nextMedicineTime = "";
  Duration timeUntilNextReminder = Duration.zero;
  Timer? _reminderTimer;
  Timer? _refreshTimer;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Track notified medicines
  Set<int> notifiedMedicineIds = {};

  // Track if notifications are initialized
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    startAutoRefresh();
    _initializeNotifications();
    fetchUpcomingMedicines();
    startReminderCountdown();
  }

  // ================= INITIALIZE NOTIFICATIONS =================
  Future<void> _initializeNotifications() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      // Create notification channel - corrected for v17.2.4
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'medicine_channel', // id
        'Medicine Reminders', // title
        description: 'Channel for Medicine Reminders', // description
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Request permissions for Android 13+ - corrected method
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        // Note: requestPermission() doesn't exist, use requestNotificationsPermission() instead
      }

      setState(() {
        _notificationsInitialized = true;
      });

      debugPrint("Notifications initialized successfully");
    } catch (e) {
      debugPrint("Error initializing notifications: $e");
    }
  }

  // ================= SHOW NOTIFICATION =================
  Future<void> showNotification(String medicineName, String timeOfDay) async {
    if (!_notificationsInitialized) {
      debugPrint("Notifications not initialized yet");
      return;
    }

    try {
      // Create a unique ID for each notification
      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Corrected AndroidNotificationDetails for v17.2.4
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'medicine_channel',
        'Medicine Reminders',
        channelDescription: 'Channel for Medicine Reminders',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.blue,
        ledOnMs: 1000,
        ledOffMs: 500,
        showWhen: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        color: Colors.blue,
      );

      // Corrected DarwinNotificationDetails for v17.2.4
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
        sound: 'default.wav',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        notificationId,
        '💊 Medicine Reminder',
        'Time to take $medicineName ($timeOfDay)',
        platformChannelSpecifics,
        payload: 'medicine_$medicineName',
      );

      debugPrint("✅ Notification shown for: $medicineName at ${DateTime.now()}");
    } catch (e) {
      debugPrint("❌ Error showing notification: $e");
    }
  }

  // ================= SCHEDULE NOTIFICATION =================
  Future<void> scheduleNotification(String medicineName, String timeOfDay, DateTime scheduledTime) async {
    if (!_notificationsInitialized) return;

    try {
      int notificationId = scheduledTime.millisecondsSinceEpoch ~/ 1000;

      // Corrected scheduled notification for v17.2.4
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '💊 Medicine Reminder',
        'Time to take $medicineName ($timeOfDay)',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_channel',
            'Medicine Reminders',
            channelDescription: 'Channel for Medicine Reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            enableLights: true,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint("✅ Notification scheduled for: $medicineName at $scheduledTime");
    } catch (e) {
      debugPrint("❌ Error scheduling notification: $e");
    }
  }

  // ================= FETCH UPCOMING MEDICINES =================
  Future<void> fetchUpcomingMedicines() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String baseUrl = sh.getString("url") ?? "http://10.0.2.2:8000";
      String? lid = sh.getString("lid");

      if (lid == null) return;

      final response = await http.post(
        Uri.parse("$baseUrl/get_upcoming_medicines/"),
        body: {
          "lid": lid,
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok" && mounted) {
        List<dynamic> medicines = data["medicines"];

        setState(() {
          upcomingMedicines = medicines.map((medicine) => {
            'id': medicine['id'],
            'medicine_name': medicine['medicine_name'],
            'time_of_day': medicine['time_of_day'],
            'food_relation': medicine['food_relation'],
            'next_reminder': medicine['next_reminder'],
          }).toList();

          // Set next reminder info
          if (upcomingMedicines.isNotEmpty) {
            nextMedicineName = upcomingMedicines[0]['medicine_name'];
            nextMedicineTime = _formatReminderTime(upcomingMedicines[0]['next_reminder']);
            _calculateTimeUntilNextReminder(upcomingMedicines[0]['next_reminder']);
          }
        });

        // Check and trigger notifications
        _checkAndTriggerNotifications(medicines);

        // Schedule future notifications
        _scheduleFutureNotifications(medicines);
      }
    } catch (e) {
      debugPrint("Medicine Fetch Error: $e");
    }
  }

  // ================= SCHEDULE FUTURE NOTIFICATIONS =================
  void _scheduleFutureNotifications(List<dynamic> medicines) {
    DateTime now = DateTime.now();

    for (var medicine in medicines) {
      if (medicine['next_reminder'] != null) {
        int medicineId = medicine['id'];
        DateTime reminderTime = DateTime.parse(medicine['next_reminder']);

        // Schedule for future reminders (more than 1 minute away)
        if (reminderTime.isAfter(now) &&
            reminderTime.difference(now).inMinutes > 1 &&
            !notifiedMedicineIds.contains(medicineId)) {

          scheduleNotification(
            medicine['medicine_name'],
            medicine['time_of_day'],
            reminderTime,
          );
        }
      }
    }
  }

  // ================= CHECK AND TRIGGER NOTIFICATIONS =================
  void _checkAndTriggerNotifications(List<dynamic> medicines) {
    DateTime now = DateTime.now();

    for (var medicine in medicines) {
      if (medicine['next_reminder'] != null) {
        int medicineId = medicine['id'];
        DateTime reminderTime = DateTime.parse(medicine['next_reminder']);

        // Calculate time difference
        Duration difference = now.difference(reminderTime);

        // Check if it's time for notification (within last 2 minutes)
        if (!notifiedMedicineIds.contains(medicineId)) {
          // If reminder time has passed (within last 2 minutes)
          if (reminderTime.isBefore(now) && difference.inMinutes < 2) {
            // Show notification immediately
            showNotification(
                medicine['medicine_name'],
                medicine['time_of_day']
            );

            // Mark as notified
            setState(() {
              notifiedMedicineIds.add(medicineId);
            });

            debugPrint("✅ Notification triggered for medicine ID: $medicineId at ${DateTime.now()}");

            // Clear from notified set after 2 hours
            Future.delayed(const Duration(hours: 2), () {
              if (mounted) {
                setState(() {
                  notifiedMedicineIds.remove(medicineId);
                });
              }
            });
          }
        }
      }
    }
  }

  // ================= CALCULATE TIME UNTIL NEXT REMINDER =================
  void _calculateTimeUntilNextReminder(String? nextReminderTime) {
    if (nextReminderTime == null) {
      timeUntilNextReminder = Duration.zero;
      return;
    }

    try {
      DateTime nextTime = DateTime.parse(nextReminderTime);
      DateTime now = DateTime.now();

      if (nextTime.isAfter(now)) {
        timeUntilNextReminder = nextTime.difference(now);
      } else {
        timeUntilNextReminder = Duration.zero;
      }
    } catch (e) {
      timeUntilNextReminder = Duration.zero;
    }
  }

  // ================= FORMAT REMINDER TIME =================
  String _formatReminderTime(String? timeString) {
    if (timeString == null) return "No upcoming reminders";

    try {
      DateTime time = DateTime.parse(timeString);
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Invalid time";
    }
  }

  // ================= FORMAT COUNTDOWN =================
  String _formatCountdown(Duration duration) {
    if (duration.inSeconds <= 0) {
      return "🔔 Time to take medicine!";
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    return "$hours:$minutes:$seconds";
  }

  // ================= START COUNTDOWN TIMER =================
  void startReminderCountdown() {
    _reminderTimer?.cancel();

    _reminderTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (upcomingMedicines.isNotEmpty && mounted) {
        setState(() {
          _calculateTimeUntilNextReminder(upcomingMedicines[0]['next_reminder']);

          // When countdown reaches zero, trigger notification
          if (timeUntilNextReminder.inSeconds <= 1) {
            _checkForDueReminders();
          }
        });
      }
    });
  }

  // ================= CHECK FOR DUE REMINDERS =================
  void _checkForDueReminders() {
    DateTime now = DateTime.now();

    for (var medicine in upcomingMedicines) {
      int medicineId = medicine['id'];
      if (medicine['next_reminder'] != null && !notifiedMedicineIds.contains(medicineId)) {
        DateTime reminderTime = DateTime.parse(medicine['next_reminder']);

        // If reminder time is within last 1 minute
        if (reminderTime.isBefore(now) &&
            now.difference(reminderTime).inSeconds < 60) {

          showNotification(
              medicine['medicine_name'],
              medicine['time_of_day']
          );

          setState(() {
            notifiedMedicineIds.add(medicineId);
          });

          // Clear after 2 hours
          Future.delayed(const Duration(hours: 2), () {
            if (mounted) {
              setState(() {
                notifiedMedicineIds.remove(medicineId);
              });
            }
          });
        }
      }
    }
  }

  // ================= AUTO REFRESH =================
  void startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
          (timer) {
        fetchUserProfile();
        fetchUpcomingMedicines();
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _reminderTimer?.cancel();
    super.dispose();
  }

  // ================= FETCH USER PROFILE =================
  Future<void> fetchUserProfile() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String baseUrl = sh.getString("url") ?? "http://10.0.2.2:8000";
      String? lid = sh.getString("lid");

      if (lid == null) return;

      final response = await http.post(
        Uri.parse("$baseUrl/user_profile/"),
        body: {
          "lid": lid,
          "action": "view",
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "ok" && mounted) {
        setState(() {
          name = data["name"] ?? "";
          username = data["username"] ?? "";
          profilePicture = data["profile_picture"] ?? "";
          healthScore = int.tryParse(data["health_score"] ?? "0") ?? 0;
          rewardPoints = int.tryParse(data["reward_points"] ?? "0") ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Home Fetch Error: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ================= LOGOUT =================
  Future<void> _logout() async {
    _refreshTimer?.cancel();
    _reminderTimer?.cancel();

    SharedPreferences sh = await SharedPreferences.getInstance();
    await sh.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MyIpPage()),
          (route) => false,
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F7),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 3,
        title: const Text(
          "LifeAura Dashboard",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      drawer: _buildDrawer(context),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 20),

            // Medicine Reminder Card
            if (upcomingMedicines.isNotEmpty)
              _buildMedicineReminderCard(),
            if (upcomingMedicines.isNotEmpty)
              const SizedBox(height: 20),

            _buildInfoCard(
              title: "Health Score",
              value: "$healthScore%",
              icon: Icons.favorite,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 16),

            _buildInfoCard(
              title: "Blood Donation Points",
              value: rewardPoints.toString(),
              icon: Icons.bloodtype,
              color: Colors.deepPurple,
            ),

            const SizedBox(height: 25),

            _buildCalendarCard(),
          ],
        ),
      ),
    );
  }

  // ================= MEDICINE REMINDER CARD =================
  Widget _buildMedicineReminderCard() {
    return Card(
      elevation: 6,
      shadowColor: Colors.blue.withOpacity(0.4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0288D1),
              Color(0xFF4FC3F7),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medication, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  "Next Medicine Reminder",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Medicine:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        nextMedicineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Time:",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        nextMedicineTime,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (timeUntilNextReminder.inSeconds > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Countdown:",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          _formatCountdown(timeUntilNextReminder),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellowAccent,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.notifications_active, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "🔔 Time to take medicine!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Show upcoming medicines list
            if (upcomingMedicines.length > 1) ...[
              const Divider(color: Colors.white30),
              const SizedBox(height: 5),
              const Text(
                "Upcoming Today:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 5),
              ...List.generate(
                upcomingMedicines.length > 3 ? 3 : upcomingMedicines.length - 1,
                    (index) {
                  final med = upcomingMedicines[index + 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.white70),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            "${med['medicine_name']} - ${_formatReminderTime(med['next_reminder'])}",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================= PROFILE CARD =================
  Widget _buildProfileCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF66BB6A),
            ],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              backgroundImage: profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture)
                  : null,
              child: profilePicture.isEmpty
                  ? const Icon(Icons.person,
                  size: 40,
                  color: Color(0xFF2E7D32))
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INFO CARD =================
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= CALENDAR CARD =================
  Widget _buildCalendarCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CalendarPage()),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3949AB),
                Color(0xFF5C6BC0),
              ],
            ),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.calendar_month,
                  size: 30,
                  color: Color(0xFF3949AB),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  "Event Calendar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DRAWER =================
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: profilePicture.isNotEmpty
                  ? NetworkImage(profilePicture)
                  : null,
              child: profilePicture.isEmpty
                  ? const Icon(Icons.person, size: 35)
                  : null,
            ),
            accountName: Text(name),
            accountEmail: Text(username),
          ),

          _drawerTile(Icons.person, "Profile",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const UserProfilePage()),
              )),

          _drawerTile(Icons.add_alarm, "Insert Vitals",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const vitals()),
              )),

          _drawerTile(Icons.food_bank_outlined, "Add Food Time",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const meal_time()),
              )),

          _drawerTile(Icons.smart_toy_outlined,
              "AI Chatbot",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const ChatBotPage()),
              )),
          //
          // _drawerTile(Icons.calendar_month, "Event Calendar",
          //         () => Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //           builder: (_) =>
          //           const CalendarPage()),
          //     )),

          _drawerTile(Icons.bloodtype_outlined, "View Organisation",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const BloodBankListPage()),
              )),

          _drawerTile(Icons.request_page, "View Requests",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const MyRequestsPage()),
              )),

          _drawerTile(Icons.person_add_alt_sharp, "Send Request",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const CreateBroadcastBloodRequestPage()),
              )),

          _drawerTile(Icons.call_received_sharp, "View Received Requests",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const ViewBroadcastBloodRequestsPage()),
              )),

          _drawerTile(Icons.verified_user, "View Accepted Users",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const AcceptedUsersPage()),
              )),

          _drawerTile(Icons.remember_me, "Medicine reminder",
                  () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const PrescriptionPage()),
              )),

          const Spacer(),

          _drawerTile(Icons.logout, "Logout",
              _logout,
              iconColor: Colors.red),
        ],
      ),
    );
  }

  Widget _drawerTile(
      IconData icon,
      String title,
      VoidCallback onTap,
      {Color iconColor = const Color(0xFF1B5E20)}) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}