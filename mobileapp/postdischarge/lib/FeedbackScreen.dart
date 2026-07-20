// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'dart:convert';
// import 'user_home.dart';
// import 'view_profile.dart';
// import 'complaint.dart';
// import 'login.dart';
//
// class FeedbackScreen extends StatefulWidget {
//   const FeedbackScreen({super.key});
//
//   @override
//   State<FeedbackScreen> createState() => _FeedbackScreenState();
// }
//
// class _FeedbackScreenState extends State<FeedbackScreen> {
//   final TextEditingController _feedbackController = TextEditingController();
//   List<Map<String, dynamic>> _feedbacks = [];
//   bool _isLoading = false;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   String userName = '';
//   String userEmail = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     _fetchFeedback();
//   }
//
//   Future<void> _loadUserData() async {
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     setState(() {
//       userName = sh.getString('user_name') ?? 'User';
//       userEmail = sh.getString('user_email') ?? '';
//     });
//   }
//
//   Future<Map<String, String>> _getAuthHeaders() async {
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     String? csrfToken = sh.getString('csrftoken');
//     String? sessionId = sh.getString('sessionid');
//
//     Map<String, String> headers = {
//       'Content-Type': 'application/json',
//     };
//
//     if (csrfToken != null) {
//       headers['X-CSRFToken'] = csrfToken;
//     }
//
//     String cookie = '';
//     if (sessionId != null) {
//       cookie = 'sessionid=$sessionId';
//     }
//     if (csrfToken != null) {
//       cookie += cookie.isNotEmpty ? '; csrftoken=$csrfToken' : 'csrftoken=$csrfToken';
//     }
//     if (cookie.isNotEmpty) {
//       headers['Cookie'] = cookie;
//     }
//
//     return headers;
//   }
//
//   Future<void> _fetchFeedback() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       SharedPreferences sh = await SharedPreferences.getInstance();
//       String url = sh.getString('url') ?? 'http://10.0.2.2:8000';
//       final headers = await _getAuthHeaders();
//       final response = await http.get(
//         Uri.parse('$url/feedback/'),
//         headers: headers,
//       ).timeout(const Duration(seconds: 10));
//
//       print('Fetch Feedback Status: ${response.statusCode}');
//       print('Fetch Feedback Response: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         if (jsonResponse['status'] == 'success') {
//           setState(() {
//             _feedbacks = List<Map<String, dynamic>>.from(jsonResponse['data']);
//           });
//         } else {
//           Fluttertoast.showToast(
//             msg: jsonResponse['message']?.toString() ?? 'Failed to fetch feedback',
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.red,
//             textColor: Colors.white,
//           );
//         }
//       } else if (response.statusCode == 401) {
//         Fluttertoast.showToast(
//           msg: 'Session expired. Please login again.',
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//         );
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const MyLogin()),
//               (route) => false,
//         );
//       } else {
//         Fluttertoast.showToast(
//           msg: 'Failed to fetch feedback: HTTP ${response.statusCode}',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//         );
//       }
//     } catch (e) {
//       print('Fetch Feedback Error: $e');
//       Fluttertoast.showToast(
//         msg: 'Network error: ${e.toString()}',
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _submitFeedback() async {
//     final feedbackText = _feedbackController.text.trim();
//     if (feedbackText.isEmpty) {
//       Fluttertoast.showToast(
//         msg: 'Please enter feedback',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//       return;
//     }
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       SharedPreferences sh = await SharedPreferences.getInstance();
//       String url = sh.getString('url') ?? 'http://10.0.2.2:8000';
//       final headers = await _getAuthHeaders();
//       final response = await http.post(
//         Uri.parse('$url/feedback/'),
//         headers: headers,
//         body: jsonEncode({'feedback': feedbackText}),
//       ).timeout(const Duration(seconds: 10));
//
//       print('Submit Feedback Status: ${response.statusCode}');
//       print('Submit Feedback Response: ${response.body}');
//
//       if (response.statusCode == 201) {
//         final jsonResponse = jsonDecode(response.body);
//         Fluttertoast.showToast(
//           msg: jsonResponse['message']?.toString() ?? 'Feedback submitted successfully',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.green,
//           textColor: Colors.white,
//         );
//         _feedbackController.clear();
//         await _fetchFeedback();
//       } else if (response.statusCode == 401) {
//         Fluttertoast.showToast(
//           msg: 'Session expired. Please login again.',
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//         );
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const MyLogin()),
//               (route) => false,
//         );
//       } else {
//         Fluttertoast.showToast(
//           msg: 'Failed to submit feedback: HTTP ${response.statusCode}',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//         );
//       }
//     } catch (e) {
//       print('Submit Feedback Error: $e');
//       Fluttertoast.showToast(
//         msg: 'Network error: ${e.toString()}',
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _logout(BuildContext context) async {
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     await sh.remove('lid');
//     await sh.remove('user_name');
//     await sh.remove('sessionid');
//     await sh.remove('csrftoken');
//
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) => const MyLogin()),
//           (route) => false,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         Navigator.pop(context);
//         return true;
//       },
//       child: Scaffold(
//         key: _scaffoldKey,
//         appBar: AppBar(
//           title: const Text(
//             'Feedback',
//             style: TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//           ),
//           backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () {
//               Navigator.pop(context);
//             },
//           ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.menu, color: Colors.white),
//               onPressed: () {
//                 _scaffoldKey.currentState?.openEndDrawer();
//               },
//             ),
//           ],
//         ),
//         endDrawer: Drawer(
//           backgroundColor: Colors.black,
//           child: ListView(
//             padding: EdgeInsets.zero,
//             children: [
//               DrawerHeader(
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.inversePrimary,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     CircleAvatar(
//                       radius: 30,
//                       backgroundColor: Colors.white,
//                       child: Text(
//                         userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
//                         style: const TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.deepPurple,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       userName,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         fontFamily: 'Roboto',
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Text(
//                       userEmail,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         color: Colors.white70,
//                         fontFamily: 'Roboto',
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.home, color: Colors.white, size: 28),
//                 title: const Text(
//                   'Home',
//                   style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Roboto'),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const UserHomeScreen(title: 'Home')),
//                   );
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.person, color: Colors.white, size: 28),
//                 title: const Text(
//                   'View Profile',
//                   style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Roboto'),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const ViewProfileScreen()),
//                   );
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.report_problem, color: Colors.white, size: 28),
//                 title: const Text(
//                   'Complaints',
//                   style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Roboto'),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const ComplaintScreen()),
//                   );
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.feedback, color: Colors.white, size: 28),
//                 title: const Text(
//                   'Feedback',
//                   style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Roboto'),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => const FeedbackScreen()),
//                   );
//                 },
//               ),
//               const Divider(color: Colors.white54),
//               ListTile(
//                 leading: const Icon(Icons.logout, color: Colors.white, size: 28),
//                 title: const Text(
//                   'Logout',
//                   style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Roboto'),
//                 ),
//                 onTap: () => _logout(context),
//               ),
//             ],
//           ),
//         ),
//         body: Stack(
//           children: [
//             Image.asset(
//               'assets/bg.png',
//               fit: BoxFit.cover,
//               width: double.infinity,
//               height: double.infinity,
//             ),
//             Container(
//               color: Colors.black.withOpacity(0.3),
//               width: double.infinity,
//               height: double.infinity,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   TextField(
//                     controller: _feedbackController,
//                     style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                     decoration: InputDecoration(
//                       labelText: 'Enter your feedback',
//                       labelStyle: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                       filled: true,
//                       fillColor: Colors.black.withOpacity(0.4),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Colors.white54),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Colors.white54),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: const BorderSide(color: Colors.white, width: 2),
//                       ),
//                     ),
//                     maxLines: 4,
//                   ),
//                   const SizedBox(height: 16),
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Theme.of(context).colorScheme.primary,
//                           Theme.of(context).colorScheme.primary.withOpacity(0.8),
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.2),
//                           spreadRadius: 2,
//                           blurRadius: 8,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: ElevatedButton(
//                       onPressed: _isLoading ? null : _submitFeedback,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: _isLoading
//                           ? const SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       )
//                           : const Text(
//                         'Submit Feedback',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           fontFamily: 'Roboto',
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Your Feedback:',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       color: Colors.white,
//                       fontFamily: 'Roboto',
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Expanded(
//                     child: _isLoading
//                         ? const Center(child: CircularProgressIndicator(color: Colors.white))
//                         : _feedbacks.isEmpty
//                         ? const Center(
//                       child: Text(
//                         'No feedback found',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.white,
//                           fontFamily: 'Roboto',
//                         ),
//                       ),
//                     )
//                         : ListView.builder(
//                       itemCount: _feedbacks.length,
//                       itemBuilder: (context, index) {
//                         final feedback = _feedbacks[index];
//                         return Card(
//                           color: Colors.black.withOpacity(0.4),
//                           margin: const EdgeInsets.symmetric(vertical: 8),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Feedback: ${feedback['feedback']}',
//                                   style: const TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                     fontFamily: 'Roboto',
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   'Date: ${feedback['date']}',
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.white70,
//                                     fontFamily: 'Roboto',
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _feedbackController.dispose();
//     super.dispose();
//   }
// }