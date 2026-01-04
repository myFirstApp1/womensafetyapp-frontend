import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  int secondsRemaining = 192; // 03:12
  Timer? _timer;
  bool isVerifying = false;
  bool isResending = false;

  final String baseUrl = "http://192.168.1.6:8080"; // auth-service


  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  Future<void> verifyOtp() async {
    if (!isOtpComplete) return;

    setState(() => isVerifying = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp": otp,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email verified successfully")),
        );

        // 👉 Navigate next (Login / Reset Password / Home)
        // Navigator.pushReplacement(...);

      } else {
        final msg = jsonDecode(response.body)["message"] ?? "Invalid OTP";
        _showError(msg);
      }
    } catch (e) {
      _showError("Something went wrong. Try again.");
    }

    setState(() => isVerifying = false);
  }

  Future<void> resendOtp() async {
    setState(() => isResending = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/resend-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => secondsRemaining = 192);
        startTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP resent successfully")),
        );
      } else {
        _showError("Failed to resend OTP");
      }
    } catch (e) {
      _showError("Network error");
    }

    setState(() => isResending = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  String get formattedTime {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  String get otp =>
      _controllers.map((c) => c.text).join();

  bool get isOtpComplete => otp.length == 6;

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            const Text(
              "Verify Your Email",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Enter the 6-digit code sent to\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 OTP BOXES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return _otpBox(i);
              }),
            ),

            const SizedBox(height: 20),

            Text(
              "Code expires in : $formattedTime",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 40),

            // 🔹 CONFIRM BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isOtpComplete && !isVerifying ? verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  disabledBackgroundColor:
                  const Color(0xFFD4AF37).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isVerifying
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Confirm Code"),
              ),
            ),

            const SizedBox(height: 14),

            // 🔹 RESEND
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: secondsRemaining == 0 && !isResending ? resendOtp : null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isResending
                    ? const CircularProgressIndicator()
                    : const Text("Resend Code"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 OTP BOX WIDGET
  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: const Color(0xFF1C1C1C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (v.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }
}
