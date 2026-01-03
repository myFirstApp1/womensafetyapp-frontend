import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../userprofile/emergency_contacts_screen.dart';
import '../userprofile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? _currentLatLng;
  bool _isLoadingLocation = true;

  final Location _location = Location();
  String userName = "User";
  String? profileImageUrl;


  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchUserProfile();
  }

Future<void> _fetchUserProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getString("userId");

    if (token == null || userId == null) return;

    final url =
        Uri.parse("http://192.168.1.6:8082/api/users/$userId");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        userName = data["name"] ?? "User";
        profileImageUrl = data["profilePictureUrl"];
      });
    }
  } catch (e) {
    debugPrint("HOME PROFILE FETCH ERROR: $e");
  }
}

  Future<void> _initLocation() async {
    try {
      // 1️⃣ Ensure service ON
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          _stopLoading();
          return;
        }
      }

      // 2️⃣ Permission
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _stopLoading();
          return;
        }
      }

      // 3️⃣ Get location
      final locationData = await _location.getLocation();

      if (!mounted) return;

      setState(() {
        _currentLatLng = LatLng(
          locationData.latitude ?? 12.9716, // fallback: Bangalore
          locationData.longitude ?? 77.5946,
        );
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint("Location error: $e");
      _stopLoading();
    }
  }

  void _stopLoading() {
    if (!mounted) return;
    setState(() => _isLoadingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Header
              InkWell(
                borderRadius: BorderRadius.circular(16),
               onTap: () async {
               final updated = await Navigator.push<bool>(
               context,
               MaterialPageRoute(
               builder: (_) => const ProfileScreen(),
               ),
               );
              if (updated == true) {
              _fetchUserProfile(); // refresh Home
              }
               },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: profileImageUrl != null &&
                          profileImageUrl!.isNotEmpty &&
                          profileImageUrl!.startsWith("http")
                          ? NetworkImage(profileImageUrl!)
                          : const AssetImage("assets/images/avatar.png")
                      as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(
                        "Hello, $userName",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                        const Text(
                          "Stay Safe",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 MAP SECTION (UPDATED)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _isLoadingLocation
                      ? const Center(child: CircularProgressIndicator())
                      : _currentLatLng == null
                      ? Image.network(
                    // 🔥 INTERNET TEST (IMPORTANT)
                    "https://tile.openstreetmap.org/5/15/10.png",
                    fit: BoxFit.cover,
                  )
                      : FlutterMap(
                    options: MapOptions(
                      initialCenter: _currentLatLng!,
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName:
                        "com.example.womensafetyapp",
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLatLng!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 SOS Button
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "SOS",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Action Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  const _ActionCard(
                    icon: Icons.notifications_active,
                    label: "Pre-Alert",
                  ),
                  const _ActionCard(
                    icon: Icons.my_location,
                    label: "Share Location",
                  ),
                  const _ActionCard(
                    icon: Icons.call,
                    label: "Fake Call",
                  ),
                  _ActionCard(
                    icon: Icons.group,
                    label: "Contacts",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 🔹 AI Companion
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.smart_toy,
                            color: Color(0xFFD4AF37)),
                        SizedBox(width: 8),
                        Text(
                          "AI Companion",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Want me to check on you in 10 min?",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text("No, thanks"),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFFD4AF37),
                          ),
                          child: const Text("Yes, please"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// ---------------- Action Card Widget ----------------

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap; // ✅ added

  const _ActionCard({
    required this.icon,
    required this.label,
    this.onTap, // ✅ added
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // ✅ wrap with InkWell
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFFD4AF37)),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
