import 'package:flutter/material.dart';

import '../../services/safety_api_service.dart';

class PreAlertScreen extends StatelessWidget {
  const PreAlertScreen({super.key});

  static const bgPink = Color(0xFFFFF1F5);
  static const primaryPink = Color(0xFFF06292);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🚫 disable back
      child: Scaffold(
        backgroundColor: bgPink,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  size: 70,
                  color: Colors.redAccent,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Pre-Alert Active",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "You said you feel unsafe.\nIf you don’t cancel, SOS may be triggered.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 40),

                // ⏱ Countdown (visual only)
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.redAccent,
                      width: 4,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "60",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () async {
                      await SafetyApiService.sendEvent(
                        event: "CANCEL_PRE_ALERT",
                      );

                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryPink),
                    ),
                    child: const Text(
                      "Cancel Pre-Alert",
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
