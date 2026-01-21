import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'add_contact_sheet.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final String baseUrl = "http://192.168.1.6:8082";
  List contacts = [];
  bool isLoading = true;

  // 🌸 theme colors
  static const rosePrimary = Color(0xFFF06292);
  static const roseLight   = Color(0xFFFFEBF0);
  static const roseBorder  = Color(0xFFF8BBD0);
  static const roseText    = Color(0xFFAD1457);

  // ---------- helpers ----------
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  // ---------- API ----------
  Future<void> fetchContacts() async {
    setState(() => isLoading = true);

    final token = await _getToken();
    final userId = await _getUserId();

    if (token == null || userId == null) {
      setState(() => isLoading = false);
      return;
    }

    final response = await http.get(
      Uri.parse("$baseUrl/api/users/contacts/$userId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        contacts = jsonDecode(response.body);
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> deleteContact(String contactId) async {
    final token = await _getToken();
    final userId = await _getUserId();

    if (token == null || userId == null) {
      _showSnack("Session expired. Please login again.");
      return;
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/api/users/contacts/$userId/$contactId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      await fetchContacts();
    } else {
      _showSnack("Failed to delete contact");
    }
  }

  void _confirmDelete(String contactId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Contact"),
        content: const Text(
          "At least one emergency contact is required.\nAre you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteContact(contactId);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: roseLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => AddContactSheet(
        existingNumbers:
        contacts.map<String>((c) => c["phoneNumber"] as String).toList(),
        onAdded: fetchContacts,
      ),
    ).then((_) => fetchContacts());
  }

  void openEditSheet(Map<String, dynamic> contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: roseLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => AddContactSheet(
        contact: contact,
        existingNumbers:
        contacts.map<String>((c) => c["phoneNumber"] as String).toList(),
        onAdded: fetchContacts,
      ),
    ).then((_) => fetchContacts());
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final canDelete = contacts.length > 1;

    return Scaffold(
      backgroundColor: roseLight,
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.white,
        foregroundColor: roseText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: rosePrimary),
            onPressed: contacts.length >= 15 ? null : openAddSheet,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : contacts.isEmpty
          ? const Center(
        child: Text(
          "No emergency contacts added",
          style: TextStyle(color: roseText),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: contacts.length,
        itemBuilder: (_, i) {
          final c = contacts[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: roseBorder),
              boxShadow: [
                BoxShadow(
                  color: roseBorder.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: roseLight,
                  child: const Icon(Icons.person, color: rosePrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c["name"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${c["relation"]} • ${c["phoneNumber"]}",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: rosePrimary),
                  onPressed: () => openEditSheet(c),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: canDelete ? Colors.red : Colors.grey,
                  ),
                  onPressed: canDelete
                      ? () => _confirmDelete(c["id"].toString())
                      : () => _showSnack(
                      "At least one contact is required"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
