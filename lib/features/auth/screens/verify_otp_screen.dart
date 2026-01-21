import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final String txnId;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    required this.txnId,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  int secondsRemaining = 240;
  Timer? _timer;

  bool isVerifying = false;
  bool isResending = false;

  final String baseUrl = "http://192.168.1.6:8080";
  late String txnId;

  // 🎨 THEME COLORS
  static const bgPink = Color(0xFFFFF1F5);
  static const fieldPink = Color(0xFFFFE4EC);
  static const primaryPink = Color(0xFFF06292);
  static const textDark = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    txnId = widget.txnId;
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

  // ---------------- VERIFY OTP ----------------
  Future<void> verifyOtp() async {
    if (!isOtpComplete || isVerifying) return;

    setState(() => isVerifying = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/otp/verify"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "txnId": txnId,
          "code": otp,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email verified successfully")),
        );

        await Future.delayed(const Duration(milliseconds: 300));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        final decoded = jsonDecode(response.body);
        _showError(decoded["data"]?["message"] ?? "Invalid OTP");
      }
    } catch (_) {
      _showError("Something went wrong");
    } finally {
      setState(() => isVerifying = false);
    }
  }

  // ---------------- RESEND OTP ----------------
  Future<void> resendOtp() async {
    if (isResending) return;

    setState(() => isResending = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/otp/resend"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "channel": "EMAIL",
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final newTxnId = decoded["data"]?["data"]?["txnId"];
        if (newTxnId != null) txnId = newTxnId.toString();

        setState(() => secondsRemaining = 240);
        startTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP resent successfully")),
        );
      } else {
        _showError("Failed to resend OTP");
      }
    } catch (_) {
      _showError("Network error");
    } finally {
      setState(() => isResending = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String get formattedTime {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  String get otp => _controllers.map((c) => c.text).join();
  bool get isOtpComplete => otp.length == 6;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: textDark),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "Verify Your Email",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Enter the 6-digit code sent to\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, _otpBox),
            ),

            const SizedBox(height: 20),

            Text(
              "Code expires in : $formattedTime",
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                isOtpComplete && !isVerifying ? verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Confirm Code",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed:
                secondsRemaining == 0 && !isResending
                    ? resendOtp
                    : null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryPink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isResending
                    ? const CircularProgressIndicator()
                    : const Text(
                  "Resend Code",
                  style: TextStyle(color: primaryPink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: fieldPink,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
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
