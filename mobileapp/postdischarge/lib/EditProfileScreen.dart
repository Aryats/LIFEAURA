// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:file_picker/file_picker.dart';
// import 'user_home.dart';
// import 'view_profile.dart';
// import 'complaint.dart';
// import 'feedback.dart';
// import 'login.dart';
//
// class EditProfileScreen extends StatefulWidget {
//   const EditProfileScreen({Key? key}) : super(key: key);
//
//   @override
//   State<EditProfileScreen> createState() => _EditProfileScreenState();
// }
//
// class _EditProfileScreenState extends State<EditProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _skillsController = TextEditingController();
//   final _preferencesController = TextEditingController();
//   File? _cvFile;
//   String? _cvFileName;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//   String userName = '';
//   String userEmail = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//     fetchProfile();
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
//   Future<void> fetchProfile() async {
//     setState(() => _isLoading = true);
//     try {
//       SharedPreferences sh = await SharedPreferences.getInstance();
//       String url = sh.getString('url') ?? 'http://10.0.2.2:8000';
//       final headers = await _getAuthHeaders();
//       final response = await http.get(
//         Uri.parse('$url/edit_profile/'),
//         headers: headers,
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body)['data'];
//         setState(() {
//           _nameController.text = data['name'] ?? '';
//           _emailController.text = data['email'] ?? '';
//           _phoneController.text = data['phone'] ?? '';
//           _skillsController.text = data['skills'] ?? '';
//           _preferencesController.text = data['preferences'] ?? '';
//           _cvFileName = data['cv']?.split('/').last;
//         });
//       } else if (response.statusCode == 401) {
//         Fluttertoast.showToast(
//           msg: 'Session expired. Please login again.',
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const MyLogin()),
//               (route) => false,
//         );
//       } else {
//         Fluttertoast.showToast(
//           msg: 'Failed to load profile: HTTP ${response.statusCode}',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: 'Network error: $e',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0,
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> updateProfile() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//     try {
//       SharedPreferences sh = await SharedPreferences.getInstance();
//       String url = sh.getString('url') ?? 'http://10.0.2.2:8000';
//       final headers = await _getAuthHeaders();
//       var request = http.MultipartRequest('POST', Uri.parse('$url/edit_profile/'));
//       request.fields['name'] = _nameController.text;
//       request.fields['email'] = _emailController.text;
//       request.fields['phone'] = _phoneController.text;
//       request.fields['skills'] = _skillsController.text;
//       request.fields['preferences'] = _preferencesController.text;
//
//       if (_cvFile != null) {
//         request.files.add(
//           await http.MultipartFile.fromPath(
//             'cv',
//             _cvFile!.path,
//             filename: _cvFileName,
//           ),
//         );
//       }
//
//       request.headers.addAll(headers);
//
//       final response = await request.send();
//       final body = await response.stream.bytesToString();
//       final jsonResponse = jsonDecode(body);
//
//       if (response.statusCode == 200) {
//         String message = jsonResponse['message'] ?? 'Profile updated successfully';
//         String extractedSkills = jsonResponse['extracted_skills'] ?? '';
//         if (extractedSkills.isNotEmpty) {
//           message += '\nExtracted skills: $extractedSkills';
//         }
//         Fluttertoast.showToast(
//           msg: message,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.green,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const ViewProfileScreen()),
//         );
//       } else if (response.statusCode == 401) {
//         Fluttertoast.showToast(
//           msg: 'Session expired. Please login again.',
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const MyLogin()),
//               (route) => false,
//         );
//       } else {
//         final error = jsonResponse['error'] ?? 'Update failed';
//         Fluttertoast.showToast(
//           msg: error,
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: 'Network error: $e',
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0,
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> pickCV() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//       );
//
//       if (result != null && result.files.single.path != null) {
//         final file = File(result.files.single.path!);
//         final extension = file.path.split('.').last.toLowerCase();
//         if (extension == 'pdf') {
//           setState(() {
//             _cvFile = file;
//             _cvFileName = result.files.single.name;
//           });
//           Fluttertoast.showToast(
//             msg: 'CV selected: $_cvFileName',
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.green,
//             textColor: Colors.white,
//             fontSize: 16.0,
//           );
//         } else {
//           Fluttertoast.showToast(
//             msg: 'Invalid file type. Please select a PDF document.',
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.red,
//             textColor: Colors.white,
//             fontSize: 16.0,
//           );
//         }
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: 'Error selecting file: $e',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0,
//       );
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
//             'Edit Profile',
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
//             _isLoading
//                 ? const Center(child: CircularProgressIndicator(color: Colors.white))
//                 : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: ListView(
//                   children: [
//                     TextFormField(
//                       controller: _nameController,
//                       style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                       decoration: InputDecoration(
//                         labelText: 'Name',
//                         labelStyle: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                         filled: true,
//                         fillColor: Colors.black.withOpacity(0.4),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white, width: 2),
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your name';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _emailController,
//                       style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         labelStyle: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                         filled: true,
//                         fillColor: Colors.black.withOpacity(0.4),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white, width: 2),
//                         ),
//                       ),
//                       keyboardType: TextInputType.emailAddress,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter an email';
//                         }
//                         if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                           return 'Please enter a valid email';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _phoneController,
//                       style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                       decoration: InputDecoration(
//                         labelText: 'Phone',
//                         labelStyle: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                         filled: true,
//                         fillColor: Colors.black.withOpacity(0.4),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white, width: 2),
//                         ),
//                       ),
//                       keyboardType: TextInputType.phone,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter a phone number';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _skillsController,
//                       style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                       decoration: InputDecoration(
//                         labelText: 'Skills (optional)',
//                         labelStyle: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                         filled: true,
//                         fillColor: Colors.black.withOpacity(0.4),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white, width: 2),
//                         ),
//                       ),
//                       maxLines: 3,
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _preferencesController,
//                       style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                       decoration: InputDecoration(
//                         labelText: 'Preferences (optional, or upload CV to auto-fill)',
//                         labelStyle: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
//                         filled: true,
//                         fillColor: Colors.black.withOpacity(0.4),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white54),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Colors.white, width: 2),
//                         ),
//                       ),
//                       maxLines: 3,
//                     ),
//                     const SizedBox(height: 20),
//                     ListTile(
//                       title: Text(
//                         _cvFileName ?? 'No CV selected',
//                         style: TextStyle(
//                           color: _cvFileName != null ? Colors.white : Colors.white70,
//                           fontFamily: 'Roboto',
//                         ),
//                       ),
//                       trailing: Container(
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               Theme.of(context).colorScheme.primary,
//                               Theme.of(context).colorScheme.primary.withOpacity(0.8),
//                             ],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.2),
//                               spreadRadius: 2,
//                               blurRadius: 8,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: ElevatedButton(
//                           onPressed: _isLoading ? null : pickCV,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             shadowColor: Colors.transparent,
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                           ),
//                           child: const Text(
//                             'Upload CV',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                               fontFamily: 'Roboto',
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Theme.of(context).colorScheme.primary,
//                             Theme.of(context).colorScheme.primary.withOpacity(0.8),
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.2),
//                             spreadRadius: 2,
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : updateProfile,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.transparent,
//                           shadowColor: Colors.transparent,
//                           padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: _isLoading
//                             ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         )
//                             : const Text(
//                           'Save Changes',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             fontFamily: 'Roboto',
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
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
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _skillsController.dispose();
//     _preferencesController.dispose();
//     super.dispose();
//   }
// }