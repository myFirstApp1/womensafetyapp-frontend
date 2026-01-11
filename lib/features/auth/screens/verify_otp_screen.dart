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

  int secondsRemaining = 192; // 03:12
  Timer? _timer;

  bool isVerifying = false;
  bool isResending = false;

  final String baseUrl = "http://10.218.102.76:8080";

  late String txnId; // mutable txnId

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

      print("OTP VERIFY RESPONSE => ${response.body}");

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email verified successfully")),
        );

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        final decoded = jsonDecode(response.body);
        final msg =
            decoded["data"]?["message"] ?? "Invalid OTP";
        _showError(msg);
      }
    } catch (e) {
      _showError("Something went wrong. Try again.");
    } finally {
      if (mounted) {
        setState(() => isVerifying = false);
      }
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
          "channel": "EMAIL", // ✅ FIX 1
        }),
      );

      print("RESEND OTP RESPONSE => ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // ✅ FIX 2: correct txnId path
        final newTxnId = decoded["data"]?["data"]?["txnId"];
        if (newTxnId != null && newTxnId.toString().isNotEmpty) {
          txnId = newTxnId;
        }

        setState(() => secondsRemaining = 192);
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
      if (mounted) {
        setState(() => isResending = false);
      }
    }
  }


  // ---------------- HELPERS ----------------
  void _showError(String msg) {
    if (!mounted) return;
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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------- UI ----------------
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
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, _otpBox),
            ),

            const SizedBox(height: 20),

            Text(
              "Code expires in : $formattedTime",
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                isOtpComplete && !isVerifying ? verifyOtp : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
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

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed:
                secondsRemaining == 0 && !isResending
                    ? resendOtp
                    : null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
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
