import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProfileForEdit(); // ✅ load from backend
  }

  // 🔹 STEP 1: Load existing profile from backend
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
        });
      }
    } catch (e) {
      debugPrint("EDIT PROFILE LOAD ERROR: $e");
    }
  }

  // 🔹 STEP 2: Update profile
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
        }),
      );

      setState(() => loading = false);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // ✅ Return success to ProfileScreen
        Navigator.pop(context, true);
      } else {
        debugPrint("UPDATE PROFILE FAILED: ${response.body}");
        _showSnack("Failed to update profile");
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("UPDATE PROFILE ERROR: $e");
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
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
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
