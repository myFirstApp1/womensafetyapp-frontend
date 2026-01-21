import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddContactSheet extends StatefulWidget {
  final Future<void> Function() onAdded;
  final Map<String, dynamic>? contact; // edit mode
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
  final String baseUrl = "http://192.168.1.6:8082";//"http://10.218.102.76:8082";

  @override
  void initState() {
    super.initState();

    if (widget.contact != null) {
      nameController.text = widget.contact!["name"] ?? "";
      relationController.text = widget.contact!["relation"] ?? "";

      // 🔹 remove +91 when prefilling
      final phone = widget.contact!["phoneNumber"] ?? "";
      phoneController.text = phone.replaceFirst("+91", "");
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

    // DUPLICATE CHECK
    final isDuplicate = widget.existingNumbers.any(
          (p) =>
      p == formattedPhone &&
          p != widget.contact?["phoneNumber"],
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

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Please login again.")),
        );
        return;
      }

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
      ).timeout(const Duration(seconds: 10)); // ✅ CRITICAL FIX

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        Navigator.pop(context); // ✅ CLOSE SHEET
        await widget.onAdded(); // ✅ REFRESH LIST
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text("Failed to save contact (${response.statusCode})"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to connect to server"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false); // ✅ ALWAYS RESET
      }
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
              nameController,
              "Name",
              Icons.person,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[a-zA-Z\s]"),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _inputField(
              phoneController,
              "Phone Number",
              Icons.phone,
              keyboard: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),

            const SizedBox(height: 14),

            _inputField(
              relationController,
              "Relation (e.g. Brother, Mother)",
              Icons.family_restroom,
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isFormValid ? saveContact : null,
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

  Widget _inputField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        TextInputType keyboard = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
        int? maxLength,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          counterText: "",
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
