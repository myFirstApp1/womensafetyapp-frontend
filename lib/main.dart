import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/app_start_screen.dart';
import 'features/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Women Safety App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppStartScreen(),
    );
  }
}
