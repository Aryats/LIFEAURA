//
//
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:postdischarge/view_vitals.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'ai_report.dart';
// import 'view_hospitals.dart';
// import 'patient_send_complaints.dart';
// import 'patinet_view_common_notification.dart';
// import 'patient_add_view_update_food_timing.dart';
// import 'patinet_view_discharge_summary.dart';
// import 'patinet_view_reminders.dart';
// import 'ip_address_page.dart';
// import 'upload_vitals.dart';
//
// class PatientHomePage extends StatefulWidget {
//   const PatientHomePage({Key? key}) : super(key: key);
//
//   @override
//   State<PatientHomePage> createState() => _PatientHomePageState();
// }
//
// class _PatientHomePageState extends State<PatientHomePage>
//     with SingleTickerProviderStateMixin {
//   String patientName = "Loading...";
//   String? profileImageUrl;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   Future<String> _getBaseUrl() async {
//     final prefs = await SharedPreferences.getInstance();
//     final ip = prefs.getString('ipAddress') ?? '127.0.0.1:8000';
//     return ip.startsWith('http://') ? ip : 'http://$ip';
//   }
//
//   Future<int?> _getPatientId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt('patient_id');
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _loadPatientData();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeIn,
//     );
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadPatientData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final username = prefs.getString('username') ?? 'Patient';
//     final patientId = await _getPatientId();
//
//     if (patientId == null) {
//       setState(() => patientName = username);
//       return;
//     }
//
//     setState(() => patientName = username);
//     _fetchProfile(patientId);
//   }
//
//   Future<void> _fetchProfile(int patientId) async {
//     final baseUrl = await _getBaseUrl();
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/patient_view-profile/$patientId/'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body)['data'];
//         setState(() {
//           patientName = data['full_name'];
//           profileImageUrl = data['profile_image'];
//         });
//
//         final prefs = await SharedPreferences.getInstance();
//         prefs.setString('username', data['full_name']);
//         prefs.setString('contact_number', data['contact_number']);
//         prefs.setString('address', data['address']);
//       }
//     } catch (e) {
//       debugPrint('Error fetching profile: $e');
//     }
//   }
//
//   void navigateTo(BuildContext context, Widget page) {
//     Navigator.push(context, MaterialPageRoute(builder: (_) => page));
//   }
//
//   Future<void> _logout() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             Icon(Icons.logout, color: Colors.red.shade400),
//             const SizedBox(width: 10),
//             const Text('Logout'),
//           ],
//         ),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
//             child: const Text('Logout'),
//           ),
//         ],
//       ),
//     );
//
//     if (confirm == true) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();
//       if (mounted) {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => const IpAddressPage()),
//               (route) => false,
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         image: DecorationImage(image: AssetImage('assets/bg2.png'), fit: BoxFit.cover),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: const Text('Patient Home', style: TextStyle(fontWeight: FontWeight.bold)),
//           flexibleSpace: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(colors: [Colors.teal.shade700, Colors.teal.shade400]),
//             ),
//           ),
//           foregroundColor: Colors.white,
//           elevation: 0,
//         ),
//         drawer: Drawer(
//           child: Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(image: AssetImage('assets/bg2.png'), fit: BoxFit.cover),
//             ),
//             child: SafeArea(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // Profile Header
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.85),
//                       borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
//                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
//                     ),
//                     padding: const EdgeInsets.all(20),
//                     child: Row(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.teal, width: 3),
//                             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
//                           ),
//                           child: CircleAvatar(
//                             radius: 35,
//                             backgroundColor: Colors.white,
//                             backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
//                             child: profileImageUrl == null ? Icon(Icons.person, size: 40, color: Colors.teal.shade700) : null,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 patientName,
//                                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
//                               ),
//                               const SizedBox(height: 10),
//                               InkWell(
//                                 onTap: () async {
//                                   final patientId = await _getPatientId();
//                                   if (patientId != null) {
//                                     Navigator.pop(context);
//                                     await Navigator.push(
//                                       context,
//                                       MaterialPageRoute(builder: (_) => EditProfilePage(patientId: patientId)),
//                                     );
//                                     await _fetchProfile(patientId);
//                                   }
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                                   decoration: BoxDecoration(
//                                     color: Colors.teal.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(20),
//                                     border: Border.all(color: Colors.teal.withOpacity(0.5), width: 1),
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Icon(Icons.edit_outlined, size: 16, color: Colors.teal.shade700),
//                                       const SizedBox(width: 6),
//                                       Text('Edit Profile', style: TextStyle(fontSize: 14, color: Colors.teal.shade700, fontWeight: FontWeight.w500)),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   // Menu Items
//                   Expanded(
//                     child: ListView(
//                       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                       children: [
//                         _buildDrawerItem(icon: Icons.local_hospital_rounded, title: 'View Hospitals', color: Colors.blue, onTap: () => navigateTo(context, const ViewHospitalsPage())),
//                         _buildDrawerItem(icon: Icons.description_rounded, title: 'View Discharge Summary', color: Colors.purple, onTap: () => navigateTo(context, const PatientViewDischargeSummary())),
//                         _buildDrawerItem(icon: Icons.schedule_rounded, title: 'Add Food Timing', color: Colors.orange, onTap: () => navigateTo(context, const PatientFoodTimingPage())),
//                         _buildDrawerItem(icon: Icons.upload_file_rounded, title: 'Upload Vitals', color: Colors.green, onTap: () => navigateTo(context, const UploadVitalsPage())),
//                         _buildDrawerItem(icon: Icons.ad_units, title: 'View Vitals', color: Colors.green, onTap: () => navigateTo(context, const ViewVitalsPage())),
//                         _buildDrawerItem(icon: Icons.fitness_center_rounded, title: 'AI-Generated Routine', color: Colors.indigo, onTap: () => navigateTo(context, const AIReportPage())),
//                         _buildDrawerItem(icon: Icons.report_problem_rounded, title: 'Send Common Complaints', color: Colors.red.shade400, onTap: () => navigateTo(context, const PatientSendComplaintsPage())),
//                         _buildDrawerItem(icon: Icons.notifications_active_rounded, title: 'View Common Notifications', color: Colors.amber.shade700, onTap: () => navigateTo(context, const PatientViewCommonNotificationPage())),
//                         const Divider(thickness: 1, color: Colors.white54),
//                         _buildDrawerItem(icon: Icons.logout_rounded, title: 'Logout', color: Colors.red, onTap: _logout, isDestructive: true),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         body: const PatinetViewReminders(),
//       ),
//     );
//   }
//
//   Widget _buildDrawerItem({required IconData icon, required String title, required Color color, required VoidCallback onTap, bool isDestructive = false}) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withOpacity(0.9), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
//       child: ListTile(
//         leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 24)),
//         title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black87, fontWeight: FontWeight.w600, fontSize: 15)),
//         trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade600),
//         onTap: onTap,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }
// }
//
// // ===================== EDIT PROFILE PAGE ==========================
//
// class EditProfilePage extends StatefulWidget {
//   final int patientId;
//   const EditProfilePage({Key? key, required this.patientId}) : super(key: key);
//
//   @override
//   State<EditProfilePage> createState() => _EditProfilePageState();
// }
//
// class _EditProfilePageState extends State<EditProfilePage> with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _ageController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//
//   String? _gender;
//   File? _imageFile;
//   bool _isLoading = false;
//   String? _currentImageUrl;
//
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//
//   Future<String> _getBaseUrl() async {
//     final prefs = await SharedPreferences.getInstance();
//     final ip = prefs.getString('ipAddress') ?? '127.0.0.1:8000';
//     return ip.startsWith('http://') ? ip : 'http://$ip';
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _loadProfileData();
//     _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
//     _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack);
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _nameController.dispose();
//     _ageController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadProfileData() async {
//     setState(() => _isLoading = true);
//     final baseUrl = await _getBaseUrl();
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/patient_view-profile/${widget.patientId}/'));
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body)['data'];
//         setState(() {
//           _nameController.text = data['full_name'];
//           _ageController.text = data['age'].toString();
//           _gender = data['gender'];
//           _phoneController.text = data['contact_number'];
//           _addressController.text = data['address'];
//           _currentImageUrl = data['profile_image'];
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() => _imageFile = File(pickedFile.path));
//     }
//   }
//
//   Future<void> _saveProfile() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//     final baseUrl = await _getBaseUrl();
//
//     var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/patient_edit-profile/${widget.patientId}/'));
//     request.fields['full_name'] = _nameController.text.trim();
//     request.fields['age'] = _ageController.text.trim();
//     request.fields['gender'] = _gender ?? '';
//     request.fields['contact_number'] = _phoneController.text.trim();
//     request.fields['address'] = _addressController.text.trim();
//
//     if (_imageFile != null) {
//       request.files.add(await http.MultipartFile.fromPath('profile_image', _imageFile!.path));
//     }
//
//     try {
//       final response = await request.send();
//       final respStr = await response.stream.bytesToString();
//       final responseData = json.decode(respStr);
//
//       if (response.statusCode == 200) {
//         // Update local state with new data if provided in response
//         if (responseData['data'] != null) {
//           final updatedData = responseData['data'];
//           setState(() {
//             _currentImageUrl = updatedData['profile_image'];
//           });
//         }
//
//         final prefs = await SharedPreferences.getInstance();
//         prefs.setString('username', _nameController.text.trim());
//         prefs.setString('contact_number', _phoneController.text.trim());
//         prefs.setString('address', _addressController.text.trim());
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text('Profile updated!')]), backgroundColor: Colors.green),
//         );
//         if (mounted) Navigator.pop(context);
//       } else {
//         final errorMessage = responseData['message'] ?? 'Update failed';
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: $e'), backgroundColor: Colors.red));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/bg1.png'), fit: BoxFit.cover)),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         body: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(colors: [Colors.teal.shade700, Colors.teal.shade400, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.3, 1.0]),
//           ),
//           child: SafeArea(
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(children: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)), const Text('Edit Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))]),
//                 ),
//                 Expanded(
//                   child: _isLoading
//                       ? const Center(child: CircularProgressIndicator(color: Colors.white))
//                       : ScaleTransition(
//                     scale: _scaleAnimation,
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(20),
//                       child: Form(
//                         key: _formKey,
//                         child: Column(children: [
//                           Stack(children: [
//                             Container(
//                               decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)]),
//                               child: CircleAvatar(
//                                 radius: 70,
//                                 backgroundColor: Colors.white,
//                                 backgroundImage: _imageFile != null ? FileImage(_imageFile!) : (_currentImageUrl != null ? NetworkImage(_currentImageUrl!) : null),
//                                 child: _imageFile == null && _currentImageUrl == null ? Icon(Icons.person, size: 70, color: Colors.teal.shade700) : null,
//                               ),
//                             ),
//                             Positioned(
//                               bottom: 0,
//                               right: 0,
//                               child: Container(
//                                 decoration: BoxDecoration(color: Colors.teal, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
//                                 child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20), onPressed: _pickImage),
//                               ),
//                             ),
//                           ]),
//                           const SizedBox(height: 40),
//                           _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Required' : null),
//                           const SizedBox(height: 16),
//                           _buildTextField(controller: _ageController, label: 'Age', icon: Icons.cake_outlined, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
//                           const SizedBox(height: 16),
//                           DropdownButtonFormField<String>(
//                             value: _gender,
//                             decoration: InputDecoration(
//                               labelText: 'Gender',
//                               prefixIcon: Icon(Icons.wc, color: Colors.teal.shade600),
//                               filled: true,
//                               fillColor: Colors.white,
//                               border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
//                             ),
//                             items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
//                             onChanged: (v) => setState(() => _gender = v),
//                             validator: (v) => v == null ? 'Required' : null,
//                           ),
//                           const SizedBox(height: 16),
//                           _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
//                           const SizedBox(height: 16),
//                           _buildTextField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined, maxLines: 3),
//                           const SizedBox(height: 40),
//                           Container(
//                             width: double.infinity,
//                             height: 55,
//                             decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade600, Colors.teal.shade400]), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]),
//                             child: ElevatedButton(
//                               onPressed: _isLoading ? null : _saveProfile,
//                               style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
//                               child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save_outlined, color: Colors.white), SizedBox(width: 10), Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))]),
//                             ),
//                           ),
//                         ]),
//                       ),
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
//
//   Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
//     return Container(
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: TextStyle(color: Colors.teal.shade600),
//           prefixIcon: Icon(icon, color: Colors.teal.shade600),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
//           filled: true,
//           fillColor: Colors.white,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         ),
//         validator: validator,
//       ),
//     );
//   }
// }