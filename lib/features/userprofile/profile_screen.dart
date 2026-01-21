import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/screens/login_screen.dart';
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
  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Clear everything (safe)
    await prefs.clear();

    // Navigate to Login & remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

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
      Uri.parse("http://192.168.1.6:8082/api/users/$userId"); //"http://10.218.102.76:8082/api/users/$userId"

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
        _showError("Failed to load userprofile");
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

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              logout(context);
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
                // _ProfileRow(
                //   label: "Verified",
                //   value: isVerified ? "Yes" : "No",
                // ),
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
                    await _fetchProfile();
                    if (!mounted) return;
                    setState(() => loading = false);

                    Navigator.pop(context, true); // 🔥 TELL HOME SCREEN
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
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                onPressed: () => showLogoutDialog(context),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
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
