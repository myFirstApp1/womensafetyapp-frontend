import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;

  String name = "";
  String? email;
  String phone = "";
  String address = "";
  bool isVerified = false;

  /// ✅ ONLY remote URL from backend
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // ================= EMAIL FROM JWT (UNCHANGED) =================

  String? _extractEmailFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payloadDecoded = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final Map<String, dynamic> decoded = jsonDecode(payloadDecoded);
      return decoded['email'];
    } catch (_) {
      return null;
    }
  }

  // ================= PROFILE API =================

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final userId = prefs.getString("userId");

      if (token == null || userId == null) {
        _showError("Session expired. Please login again.");
        return;
      }

      final url =
      Uri.parse("http://192.168.1.6:8082/api/users/$userId");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final resolvedEmail =
            data["email"] ?? _extractEmailFromToken(token);

        setState(() {
          name = data["name"] ?? "";
          email = resolvedEmail;
          phone = data["phone"] ?? "";
          address = data["address"] ?? "";
          isVerified = data["isVerified"] ?? false;

          /// ✅ accept ONLY http URLs
          final img = data["profilePictureUrl"];
          profileImageUrl =
          (img != null && img.startsWith("http")) ? img : null;

          loading = false;
        });
      } else {
        _showError("Failed to load profile");
      }
    } catch (e) {
      _showError("Something went wrong");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => loading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatar =
    (profileImageUrl != null && profileImageUrl!.startsWith("http"))
        ? NetworkImage(profileImageUrl!)
        : const AssetImage("assets/images/avatar.png");

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F3),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔹 Avatar (READ ONLY)
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatar,
            ),

            const SizedBox(height: 12),

            Text(
              name.isNotEmpty ? name : "Not set",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              email != null && email!.isNotEmpty ? email! : "—",
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 30),

            _ProfileCard(
              title: "Personal Information",
              children: [
                _ProfileRow(label: "Phone", value: phone),
                _ProfileRow(label: "Address", value: address),
                _ProfileRow(
                  label: "Verified",
                  value: isVerified ? "Yes" : "No",
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );

                  if (updated == true) {
                    setState(() => loading = true);
                    _fetchProfile();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Edit Profile"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= REUSABLE WIDGETS =================

class _ProfileCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value.isNotEmpty ? value : "—",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:image_picker/image_picker.dart';
//
// import 'edit_profile_screen.dart';
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   bool loading = true;
//
//   String name = "";
//   String? email;
//   String phone = "";
//   String address = "";
//   bool isVerified = false;
//   String? profileImageUrl;
//
//   final ImagePicker _picker = ImagePicker(); // ✅ NEW
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchProfile();
//   }
//
//   // ================= EMAIL FROM JWT (UNCHANGED) =================
//
//   String? _extractEmailFromToken(String token) {
//     try {
//       final parts = token.split('.');
//       if (parts.length != 3) return null;
//
//       final payloadDecoded = utf8.decode(
//         base64Url.decode(base64Url.normalize(parts[1])),
//       );
//
//       final Map<String, dynamic> decoded = jsonDecode(payloadDecoded);
//       return decoded['email'];
//     } catch (_) {
//       return null;
//     }
//   }
//
//   // ================= PROFILE API (UNCHANGED) =================
//
//   Future<void> _fetchProfile() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("token");
//       final userId = prefs.getString("userId");
//
//       if (token == null || userId == null) {
//         _showError("Session expired. Please login again.");
//         return;
//       }
//
//       const baseUrl = "http://192.168.1.6:8082";
//       final url = Uri.parse("$baseUrl/api/users/$userId");
//
//       final response = await http.get(
//         url,
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final resolvedEmail =
//             data["email"] ?? _extractEmailFromToken(token);
//
//         setState(() {
//           name = data["name"] ?? "";
//           email = resolvedEmail;
//           phone = data["phone"] ?? "";
//           address = data["address"] ?? "";
//           isVerified = data["isVerified"] ?? false;
//           profileImageUrl = data["profilePictureUrl"];
//           loading = false;
//         });
//       } else {
//         _showError("Failed to load profile");
//       }
//     } catch (e) {
//       _showError("Something went wrong");
//     }
//   }
//
//   void _showError(String msg) {
//     if (!mounted) return;
//     setState(() => loading = false);
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(msg)));
//   }
//
//   // ================= PROFILE IMAGE OPTIONS (NEW) =================
//
//   void _showImageOptions() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (_) => Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           ListTile(
//             leading: const Icon(Icons.photo),
//             title: const Text("Choose from Gallery"),
//             onTap: () {
//               Navigator.pop(context);
//               _pickFromGallery();
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.camera_alt),
//             title: const Text("Take Photo"),
//             onTap: () {
//               Navigator.pop(context);
//               _takePhoto();
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.link),
//             title: const Text("Paste Image URL"),
//             onTap: () {
//               Navigator.pop(context);
//               _showImageUrlDialog();
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _pickFromGallery() async {
//     final image =
//     await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
//     if (image != null) {
//       setState(() => profileImageUrl = image.path); // TEMP PREVIEW
//     }
//   }
//
//   Future<void> _takePhoto() async {
//     final image =
//     await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
//     if (image != null) {
//       setState(() => profileImageUrl = image.path); // TEMP PREVIEW
//     }
//   }
//
//   void _showImageUrlDialog() {
//     final controller = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Paste Image URL"),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(
//             hintText: "https://example.com/photo.jpg",
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               setState(() => profileImageUrl = controller.text.trim());
//               Navigator.pop(context);
//             },
//             child: const Text("Save"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ================= UI =================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9F7F3),
//       appBar: AppBar(
//         title: const Text("Profile"),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//       ),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             // 🔹 Avatar with Edit Overlay
//             GestureDetector(
//               onTap: _showImageOptions,
//               child: Stack(
//                 alignment: Alignment.bottomRight,
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundColor: Colors.grey.shade200,
//                     backgroundImage: profileImageUrl != null
//                         ? NetworkImage(profileImageUrl!)
//                         : const AssetImage("assets/images/avatar.png")
//                     as ImageProvider,
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 12),
//
//             Text(
//               name.isNotEmpty ? name : "Not set",
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const SizedBox(height: 4),
//
//             Text(
//               email != null && email!.isNotEmpty ? email! : "—",
//               style: const TextStyle(color: Colors.black54),
//             ),
//
//             const SizedBox(height: 30),
//
//             _ProfileCard(
//               title: "Personal Information",
//               children: [
//                 _ProfileRow(label: "Phone", value: phone),
//                 _ProfileRow(label: "Address", value: address),
//                 _ProfileRow(
//                   label: "Verified",
//                   value: isVerified ? "Yes" : "No",
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 30),
//
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: () async {
//                   final updated = await Navigator.push<bool>(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const EditProfileScreen(),
//                     ),
//                   );
//
//                   if (updated == true) {
//                     setState(() => loading = true);
//                     _fetchProfile();
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFD4AF37),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text("Edit Profile"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ================= REUSABLE WIDGETS (UNCHANGED) =================
//
// class _ProfileCard extends StatelessWidget {
//   final String title;
//   final List<Widget> children;
//
//   const _ProfileCard({
//     required this.title,
//     required this.children,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ...children,
//         ],
//       ),
//     );
//   }
// }
//
// class _ProfileRow extends StatelessWidget {
//   final String label;
//   final String value;
//
//   const _ProfileRow({
//     required this.label,
//     required this.value,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         children: [
//           Expanded(
//             flex: 3,
//             child: Text(
//               label,
//               style: const TextStyle(color: Colors.black54),
//             ),
//           ),
//           Expanded(
//             flex: 5,
//             child: Text(
//               value.isNotEmpty ? value : "—",
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
