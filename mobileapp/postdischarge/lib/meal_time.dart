import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class meal_time extends StatefulWidget {
  const meal_time({super.key});

  @override
  State<meal_time> createState() => _meal_timeState();
}

class _meal_timeState extends State<meal_time>
    with SingleTickerProviderStateMixin {

  final TextEditingController breakfastController = TextEditingController();
  final TextEditingController lunchController = TextEditingController();
  final TextEditingController dinnerController = TextEditingController();

  bool isLoading = false;
  bool isFetching = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    fetchMealTime();
  }

  Future<void> fetchMealTime() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String baseUrl = sh.getString("url") ?? "http://10.0.2.2:8000";
    String? lid = sh.getString("lid");

    var response = await http.post(
      Uri.parse("$baseUrl/view_meal_time/"),
      body: {"lid": lid ?? ""},
    );

    var data = jsonDecode(response.body);

    if (data["status"] == "ok") {
      breakfastController.text = data["breakfast_time"];
      lunchController.text = data["lunch_time"];
      dinnerController.text = data["dinner_time"];
    }

    setState(() => isFetching = false);
    _animationController.forward();
  }

  Future<void> pickTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      controller.text =
      "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
    }
  }

  Future<void> submitMealTime() async {

    if (breakfastController.text.isEmpty ||
        lunchController.text.isEmpty ||
        dinnerController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select all meal times")),
      );
      return;
    }

    setState(() => isLoading = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String baseUrl = sh.getString("url") ?? "http://10.0.2.2:8000";
    String? lid = sh.getString("lid");

    var response = await http.post(
      Uri.parse("$baseUrl/add_meal_time/"),
      body: {
        "lid": lid ?? "",
        "breakfast_time": breakfastController.text,
        "lunch_time": lunchController.text,
        "dinner_time": dinnerController.text,
      },
    );

    var data = jsonDecode(response.body);

    setState(() => isLoading = false);

    if (data["status"] == "ok") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Meal Time Saved Successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["message"] ?? "Error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: isFetching
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [

          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF43A047),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [

                  // Top Curved Header
                  ClipPath(
                    clipper: CurvedClipper(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      color: Colors.white.withOpacity(0.15),
                      child: const Column(
                        children: [
                          Icon(Icons.restaurant_menu,
                              size: 60,
                              color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            "Your Meal Schedule",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        children: [

                          buildTimeCard(
                              breakfastController,
                              "Breakfast",
                              Icons.free_breakfast),

                          const SizedBox(height: 20),

                          buildTimeCard(
                              lunchController,
                              "Lunch",
                              Icons.lunch_dining),

                          const SizedBox(height: 20),

                          buildTimeCard(
                              dinnerController,
                              "Dinner",
                              Icons.dinner_dining),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : submitMealTime,
                              style: ElevatedButton.styleFrom(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Ink(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF66BB6A),
                                      Color(0xFF2E7D32)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(30)),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Save Meal Time",
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                    color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTimeCard(
      TextEditingController controller,
      String title,
      IconData icon) {

    return GestureDetector(
      onTap: () => pickTime(controller),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [

            Icon(icon,
                size: 35,
                color: const Color(0xFF2E7D32)),

            const SizedBox(width: 20),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),

            Text(
              controller.text.isEmpty
                  ? "Select"
                  : controller.text,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20)),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height,
        size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
