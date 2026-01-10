import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  final String baseUrl = "http://10.218.102.76:8080";//"http://192.168.1.6:8080"

  bool canResend = false;
  int secondsRemaining = 60;
  Timer? _timer;

  // 🔹 START TIMER
  void startResendTimer() {
    _timer?.cancel(); // cancel old timer if any

    setState(() {
      canResend = false;
      secondsRemaining = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        timer.cancel();
        setState(() {
          canResend = true;
        });
      } else {
        setState(() {
          secondsRemaining--;
        });
      }
    });
  }

  Future<void> sendOtp() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Reset password link has been sent to your email.\nPlease check your inbox.",
            ),
          ),
        );

        // 🔥 THIS WAS MISSING
        startResendTimer();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel(); // 🔥 VERY IMPORTANT
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // 🔹 Title
            const Text(
              "Forget Password",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 Description
            const Text(
              "Please enter your email to receive a\nconfirmation code to set a new password",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 40),

            // 🔹 Email Field
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Email",
                  hintStyle: TextStyle(color: Colors.white54),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Send Code Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD400),
                  disabledBackgroundColor: const Color(0xFFFFD400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
                    : const Text(
                  "Send Code",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Resend Timer
            TextButton(
              onPressed: canResend ? sendOtp : null,
              child: Text(
                canResend
                    ? "Resend Email"
                    : "Resend in 00:${secondsRemaining.toString().padLeft(2, '0')}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
