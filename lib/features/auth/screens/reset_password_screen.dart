import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'password_success_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

enum PasswordStrength { weak, medium, strong }

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  PasswordStrength _passwordStrength = PasswordStrength.weak;

  final String baseUrl = "http://192.168.1.6:8080";

  // 🔹 Password strength logic (UNCHANGED)
  PasswordStrength checkStrength(String password) {
    if (password.length < 8) return PasswordStrength.weak;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial =
    password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasUpper && hasNumber && hasSpecial) {
      return PasswordStrength.strong;
    }
    return PasswordStrength.medium;
  }

  Color strengthColor() {
    switch (_passwordStrength) {
      case PasswordStrength.strong:
        return Colors.green;
      case PasswordStrength.medium:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String strengthText() {
    switch (_passwordStrength) {
      case PasswordStrength.strong:
        return "Strong password";
      case PasswordStrength.medium:
        return "Medium password";
      default:
        return "Weak password";
    }
  }

  Future<void> resetPassword() async {
    if (_passwordStrength != PasswordStrength.strong) {
      _showMessage("Please choose a strong password");
      return;
    }

    if (passwordController.text != confirmController.text) {
      _showMessage("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": widget.token,
          "newPassword": passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const PasswordSuccessScreen(),
          ),
              (route) => false,
        );
      } else {
        _showMessage("Reset password failed");
      }
    } catch (e) {
      _showMessage("Something went wrong");
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              "Create New Password",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Your new password must be strong and secure",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 30),

            _passwordField(
              controller: passwordController,
              hint: "New Password",
              visible: showPassword,
              toggle: () => setState(() => showPassword = !showPassword),
              onChanged: (value) {
                setState(() {
                  _passwordStrength = checkStrength(value);
                });
              },
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _passwordStrength == PasswordStrength.weak
                        ? 0.33
                        : _passwordStrength == PasswordStrength.medium
                        ? 0.66
                        : 1.0,
                    backgroundColor: Colors.pink.shade100,
                    valueColor:
                    AlwaysStoppedAnimation(strengthColor()),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  strengthText(),
                  style: TextStyle(
                    color: strengthColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _passwordField(
              controller: confirmController,
              hint: "Confirm Password",
              visible: showConfirmPassword,
              toggle: () => setState(
                    () => showConfirmPassword = !showConfirmPassword,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ||
                    _passwordStrength != PasswordStrength.strong
                    ? null
                    : resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF06292),
                  disabledBackgroundColor: const Color(0xFFF8BBD0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  "Reset Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool visible,
    required VoidCallback toggle,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4EC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon:
          const Icon(Icons.lock_outline, color: Color(0xFFF06292)),
          suffixIcon: IconButton(
            icon: Icon(
              visible ? Icons.visibility : Icons.visibility_off,
              color: Colors.black45,
            ),
            onPressed: toggle,
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }
}
