import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddContactSheet extends StatefulWidget {
  final Future<void> Function() onAdded;
  final Map<String, dynamic>? contact;
  final List<String> existingNumbers;

  const AddContactSheet({
    super.key,
    required this.onAdded,
    required this.existingNumbers,
    this.contact,
  });

  @override
  State<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<AddContactSheet> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final relationController = TextEditingController();

  bool isSaving = false;
  final String baseUrl = "http://192.168.1.6:8082";

  // 🌸 theme colors
  static const rosePrimary = Color(0xFFF06292);
  static const roseLight   = Color(0xFFFFEBF0);
  static const roseBorder  = Color(0xFFF8BBD0);
  static const roseText    = Color(0xFFAD1457);

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      nameController.text = widget.contact!["name"] ?? "";
      relationController.text = widget.contact!["relation"] ?? "";
      phoneController.text =
          (widget.contact!["phoneNumber"] ?? "").replaceFirst("+91", "");
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    relationController.dispose();
    super.dispose();
  }

  bool get isFormValid {
    return nameController.text.trim().isNotEmpty &&
        phoneController.text.trim().length == 10 &&
        relationController.text.trim().isNotEmpty &&
        !isSaving;
  }

  Future<void> saveContact() async {
    if (!isFormValid || isSaving) return;

    final formattedPhone = "+91${phoneController.text.trim()}";

    final isDuplicate = widget.existingNumbers.any(
          (p) => p == formattedPhone && p != widget.contact?["phoneNumber"],
    );

    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This phone number already exists")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final userId = prefs.getString("userId");

      if (token == null || userId == null) return;

      final isEdit = widget.contact != null;

      final url = isEdit
          ? "$baseUrl/api/users/contacts/$userId/${widget.contact!["id"]}"
          : "$baseUrl/api/users/contacts/$userId";

      final method = isEdit ? http.put : http.post;

      final response = await method(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": nameController.text.trim(),
          "phoneNumber": formattedPhone,
          "relation": relationController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop(context);
        await widget.onAdded();
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: roseLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: roseBorder,
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
                color: roseText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            _inputField(
              controller: nameController,
              hint: "Name",
              icon: Icons.person,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s]")),
              ],
            ),

            const SizedBox(height: 14),

            _inputField(
              controller: phoneController,
              hint: "Phone Number",
              icon: Icons.phone,
              keyboard: TextInputType.phone,
              maxLength: 10,
              formatters: [FilteringTextInputFormatter.digitsOnly],
            ),

            const SizedBox(height: 14),

            _inputField(
              controller: relationController,
              hint: "Relation (Mother, Sister…)",
              icon: Icons.family_restroom,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isFormValid ? saveContact : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: rosePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  widget.contact == null ? "Save Contact" : "Update Contact",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      maxLength: maxLength,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: rosePrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: roseBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: rosePrimary, width: 2),
        ),
      ),
    );
  }
}
