import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/screens/login_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  // Future<void> _navigateNext() async {
  //   // Small delay just to show logo smoothly (optional)
  //   await Future.delayed(const Duration(milliseconds: 500));
  //
  //   final prefs = await SharedPreferences.getInstance();
  //   final onboardingDone = prefs.getBool("onboarding_done") ?? false;
  //   final token = prefs.getString("token");
  //
  //   if (!mounted) return;
  //
  //   if (!onboardingDone) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const OnboardingScreen()),
  //     );
  //   } else if (token != null && token.isNotEmpty) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const HomeScreen()),
  //     );
  //   } else {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const LoginScreen()),
  //     );
  //   }
  // }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final isOnboardingDone = prefs.getBool("onboarding_done") ?? false;
    final token = prefs.getString("token");

    if (!mounted) return;

    if (!isOnboardingDone) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          "assets/images/logo/logo.png",
          width: 220, // balanced size
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
