import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vibewrite_app/pages/home.dart';
import 'package:vibewrite_app/pages/splash.dart';
import 'package:vibewrite_app/pages/login.dart';
import 'package:vibewrite_app/pages/signup.dart';
import 'package:vibewrite_app/pages/welcome.dart';
import 'package:vibewrite_app/services/firebase_options.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeWrite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
