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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    if (token == null || userId == null) {
      _showSnack("Failed to delete contact");
      return;
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/api/users/contacts/$userId/$contactId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      await fetchContacts(); // ✅ refresh list
    } else {
      print("DELETE FAILED → ${response.statusCode} ${response.body}");
      _showSnack("Failed to delete contact");
    }
  }


  void openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddContactSheet(
        onAdded: () async => await fetchContacts(),
      ),
    );
  }

  void openEditSheet(Map<String, dynamic> contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddContactSheet(
        contact: contact,
        onAdded: () async => await fetchContacts(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = contacts.length > 1;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (_, i) {
          final c = contacts[i];
          return ListTile(
            leading:
            const Icon(Icons.person, color: Colors.white),
            title: Text(
              c["name"],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "${c["relation"]} • ${c["phoneNumber"]}",
              style:
              const TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit,
                      color: Colors.amber),
                  onPressed: () => openEditSheet(c),
                ),
                Tooltip(
                  message: canDelete
                      ? "Delete contact"
                      : "At least one contact is required",
                  child: IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: contacts.length > 1 ? Colors.red : Colors.grey,
                    ),
                    onPressed: contacts.length > 1
                        ? () => deleteContact(c["id"].toString())
                        : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("At least one contact is required"),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
