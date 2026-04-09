import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/safety_api_service.dart';

class PreAlertScreen extends StatefulWidget {
  const PreAlertScreen({super.key});

  @override
  State<PreAlertScreen> createState() => _PreAlertScreenState();
}

class _PreAlertScreenState extends State<PreAlertScreen> {
  bool isMonitoring = false;
  int selectedMinutes = 5;
  int secondsRemaining = 0;
  Timer? timer;

  void startMonitoring() async {
    await SafetyApiService.sendEvent(
      event: "PRE_ALERT_STARTED",
      durationMinutes: selectedMinutes,
    );

    setState(() {
      isMonitoring = true;
      secondsRemaining = selectedMinutes * 60;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        t.cancel();
        triggerSOS();
      }
    });
  }

  Future<void> cancelPreAlert() async {
    await SafetyApiService.sendEvent(event: "PRE_ALERT_CANCELLED");

    timer?.cancel();
    Navigator.pop(context);
  }

  Future<void> triggerSOS() async {
    await SafetyApiService.sendEvent(event: "SOS_TRIGGERED");

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/sos-active');
  }

  String get timerText {
    int m = secondsRemaining ~/ 60;
    int s = secondsRemaining % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3CD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: isMonitoring
                ? _buildMonitoringUI()
                : _buildSetupUI(),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: Colors.orange, size: 80),
        const SizedBox(height: 20),
        const Text(
          "PRE-ALERT",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text("Select how long you want us to monitor you."),
        const SizedBox(height: 30),

        DropdownButtonFormField<int>(
          value: selectedMinutes,
          items: [5, 10, 15, 30, 60]
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text("$e Minutes"),
          ))
              .toList(),
          onChanged: (val) {
            setState(() => selectedMinutes = val!);
          },
          decoration: const InputDecoration(
            labelText: "Monitoring Time",
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: startMonitoring,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("Start Monitoring"),
          ),
        ),

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
      ],
    );
  }

  Widget _buildMonitoringUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning_amber_rounded,
            color: Colors.orange, size: 80),
        const SizedBox(height: 20),
        const Text(
          "PRE-ALERT ACTIVE",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Text(
          timerText,
          style: const TextStyle(
              fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: cancelPreAlert,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text("I'm Safe"),
          ),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
//
// import '../../services/safety_api_service.dart';
//
// class PreAlertScreen extends StatelessWidget {
//   const PreAlertScreen({super.key});
//
//   static const bgPink = Color(0xFFFFF1F5);
//   static const primaryPink = Color(0xFFF06292);
//
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async => false, // 🚫 disable back
//       child: Scaffold(
//         backgroundColor: bgPink,
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.warning_rounded,
//                   size: 70,
//                   color: Colors.redAccent,
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 const Text(
//                   "Pre-Alert Active",
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//
//                 const SizedBox(height: 12),
//
//                 const Text(
//                   "You said you feel unsafe.\nIf you don’t cancel, SOS may be triggered.",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.black54),
//                 ),
//
//                 const SizedBox(height: 40),
//
//                 // ⏱ Countdown (visual only)
//                 Container(
//                   width: 160,
//                   height: 160,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white,
//                     border: Border.all(
//                       color: Colors.redAccent,
//                       width: 4,
//                     ),
//                   ),
//                   child: const Center(
//                     child: Text(
//                       "60",
//                       style: TextStyle(
//                         fontSize: 48,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.redAccent,
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 30),
//
//                 SizedBox(
//                   width: double.infinity,
//                   height: 52,
//                   child: OutlinedButton(
//                     onPressed: () async {
//                       await SafetyApiService.sendEvent(
//                         event: "CANCEL_PRE_ALERT",
//                       );
//
//                       Navigator.pop(context);
//                     },
//                     style: OutlinedButton.styleFrom(
//                       side: const BorderSide(color: primaryPink),
//                     ),
//                     child: const Text(
//                       "Cancel Pre-Alert",
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: primaryPink,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
