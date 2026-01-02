import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'add_contact_sheet.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final String baseUrl = "http://192.168.1.6:8080";
  List contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    setState(() => isLoading = true);

    final response = await http.get(
      Uri.parse("$baseUrl/api/user/emergency-contacts"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      setState(() {
        contacts = jsonDecode(response.body);
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> deleteContact(String id) async {
    await http.delete(
      Uri.parse("$baseUrl/api/user/emergency-contacts/$id"),
    );
    fetchContacts();
  }

  void showAddContactSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddContactSheet(onAdded: fetchContacts),
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
            onPressed: contacts.length >= 15 ? null : showAddContactSheet,
          )
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
            leading: const Icon(Icons.person, color: Colors.white),
            title: Text(
              c["name"],
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              c["phone"],
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteContact(c["id"]),
            ),
          );
        },
      ),
    );
  }
}
