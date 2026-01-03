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
      contacts = jsonDecode(response.body);
    }

    setState(() => isLoading = false);
  }

  Future<void> deleteContact(String id) async {
    final token = await _getToken();
    final userId = await _getUserId();

    if (token == null || userId == null) return;

    await http.delete(
      Uri.parse("$baseUrl/api/users/contacts/$userId/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    await fetchContacts();
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
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Colors.red),
                  onPressed: () => deleteContact(c["id"]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
