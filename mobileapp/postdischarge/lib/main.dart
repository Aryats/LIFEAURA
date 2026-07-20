import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyIpPage(),
    );
  }
}

class MyIpPage extends StatefulWidget {
  const MyIpPage({super.key});

  @override
  State<MyIpPage> createState() => _MyIpPageState();
}

class _MyIpPageState extends State<MyIpPage> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadIp();
  }

  Future<void> loadIp() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    ipController.text = sh.getString("ip") ?? "";
  }

  Future<void> saveIpAndNavigate() async {
    String ip = ipController.text.trim();

    SharedPreferences sh = await SharedPreferences.getInstance();
    await sh.setString("ip", ip);
    await sh.setString("url", "http://$ip:8000");
    await sh.setString("img_url", "http://$ip:8000");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyLogin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A1F44),
              Color(0xFF112D66),
              Colors.black,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.25),
                    blurRadius: 30,
                    spreadRadius: 3,
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    const Icon(Icons.cloud_done,
                        size: 80, color: Colors.blueAccent),

                    const SizedBox(height: 20),

                    const Text(
                      "SERVER CONNECTION",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 30),

                    TextFormField(
                      controller: ipController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon:
                        const Icon(Icons.public, color: Colors.blueAccent),
                        labelText: "IP Address",
                        labelStyle:
                        const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? "Enter IP Address"
                          : null,
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            saveIpAndNavigate();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                          elevation: 10,
                        ),
                        child: const Text(
                          "CONNECT",
                          style: TextStyle(
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
