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

    final bool onboardingDone =
        prefs.getBool("onboarding_done") ?? false;

    final String? token = prefs.getString("token");

    // small delay only for smooth UX
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // 1️⃣ First-time user → onboarding
    if (!onboardingDone) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
      );
      return;
    }

    // 2️⃣ Logged-out user → login
    if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      return;
    }

    // 3️⃣ Logged-in user (restart case) → home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
