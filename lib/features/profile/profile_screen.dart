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
  String ?email;
  String phone = "";
  String address = "";
  bool isVerified = false;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    loadEmail();
  }

  Future<void> loadEmail() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email')!;
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final userId = prefs.getString("userId");

      debugPrint("🟡 USER ID: $userId");
      debugPrint("🟡 TOKEN: $token");

      const baseUrl = "http://192.168.1.6:8082";
      final url = Uri.parse("$baseUrl/api/users/$userId");

      debugPrint("🟡 PROFILE API URL: $url");

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("🟢 STATUS CODE: ${response.statusCode}");
      debugPrint("🟢 RAW RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        debugPrint("🟢 PARSED BODY: $body");

        final data = body;
        debugPrint("🟢 DATA OBJECT: $data");

        setState(() {
          name = data?["name"] ?? "";
          email = data?["email"] ?? "";
          phone = data?["phone"] ?? "";
          address = data?["address"] ?? "";
          isVerified = data?["isVerified"] ?? false;
          profileImageUrl = data?["profilePictureUrl"];
          loading = false;
        });
      } else {
        _showError("Failed to load profile");
      }
    } catch (e) {
      debugPrint("🔴 PROFILE FETCH ERROR: $e");
      _showError("Something went wrong");
    }
  }

  // Future<void> _fetchProfile() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString("token");
  //     final userId = prefs.getString("userId");
  //
  //     if (token == null || userId == null) {
  //       _showError("Session expired. Please login again.");
  //       return;
  //     }
  //
  //     const baseUrl = "http://192.168.1.3:8082"; // User Service
  //     final url = Uri.parse("$baseUrl/api/users/$userId");
  //
  //     final response = await http.get(
  //       url,
  //       headers: {
  //         "Authorization": "Bearer $token",
  //         "Content-Type": "application/json",
  //       },
  //     );
  //
  //     debugPrint("PROFILE STATUS: ${response.statusCode}");
  //     debugPrint("PROFILE BODY: ${response.body}");
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body); // ✅ FIX: no ["data"]
  //
  //       setState(() {
  //         name = data["name"] ?? "";
  //         email = data["email"] ?? ""; // may be null
  //         phone = data["phone"] ?? "";
  //         address = data["address"] ?? "";
  //         isVerified = data["isVerified"] ?? false;
  //         profileImageUrl = data["profilePictureUrl"];
  //         loading = false;
  //       });
  //     } else {
  //       _showError("Failed to load profile");
  //     }
  //   } catch (e) {
  //     debugPrint("PROFILE ERROR: $e");
  //     _showError("Something went wrong");
  //   }
  // }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => loading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
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
            // 🔹 Avatar
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : const AssetImage(
                      "assets/images/avatar.png",
                    ) as ImageProvider,
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
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Info Card
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

            // 🔹 Edit Button
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

                  // ✅ STEP 4 – refresh after update
                  if (updated == true) {
                    setState(() => loading = true);
                    _fetchProfile();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFFD4AF37),
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

// ---------------- Reusable Widgets ----------------

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
              style:
              const TextStyle(color: Colors.black54),
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
