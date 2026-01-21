import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:womensafetyapp/features/auth/screens/verify_otp_screen.dart';

import '../../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool loading = false;

  // 🔴 DO NOT CHANGE LOGIC BELOW
  Future<void> loginUser() async {
    final username = usernameCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showSnack("Username and password are required");
      return;
    }

    setState(() => loading = true);

    const baseUrl = "http://192.168.1.6:8080";//"http://10.218.102.76:8080";
    final url = Uri.parse("$baseUrl/api/auth/login");

    try {
      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint("LOGIN STATUS: ${response.statusCode}");
      debugPrint("LOGIN BODY: ${response.body}");

      setState(() => loading = false);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final data1 = body["data"];
        if (data1 == null) {
          showSnack("Invalid response");
          return;
        }

        final data2 = data1["data"];
        if (data2 == null) {
          showSnack("Invalid response");
          return;
        }

        final token = data2["token"];
        final userId = data2["userId"];
        final txnId = data2["txnId"];

        final prefs = await SharedPreferences.getInstance();

// 🔥 TEMP store email for OTP screen
// Backend uses email, not username
        await prefs.setString("pendingEmail", "${usernameCtrl.text.trim()}@gmail.com");

        final email = prefs.getString("pendingEmail");

// 🔁 UNVERIFIED USER → GO TO OTP
        if ((token == null || token.toString().isEmpty) &&
            txnId != null &&
            txnId.toString().isNotEmpty) {

          if (email == null || email.isEmpty) {
            showSnack("Email not found. Please register again.");
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please verify OTP before login")),
          );

          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyOtpScreen(
                email: email,                // ✅ now non-null
                txnId: txnId.toString(),
              ),
            ),
          );
          return;
        }

//  Handle login success properly
        await handleLoginSuccess(
          token: token,
          userId: userId,
        );

        showSnack("Login successful");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      showSnack("Network or unexpected error occurred");
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> handleLoginSuccess({
    required String token,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 🔥 ALWAYS clear first (even same account)
    await prefs.clear();

    // Optional but recommended
    await prefs.setBool("isLoggedIn", true);

    // Decode JWT
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    // Extract email (sub)
    String email = decodedToken['sub'];

    // 🔥 Store latest values
    await prefs.setString("token", token);
    await prefs.setString("userId", userId);
    await prefs.setString("email", email);

    debugPrint("Stored Email: $email");
    print("✅ Stored userId: ${prefs.getString("userId")}");
    print("✅ Stored email : ${prefs.getString("email")}");

  }

  // 🔵 UI STARTS HERE
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

              // Title
              const Text(
                "AuraGuard",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Your Safety, Secured",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 24),

              // Login | Sign Up Toggle
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.black12.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Center(
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Username
              const Text("Username",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(
                  hintText: "Enter your username",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Password
              const Text("Password",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon:
                  const Icon(Icons.visibility_off, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text("Forgot Password?"),
                ),
              ),

              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : loginUser,
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
                    "Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("or"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              // Apple Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Sign in with Apple",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Google Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Sign in with Google",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
