import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddContactSheet extends StatefulWidget {
  final Future<void> Function() onAdded; // ✅ UPDATED
  final Map<String, dynamic>? contact; // for edit

  const AddContactSheet({
    super.key,
    required this.onAdded,
    this.contact,
  });

  @override
  State<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<AddContactSheet> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final relativeController = TextEditingController();

  bool isSaving = false;
  final String baseUrl = "http://192.168.1.6:8082";

  @override
  void initState() {
    super.initState();

    // Prefill for edit
    if (widget.contact != null) {
      nameController.text = widget.contact!["name"] ?? "";
      phoneController.text = widget.contact!["phoneNumber"] ?? "";
      relativeController.text = widget.contact!["relation"] ?? "";
    }
  }

  Future<void> saveContact() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        relativeController.text.isEmpty) {
      return;
    }

    setState(() => isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      setState(() => isSaving = false);
      return;
    }

    final isEdit = widget.contact != null;

    final url = isEdit
        ? "$baseUrl/api/users/contacts/${widget.contact!["id"]}"
        : "$baseUrl/api/users/contacts";

    final method = isEdit ? http.put : http.post;

    final response = await method(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": nameController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "relation": relativeController.text.trim(),
      }),
    );

    setState(() => isSaving = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      await widget.onAdded(); // ✅ WAIT for refresh
      if (!mounted) return;
      Navigator.pop(context); // ✅ NOW it will close
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save contact")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.contact == null
                  ? "Add Emergency Contact"
                  : "Edit Emergency Contact",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _inputField(
              controller: nameController,
              hint: "Name",
              icon: Icons.person,
            ),
            const SizedBox(height: 14),
            _inputField(
              controller: phoneController,
              hint: "Phone Number",
              icon: Icons.phone,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _inputField(
              controller: relativeController,
              hint: "Relative (e.g. Mother, Friend)",
              icon: Icons.family_restroom,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isSaving ? null : saveContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                  widget.contact == null ? "Save" : "Update",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}
