import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class AddContactSheet extends StatefulWidget {
  final VoidCallback onAdded;

  const AddContactSheet({super.key, required this.onAdded});

  @override
  State<AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<AddContactSheet> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool isSaving = false;

  final String baseUrl = "http://192.168.1.6:8080";

  Future<void> saveContact() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) return;

    setState(() => isSaving = true);

    await http.post(
      Uri.parse("$baseUrl/api/user/emergency-contacts"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
      }),
    );

    widget.onAdded();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Add Emergency Contact",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: "Name",
              filled: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: "Phone Number",
              filled: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: isSaving ? null : saveContact,
              child: isSaving
                  ? const CircularProgressIndicator()
                  : const Text("Save"),
            ),
          ),
        ],
      ),
    );
  }
}
