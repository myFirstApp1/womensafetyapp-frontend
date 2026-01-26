import 'dart:async';
import 'package:flutter/material.dart';

class SosCountdownDialog extends StatefulWidget {
  const SosCountdownDialog({super.key});

  @override
  State<SosCountdownDialog> createState() => _SosCountdownDialogState();
}

class _SosCountdownDialogState extends State<SosCountdownDialog> {
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        Navigator.pop(context, true); // confirmed
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _cancel() {
    _timer?.cancel();
    Navigator.pop(context, false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Confirm SOS",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Text(
              "$_secondsLeft",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 12),
            const Text(
              "SOS will be triggered automatically.\nTap cancel if this was accidental.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            OutlinedButton(
              onPressed: _cancel,
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
