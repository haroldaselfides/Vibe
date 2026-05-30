import 'package:flutter/material.dart';

class AppTheme {
  // ─── Core Colors ─────────────────────────────────────────────────────────────

  // Wabi palette — flat colors only, no gradients
  static const Color wabiCream    = Color(0xFFFAF1E9); // warm off-white cream
  static const Color wabiSand     = Color(0xFFE0CEB1); // soft sand beige
  static const Color wabiKhaki    = Color(0xFFB29B7B); // warm khaki brown
  static const Color wabiSteel    = Color(0xFF747D86); // cool steel grey
  static const Color wabiCharcoal = Color(0xFF505767); // deep charcoal blue-grey

  // ── Wabi: specific button colors ──
  static const Color wabiButtonPrimary   = wabiCharcoal; // charcoal CTA (high contrast)
  static const Color wabiButtonSecondary = wabiSteel;    // steel secondary
  static const Color wabiButtonSoft      = wabiSand;     // sand ghost button

  // ── Wabi: specific background colors ──
  static const Color wabiBgMain  = wabiCream;    // main screen background
  static const Color wabiBgCard  = wabiSand;     // card / panel surface
  static const Color wabiBgMid   = wabiKhaki;    // mid overlay / section
  static const Color wabiBgDark  = wabiCharcoal; // dark screen / header

  // Ink & Parchment palette — warm editorial, literary aesthetic
  static const Color inkIvory      = Color(0xFFF5F0E8); // aged ivory — main bg
  static const Color inkCanvas     = Color(0xFFEDE6D8); // warm canvas — cards, featured banner
  static const Color inkTerracotta = Color(0xFFC4603B); // terracotta — CTAs, active icons, tags
  static const Color inkSage       = Color(0xFF7A9E8E); // dusty sage — secondary actions, tags
  static const Color inkEspresso   = Color(0xFF1F1208); // deep espresso — headlines, titles
  static const Color inkUmber      = Color(0xFF7A6552); // warm umber — usernames, metadata
  static const Color inkGold       = Color(0xFFC9973A); // antique gold — trending numbers, likes
  static const Color inkBlush      = Color(0xFFD9847A); // blush rose — Romance genre badge
  static const Color inkIndigo     = Color(0xFF5C6B8A); // slate indigo — Mystery genre badge
  static const Color inkTeal       = Color(0xFF4A8FA0); // steel teal — Sci-Fi genre badge

  // ── Ink & Parchment: specific button colors ──
  static const Color inkButtonPrimary   = inkTerracotta; // terracotta CTA (warm, energetic)
  static const Color inkButtonSecondary = inkSage;       // sage secondary (calm, natural)
  static const Color inkButtonSoft      = inkCanvas;     // canvas ghost button (subtle)

  // ── Ink & Parchment: specific background colors ──
  static const Color inkBgMain  = inkIvory;    // main screen background
  static const Color inkBgCard  = inkCanvas;   // card / panel surface
  static const Color inkBgMid   = inkUmber;    // mid overlay / section
  static const Color inkBgDark  = inkEspresso; // dark screen / header

  // ── Ink & Parchment: genre tag colors ──
  static const Color inkTagRomance = inkBlush;  // Romance
  static const Color inkTagMystery = inkIndigo; // Mystery
  static const Color inkTagFantasy = inkSage;   // Fantasy
  static const Color inkTagSciFi   = inkTeal;   // Sci-Fi

  // ─── Semantic / App Colors ───────────────────────────────────────────────────

  static const Color primaryColor    = inkTerracotta; // warm terracotta
  static const Color primaryLight    = inkCanvas;     // light canvas
  static const Color accentColor     = inkGold;       // antique gold accent
  static const Color backgroundColor = inkIvory;      // aged ivory background
  static const Color surfaceColor    = Color(0xFFFFFFFF);
  static const Color textDark        = inkEspresso;   // deep espresso for text
  static const Color textLight       = inkUmber;      // warm umber for secondary text
  static const Color borderColor     = inkCanvas;     // soft canvas border

  // ─── Gradients ───────────────────────────────────────────────────────────────

  // Ink & Parchment: background wash — ivory → canvas
  static const LinearGradient inkBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [inkIvory, inkCanvas],
  );

  // Ink & Parchment: dark background — espresso → umber
  static const LinearGradient inkBgDarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [inkEspresso, inkUmber],
  );

  // Ink & Parchment: primary button — terracotta → umber
  static const LinearGradient inkButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [inkTerracotta, inkUmber],
  );

  // Ink & Parchment: secondary button — sage → teal
  static const LinearGradient inkButtonSecondaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [inkSage, inkTeal],
  );

  // Ink & Parchment: hero — full editorial sweep
  static const LinearGradient inkHeroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [inkEspresso, inkTerracotta, inkUmber, inkCanvas, inkIvory],
  );

  // Wabi: no gradients by design (flat palette only)

  // ─── Theme ───────────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: textLight, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: borderColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textDark,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textLight,
        ),
      ),
    );
  }
}