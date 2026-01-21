import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/screens/login_screen.dart';
import '../home/home_screen.dart';
import 'onboarding_screen.dart';

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  @override
  void initState() {
    super.initState();
    _decideStartScreen();
  }

  Future<void> _decideStartScreen() async {
    final prefs = await SharedPreferences.getInstance();

    final onboardingDone = prefs.getBool("onboarding_done") ?? false;
    final token = prefs.getString("token");

    await Future.delayed(const Duration(milliseconds: 300)); // smooth UX

    if (!mounted) return;

    if (!onboardingDone) {
      // 1️⃣ First time user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (token == null || token.isEmpty) {
      // 2️⃣ Logged out user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // 3️⃣ Logged in user
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // simple splash
      ),
    );
  }
}
