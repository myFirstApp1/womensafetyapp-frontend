import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  bool loading = false;

  final ImagePicker _picker = ImagePicker();

  /// ✅ Remote image URL (ONLY this goes to backend)
  String? profileImageUrl;

  /// ✅ Local image for preview only
  File? localImageFile;

  @override
  void initState() {
    super.initState();
    _fetchProfileForEdit();
  }

  Future<void> _fetchProfileForEdit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final userId = prefs.getString("userId");

      if (token == null || userId == null) return;

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

        setState(() {
          nameCtrl.text = data["name"] ?? "";
          phoneCtrl.text = data["phone"] ?? "";
          addressCtrl.text = data["address"] ?? "";
          profileImageUrl = data["profilePictureUrl"];
          localImageFile = null;
        });
      }
    } catch (e) {
      debugPrint("EDIT PROFILE LOAD ERROR: $e");
    }
  }

  // ================= IMAGE OPTIONS (UI UPDATED ONLY) =================

  void _showImageOptions() {
    const rosePrimary = Color(0xFFF06292);
    const roseLight = Color(0xFFFFEBF0);
    const roseBorder = Color(0xFFF8BBD0);
    const roseText = Color(0xFFAD1457);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: const BoxDecoration(
          color: roseLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: roseBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Update Profile Photo",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: roseText,
              ),
            ),
            const SizedBox(height: 24),

            _PhotoOption(
              icon: Icons.photo_library_outlined,
              title: "Choose from Gallery",
              subtitle: "Select a photo from your device",
              onTap: () async {
                Navigator.pop(context);
                final image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() {
                    localImageFile = File(image.path);
                    profileImageUrl = null;
                  });
                }
              },
            ),

            const SizedBox(height: 12),

            _PhotoOption(
              icon: Icons.camera_alt_outlined,
              title: "Take Photo",
              subtitle: "Use your camera",
              onTap: () async {
                Navigator.pop(context);
                final image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() {
                    localImageFile = File(image.path);
                    profileImageUrl = null;
                  });
                }
              },
            ),

            const SizedBox(height: 12),

            _PhotoOption(
              icon: Icons.link,
              title: "Paste Image URL",
              subtitle: "Use an online image link",
              onTap: () {
                Navigator.pop(context);
                _showImageUrlDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageUrlDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Paste Image URL"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "https://example.com/photo.jpg",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.startsWith("http")) {
                setState(() {
                  profileImageUrl = url;
                  localImageFile = null;
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ================= UPDATE PROFILE (UNCHANGED) =================

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final userId = prefs.getString("userId");

      if (token == null || userId == null) {
        _showSnack("Session expired");
        setState(() => loading = false);
        return;
      }

      final url =
      Uri.parse("http://192.168.1.6:8082/api/users/$userId");

      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": nameCtrl.text.trim(),
          "phone": phoneCtrl.text.trim(),
          "address": addressCtrl.text.trim(),
          "profilePictureUrl": profileImageUrl,
        }),
      );

      setState(() => loading = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("username", nameCtrl.text.trim());
        Navigator.pop(context, true);
      } else {
        _showSnack("Failed to update profile");
      }
    } catch (e) {
      setState(() => loading = false);
      _showSnack("Something went wrong");
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    const rosePrimary = Color(0xFFF06292);
    const roseLight = Color(0xFFFFEBF0);
    const roseBorder = Color(0xFFF8BBD0);
    const roseText = Color(0xFFAD1457);

    ImageProvider avatar;

    if (localImageFile != null) {
      avatar = FileImage(localImageFile!);
    } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      avatar = NetworkImage(profileImageUrl!);
    } else {
      avatar = const AssetImage("assets/images/avatar.png");
    }

    return Scaffold(
      backgroundColor: roseLight,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        foregroundColor: roseText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _showImageOptions,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: roseBorder,
                      backgroundImage: avatar,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.edit,
                          size: 18, color: rosePrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ---- Card ----
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: roseBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: roseText,
                      ),
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: nameCtrl,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: "Name",
                        helperText: "Name cannot be changed",
                        filled: true,
                        fillColor: roseLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        prefixIcon:
                        const Icon(Icons.phone, color: rosePrimary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: roseBorder),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Phone number is required";
                        }
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
                          return "Enter valid 10-digit phone number";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Address",
                        prefixIcon: const Icon(Icons.location_on,
                            color: rosePrimary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: roseBorder),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rosePrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save Changes",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= PHOTO OPTION WIDGET =================

class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const rosePrimary = Color(0xFFF06292);
    const roseBorder = Color(0xFFF8BBD0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: roseBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: rosePrimary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: rosePrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
