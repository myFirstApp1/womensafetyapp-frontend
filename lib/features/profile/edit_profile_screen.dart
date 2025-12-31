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

  // ✅ NEW
  final ImagePicker _picker = ImagePicker();
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfileForEdit();
  }

  // 🔹 Load existing profile
  Future<void> _fetchProfileForEdit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final userId = prefs.getString("userId");

      if (token == null || userId == null) return;

      const baseUrl = "http://192.168.1.6:8082";
      final url = Uri.parse("$baseUrl/api/users/$userId");

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
        });
      }
    } catch (e) {
      debugPrint("EDIT PROFILE LOAD ERROR: $e");
    }
  }

  // ================= PROFILE IMAGE OPTIONS =================

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Choose from Gallery"),
            onTap: () {
              Navigator.pop(context);
              _pickFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take Photo"),
            onTap: () {
              Navigator.pop(context);
              _takePhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text("Paste Image URL"),
            onTap: () {
              Navigator.pop(context);
              _showImageUrlDialog();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final image =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => profileImageUrl = image.path);
    }
  }

  Future<void> _takePhoto() async {
    final image =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) {
      setState(() => profileImageUrl = image.path);
    }
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
              setState(() => profileImageUrl = controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 🔹 Update profile (UNCHANGED API)
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final userId = prefs.getString("userId");

      if (token == null || userId == null) {
        _showSnack("Session expired. Please login again.");
        setState(() => loading = false);
        return;
      }

      const baseUrl = "http://192.168.1.6:8082";
      final url = Uri.parse("$baseUrl/api/users/$userId");

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
          "profilePictureUrl": profileImageUrl, // ✅ added
        }),
      );

      setState(() => loading = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
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

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 🔹 Profile Picture Edit
              GestureDetector(
                onTap: _showImageOptions,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileImageUrl != null
                          ? (profileImageUrl!.startsWith("http")
                          ? NetworkImage(profileImageUrl!)
                          : FileImage(File(profileImageUrl!)))
                          : const AssetImage(
                        "assets/images/avatar.png",
                      ) as ImageProvider,
                    ),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 18),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) =>
                v == null || v.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone"),
                validator: (v) =>
                v == null || v.isEmpty ? "Phone is required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: "Address"),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : updateProfile,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
