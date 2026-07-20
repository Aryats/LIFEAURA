// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
// import 'user_home.dart';
// import 'edit_profile.dart';
// import 'complaint.dart';
// import 'feedback.dart';
// import 'login.dart';
//
// class ViewProfileScreen extends StatefulWidget {
//   const ViewProfileScreen({super.key});
//
//   @override
//   State<ViewProfileScreen> createState() => _ViewProfileScreenState();
// }
//
// class _ViewProfileScreenState extends State<ViewProfileScreen> {
//   Map<String, dynamic> profileData = {};
//   bool _isLoading = true;
//   bool _hasError = false;
//   String _errorMessage = '';
//   bool _isOpeningCV = false;
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
//   @override
//   void initState() {
//     super.initState();
//     _fetchProfileData();
//   }
//
//   Future<void> _fetchProfileData() async {
//     setState(() {
//       _isLoading = true;
//       _hasError = false;
//     });
//
//     SharedPreferences sh = await SharedPreferences.getInstance();
//     String url = sh.getString('url') ?? 'http://10.0.2.2:8000';
//
//     try {
//       Map<String, String> headers = await _getAuthHeaders();
//       final response = await http.get(
//         Uri.parse('$url/user_profile/'),
//         headers: headers,
//       );
//
//       if (response.statusCode == 200) {
//         final jsonResponse = jsonDecode(response.body);
//         if (jsonResponse['status'] == 'success') {
//           setState(() {
//             profileData = jsonResponse['data'];
//             _isLoading = false;
//           });
//         } else {
//           setState(() {
//             _isLoading = false;
//             _hasError = true;
//             _errorMessage = jsonResponse['message'] ?? 'Failed to load profile';
//           });
//           Fluttertoast.showToast(
//             msg: _errorMessage,
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.red,
//             textColor: Colors.white,
//             fontSize: 16.0,
//           );
//         }
//       } else if (response.statusCode == 401) {
//         setState(() {
//           _isLoading = false;
//           _hasError = true;
//           _errorMessage = 'Session expired. Please login again.';
//         });
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
//         setState(() {
//           _isLoading = false;
//           _hasError = true;
//           _errorMessage = 'Server error: ${response.statusCode}';
//         });
//         Fluttertoast.showToast(
//           msg: _errorMessage,
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _hasError = true;
//         _errorMessage = 'Network error: $e';
//       });
//       Fluttertoast.showToast(
//         msg: _errorMessage,
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0,
//       );
//     }
//   }
//
//   Future<void> _viewOrDownloadCV() async {
//     if (_isOpeningCV || profileData['cv'] == null) {
//       if (profileData['cv'] == null) {
//         Fluttertoast.showToast(
//           msg: 'No CV available',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//       }
//       return;
//     }
//
//     setState(() {
//       _isOpeningCV = true;
//     });
//
//     try {
//       final url = Uri.parse(profileData['cv']);
//       if (await canLaunchUrl(url)) {
//         await launchUrl(url, mode: LaunchMode.externalApplication);
//       } else {
//         await _downloadCV();
//       }
//     } catch (e) {
//       await _downloadCV();
//     } finally {
//       setState(() {
//         _isOpeningCV = false;
//       });
//     }
//   }
//
//   Future<void> _downloadCV() async {
//     try {
//       final headers = await _getAuthHeaders();
//       final response = await http.get(Uri.parse(profileData['cv']), headers: headers);
//
//       if (response.statusCode == 200) {
//         final tempDir = await getTemporaryDirectory();
//         final fileName = profileData['cv'].split('/').last;
//         final file = File('${tempDir.path}/$fileName');
//         await file.writeAsBytes(response.bodyBytes);
//
//         final result = await OpenFile.open(file.path);
//         if (result.type != ResultType.done) {
//           Fluttertoast.showToast(
//             msg: 'Cannot open CV: ${result.message}. Saved to ${file.path}',
//             toastLength: Toast.LENGTH_LONG,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.orange,
//             textColor: Colors.white,
//             fontSize: 16.0,
//           );
//         } else {
//           Fluttertoast.showToast(
//             msg: 'CV opened successfully',
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.green,
//             textColor: Colors.white,
//             fontSize: 16.0,
//           );
//         }
//       } else {
//         Fluttertoast.showToast(
//           msg: 'Failed to download CV: ${response.statusCode}',
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg: 'Error downloading CV: $e',
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
//   Widget _buildProfileItem(String title, String value, {IconData? icon}) {
//     return ListTile(
//       leading: icon != null ? Icon(icon, color: Colors.white, size: 24) : null,
//       title: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 14,
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontFamily: 'Roboto',
//         ),
//       ),
//       subtitle: Text(
//         value.isNotEmpty ? value : 'Not provided',
//         style: const TextStyle(
//           fontSize: 16,
//           color: Colors.white70,
//           fontFamily: 'Roboto',
//         ),
//       ),
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
//             'User Profile',
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
//               icon: const Icon(Icons.refresh, color: Colors.white),
//               onPressed: _fetchProfileData,
//             ),
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
//                         profileData['name'] != null && profileData['name'].isNotEmpty
//                             ? profileData['name'][0].toUpperCase()
//                             : 'U',
//                         style: const TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.deepPurple,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       profileData['name'] ?? 'User',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         fontFamily: 'Roboto',
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Text(
//                       profileData['email'] ?? '',
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
//                 : _hasError
//                 ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error_outline, size: 64, color: Colors.red),
//                   const SizedBox(height: 16),
//                   Text(
//                     _errorMessage,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       color: Colors.white,
//                       fontFamily: 'Roboto',
//                     ),
//                   ),
//                   const SizedBox(height: 20),
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
//                       onPressed: _fetchProfileData,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         'Retry',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           fontFamily: 'Roboto',
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//                 : ListView(
//               padding: const EdgeInsets.all(16),
//               children: [
//                 Center(
//                   child: Column(
//                     children: [
//                       CircleAvatar(
//                         radius: 50,
//                         backgroundColor: Colors.deepPurple,
//                         child: Text(
//                           profileData['name'] != null && profileData['name'].isNotEmpty
//                               ? profileData['name'][0].toUpperCase()
//                               : 'U',
//                           style: const TextStyle(
//                             fontSize: 40,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Text(
//                         profileData['name'] ?? 'User',
//                         style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           fontFamily: 'Roboto',
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         profileData['email'] ?? '',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.white70,
//                           fontFamily: 'Roboto',
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 const Divider(color: Colors.white54),
//                 _buildProfileItem('Phone', profileData['phone'] ?? '', icon: Icons.phone),
//                 const Divider(color: Colors.white54),
//                 _buildProfileItem('Skills', profileData['skills'] ?? '', icon: Icons.school),
//                 const Divider(color: Colors.white54),
//                 _buildProfileItem('Preferences', profileData['preferences'] ?? '', icon: Icons.settings),
//                 const Divider(color: Colors.white54),
//                 if (profileData['cv'] != null)
//                   Column(
//                     children: [
//                       ListTile(
//                         leading: const Icon(Icons.description, color: Colors.white, size: 24),
//                         title: const Text(
//                           'CV',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontFamily: 'Roboto',
//                           ),
//                         ),
//                         subtitle: Text(
//                           profileData['cv'].split('/').last,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             color: Colors.white70,
//                             fontFamily: 'Roboto',
//                           ),
//                         ),
//                         trailing: Container(
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Theme.of(context).colorScheme.primary,
//                                 Theme.of(context).colorScheme.primary.withOpacity(0.8),
//                               ],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.2),
//                                 spreadRadius: 2,
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: ElevatedButton(
//                             onPressed: _isOpeningCV ? null : _viewOrDownloadCV,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.transparent,
//                               shadowColor: Colors.transparent,
//                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             child: _isOpeningCV
//                                 ? const SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               ),
//                             )
//                                 : const Text(
//                               'View CV',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.white,
//                                 fontFamily: 'Roboto',
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const Divider(color: Colors.white54),
//                     ],
//                   ),
//                 const SizedBox(height: 20),
//                 Center(
//                   child: Container(
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
//                     child: ElevatedButton.icon(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (context) => const EditProfileScreen()),
//                         );
//                       },
//                       icon: const Icon(Icons.edit, color: Colors.white),
//                       label: const Text(
//                         'Edit Profile',
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: Colors.white,
//                           fontFamily: 'Roboto',
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }