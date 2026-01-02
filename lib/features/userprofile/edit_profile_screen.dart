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
          localImageFile = null; // ✅ reset preview
        });
      }
    } catch (e) {
      debugPrint("EDIT PROFILE LOAD ERROR: $e");
    }
  }

  // ================= IMAGE OPTIONS =================

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Choose from Gallery"),
            onTap: () async {
              Navigator.pop(context);
              final image = await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 70,
              );
              if (image != null) {
                setState(() {
                  localImageFile = File(image.path); // ✅ preview only
                  profileImageUrl = null; // ❌ not saved
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take Photo"),
            onTap: () async {
              Navigator.pop(context);
              final image = await _picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 70,
              );
              if (image != null) {
                setState(() {
                  localImageFile = File(image.path); // ✅ preview only
                  profileImageUrl = null;
                });
              }
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
                  profileImageUrl = url; // ✅ backend-safe
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

  // ================= UPDATE PROFILE =================

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
          "profilePictureUrl": profileImageUrl, // ✅ ONLY URL
        }),
      );

      setState(() => loading = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
        Navigator.pop(context, true);
      } else {
        _showSnack("Failed to update userprofile");
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
    ImageProvider avatar;

    if (localImageFile != null) {
      avatar = FileImage(localImageFile!); // ✅ preview
    } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      avatar = NetworkImage(profileImageUrl!); // ✅ saved image
    } else {
      avatar = const AssetImage("assets/images/avatar.png");
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
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
                    CircleAvatar(radius: 50, backgroundImage: avatar),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 18),
                    ),
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
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
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
