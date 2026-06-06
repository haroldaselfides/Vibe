import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vibewrite_app/pages/splash.dart';
import 'package:vibewrite_app/pages/login.dart';
import 'package:vibewrite_app/pages/signup.dart';
import 'package:vibewrite_app/pages/welcome.dart';
import 'package:vibewrite_app/pages/settings.dart';
import 'package:vibewrite_app/services/firebase_options.dart';
import 'theme/new_app_theme.dart';
import 'theme/app_typography.dart';
import 'widgets/navigation.dart';

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
      title: 'VIBEWRITE',
      debugShowCheckedModeBanner: false,
      color: AppTheme.backgroundColor, // Set background color for entire app
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('de', ''),
        Locale('zh', ''),
        Locale('ar', ''),
        Locale('ja', ''),
        Locale('ko', ''),
      ],
      theme: ThemeData(
        fontFamily: GoogleFonts.manrope().fontFamily,

        textTheme: TextTheme(
          displayLarge: AppTypography.headingXL,
          displayMedium: AppTypography.headingLg,
          headlineMedium: AppTypography.headingMd,
          titleLarge: AppTypography.headingSm,

          bodyLarge: AppTypography.bodyLg,
          bodyMedium: AppTypography.bodyMd,

          labelLarge: AppTypography.labelMd,
          labelMedium: AppTypography.labelSm,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        //'/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
         '/home': (context) => const MainNavigationScreen(),
        // '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}