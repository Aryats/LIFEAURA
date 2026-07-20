import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'RegisterScreen.dart';
import 'userhomescreen.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({Key? key}) : super(key: key);

  @override
  State<MyLogin> createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {

      SharedPreferences sh = await SharedPreferences.getInstance();
      String baseUrl = sh.getString('url') ?? 'http://10.0.2.2:8000';

      final response = await http.post(
        Uri.parse('$baseUrl/user_login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'ok') {

        await sh.setString('lid', data['lid'].toString());
        await sh.setString('pid', data['pid'].toString());
        await sh.setString('username', data['username'] ?? '');
        await sh.setString('name', data['name'] ?? '');
        await sh.setString('email', data['email'] ?? '');
        await sh.setString('profile_picture', data['profile_picture'] ?? '');
        await sh.setString('reward_points', data['reward_points'] ?? '0');
        await sh.setString('health_score', data['health_score'] ?? '0');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );

      } else {
        _showMessage(data['error'] ?? "Invalid Credentials", Colors.red);
      }

    } catch (e) {
      _showMessage("Server Error: $e", Colors.red);
    }

    setState(() => _isLoading = false);
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              'assets/loginpage.jpg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.blueAccent.withOpacity(0.3),
                      blurRadius: 30,
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      const Icon(Icons.lock_outline,
                          size: 80,
                          color: Colors.blueAccent),

                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _usernameController,
                        label: "Username",
                        icon: Icons.person,
                      ),

                      const SizedBox(height: 18),

                      _buildPasswordField(),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                          _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                            elevation: 10,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : const Text(
                            "LOGIN",
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(
                              color: Colors.white70),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon:
        Icon(icon, color: Colors.blueAccent),
        labelText: label,
        labelStyle:
        const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      validator: (value) =>
      value == null || value.isEmpty
          ? "Enter $label"
          : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon:
        const Icon(Icons.lock, color: Colors.blueAccent),
        labelText: "Password",
        labelStyle:
        const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() =>
            _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator: (value) =>
      value == null || value.isEmpty
          ? "Enter Password"
          : null,
    );
  }
}
