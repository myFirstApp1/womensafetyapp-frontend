import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import 'verify_otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool loading = false;

  // 🔴 DO NOT CHANGE THIS METHOD
  Future<void> registerUser() async {
    final username = usernameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();
    final confirmPassword = confirmPassCtrl.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showSnack("All fields are required");
      return;
    }

    if (password != confirmPassword) {
      showSnack("Passwords do not match");
      return;
    }

    setState(() => loading = true);

    const baseUrl = "http://192.168.1.6:8080";//"http://10.218.102.76:8080";
    final url = Uri.parse("$baseUrl/api/auth/register");

    try {
      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      )
          .timeout(const Duration(seconds: 10));

      setState(() => loading = false);

      print("🟢 REGISTER STATUS: ${response.statusCode}");
      print("🟢 REGISTER BODY: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);

// ✅ CORRECT extraction (3-level deep)
        final txnId =
        decoded["data"]?["data"]?["txnId"];

        final emailMessage =
        decoded["data"]?["data"]?["message"];

        if (txnId == null || txnId
            .toString()
            .isEmpty) {
          print("❌ Full register response: $decoded");
          showSnack("OTP transaction id missing. Please try again.");
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailMessage ?? "Please verify OTP"),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VerifyOtpScreen(
                  email: email,
                  txnId: txnId,
                ),
          ),
        );
      }
      else {
        String errorMessage = "Registration failed";
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data["message"] != null) {
            errorMessage = data["message"];
          }
        } catch (_) {}

        showSnack(errorMessage);
      }
    } catch (e) {
      setState(() => loading = false);
      showSnack("Something went wrong. Please try again.");
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // 🔵 UI UPDATED ONLY BELOW
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Text(
                "AuraGuard",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Your Safety, Secured",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 24),

              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black12.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _label("Username"),
              _inputField(
                controller: usernameCtrl,
                hint: "Enter your username",
              ),

              const SizedBox(height: 18),

              _label("Email"),
              _inputField(
                controller: emailCtrl,
                hint: "Enter your email address",
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              _label("Password"),
              _inputField(
                controller: passCtrl,
                hint: "Enter your password",
                obscure: true,
              ),

              const SizedBox(height: 18),

              _label("Confirm Password"),
              _inputField(
                controller: confirmPassCtrl,
                hint: "Re-enter your password",
                obscure: true,
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text.rich(
                TextSpan(
                  text: "By signing up, you agree to our ",
                  children: [
                    TextSpan(
                      text: "Terms",
                      style: TextStyle(color: Color(0xFFD4AF37)),
                    ),
                    TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(color: Color(0xFFD4AF37)),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w500),
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
