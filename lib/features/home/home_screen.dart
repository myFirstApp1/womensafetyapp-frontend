import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/safety_api_service.dart';
import '../userprofile/emergency_contacts_screen.dart';
import '../userprofile/profile_screen.dart';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/services.dart';




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
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);

  int _shakeCount = 0;
  DateTime _firstShakeTime =
  DateTime.fromMillisecondsSinceEpoch(0);
  static const double shakeThreshold = 18.0;
  static const int shakeCooldownMs = 800;      // gap between shakes
  static const int shakeWindowMs = 3000;       // total window for 3 shakes


  // 🎨 THEME COLORS
  static const bgPink = Color(0xFFFFF1F5);
  static const softPink = Color(0xFFFFE4EC);
  static const primaryPink = Color(0xFFF06292);
  static const textDark = Color(0xFF333333);


  @override
  void initState() {
    super.initState();
    _restoreState();
    _initLocation();
    _fetchUserProfile();
    _startShakeListener();
    //_syncWithBackend();
  }

  Future<void> _restoreState() async {
    final state = await SafetyApiService.getCurrentState();

    if (!mounted) return;

    if (state == "PRE_ALERT") {
      Navigator.pushNamed(context, '/pre-alert');
    } else if (state == "SOS_ACTIVE") {
      Navigator.pushNamed(context, '/sos-active');
    }
  }


  void _startShakeListener() {
    _accelSub = accelerometerEvents.listen((event) {
      final now = DateTime.now();

      // prevent noise
      if (now.difference(_lastShakeTime).inMilliseconds <
          shakeCooldownMs) {
        return;
      }

      final double x = event.x;
      final double y = event.y;
      final double z = event.z;

      final double acceleration =
      math.sqrt(x * x + y * y + z * z);

      if (acceleration < shakeThreshold) return;

      _lastShakeTime = now;

      // First shake
      if (_shakeCount == 0) {
        _firstShakeTime = now;
      }

      _shakeCount++;

      // Too slow → reset
      if (now.difference(_firstShakeTime).inMilliseconds >
          shakeWindowMs) {
        _resetShake();
        return;
      }

      debugPrint("📳 Shake $_shakeCount detected");

      // 🎯 SUCCESS: 3 shakes
      if (_shakeCount == 3) {
        _onTripleShake();
        _resetShake();
      }
    });
  }

  // Future<void> _syncWithBackend() async {
  //   final state = await SafetyApiService.getStatus(userId);
  //
  //   if (state == "PRE_ALERT") {
  //     Navigator.pushNamed(context, '/pre-alert');
  //   } else if (state == "SOS_ACTIVE") {
  //     Navigator.pushNamed(context, '/sos-active');
  //   }
  // }

  Future<void> _onTripleShake() async {
    await SafetyApiService.sendEvent(
      event: "PHONE_SHAKE_DETECTED",
    );

    Navigator.pushNamed(context, '/sos-active');
  }



  void _resetShake() {
    _shakeCount = 0;
    _firstShakeTime =
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _onPhoneShake() {
    debugPrint("📳 PHONE SHAKE DETECTED");

    // 🔔 EVENT ONLY (later)
    // SafetyApiService.sendEvent("PHONE_SHAKE");

    // ❌ No navigation
    // ❌ No SOS trigger
    // ❌ No state change
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
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
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted =
      await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      final locationData = await _location.getLocation();

      if (!mounted) return;

      setState(() {
        _currentLatLng = LatLng(
          locationData.latitude ?? 12.9716,
          locationData.longitude ?? 77.5946,
        );
        _isLoadingLocation = false;
      });
    } catch (_) {
      _isLoadingLocation = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 HEADER
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
                    _fetchUserProfile();
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: softPink,
                      backgroundImage: profileImageUrl != null &&
                          profileImageUrl!.startsWith("http")
                          ? NetworkImage(profileImageUrl!)
                          : const AssetImage(
                          "assets/images/avatar.png")
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
                            color: textDark,
                          ),
                        ),
                         Text(
                          "Stay Safe",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 MAP
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: _isLoadingLocation || _currentLatLng == null
                      ? const Center(
                    child: CircularProgressIndicator(),
                  )
                      : FlutterMap(
                    options: MapOptions(
                      initialCenter: _currentLatLng!, // now SAFE
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: "com.example.womensafetyapp",
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

              // 🔹 SOS
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/sos-active');

                    SafetyApiService.sendEvent(
                      event: "SOS_BUTTON_PRESSED",
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 30,
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
              ),

              const SizedBox(height: 30),

              // 🔹 ACTION GRID
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _ActionCard(
                    icon: Icons.notifications_active,
                    label: "Pre-Alert",
                      onTap: () async {
                        await SafetyApiService.sendEvent(
                          event: "PRE_ALERT_BUTTON_PRESSED",
                        );

                        Navigator.pushNamed(context, '/pre-alert');
                      }
                  ),
                  _ActionCard(
                    icon: Icons.my_location,
                    label: "Share Location",
                  ),
                  _ActionCard(
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
                          builder: (_) =>
                          const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 🔹 AI COMPANION
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.smart_toy,
                            color: primaryPink),
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
                      style:
                      TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "No, thanks",
                            style:
                            TextStyle(color: textDark),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            primaryPink,
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

// ---------------- ACTION CARD ----------------

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  static const softPink = Color(0xFFFFE4EC);
  static const primaryPink = Color(0xFFF06292);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: softPink,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 32, color: primaryPink),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
