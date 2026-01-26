import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:womensafetyapp/features/sos/sos_countdown_dialog.dart';


class SosActiveScreen extends StatefulWidget {
  const SosActiveScreen({super.key});

  @override
  State<SosActiveScreen> createState() => _SosActiveScreenState();
}
class _SosActiveScreenState extends State<SosActiveScreen> {


  @override
  void initState() {
    super.initState();
    _keepScreenAwake();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSosCountdown();
    });
  }

  Future<void> _showSosCountdown() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SosCountdownDialog(),
    );

    // User cancelled
    if (confirmed == false) {
      Navigator.pop(context); // back to Home
      return;
    }

    // Timer finished → SOS confirmed
    if (confirmed == true) {
      debugPrint("🚨 SOS CONFIRMED AFTER 60s");

      // 🔔 Later:
      // SafetyApiService.sendEvent(event: "SOS_CONFIRMED");
    }
  }


  Future<void> _keepScreenAwake() async {
    await WakelockPlus.enable();
  }

  @override
  void dispose() {
    _releaseScreen();
    super.dispose();
  }

  Future<void> _releaseScreen() async {
    await WakelockPlus.disable();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🚫 disable back
      child: Scaffold(
        backgroundColor: const Color(0xFF8B0000),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "SOS ACTIVE",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Help is being alerted.\nStay calm and keep the app open.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🚫 disable back button
      child: Scaffold(
        backgroundColor: const Color(0xFF8B0000), // deep red
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // 🔴 SOS indicator
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 20,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'SOS ACTIVE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Help is being alerted.\nStay calm. Keep the app open.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // ❌ No cancel button for now
                // (backend will decide later)
              ],
            ),
          ),
        ),
      ),
    );
  }

