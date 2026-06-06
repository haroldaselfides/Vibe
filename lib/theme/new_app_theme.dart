import 'package:flutter/material.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // VIBEWRITE Literary Palette
  // ─────────────────────────────────────────────
  
  // Core Colors
  static const Color inkEspresso = Color(0xFF2B1410);      // Very dark brown
  static const Color inkMaroon = Color(0xFF7A1313);         // Deep burgundy
  static const Color inkTerracotta = Color(0xFFB8523F);    // Warm rust/terracotta
  static const Color inkGold = Color(0xFFD4A574);           // Warm gold
  static const Color inkUmber = Color(0xFF8B6F47);          // Earth brown
  static const Color inkSage = Color(0xFF9B8F7E);           // Muted sage
  
  // Light Colors
  static const Color inkIvory = Color(0xFFF5E6B3);          // Warm ivory
  static const Color inkCanvas = Color(0xFFFAF6F0);         // Off-white canvas
  static const Color inkBgMain = Color(0xFFFEF9F3);         // Warm white
  static const Color inkBgCard = Color(0xFFEBDCC7);         // Soft beige

  // Secondary Palette (legacy support)
  static const Color cream = Color(0xFFF5E6B3);
  static const Color gold = Color(0xFFC19A5B);
  static const Color brown = Color(0xFFA0522D);
  static const Color darkBrown = Color(0xFF5A2D0C);
  static const Color maroon = Color(0xFF7A1313);

  // Brand Colors
  static const Color primaryColor = inkMaroon;
  static const Color accentColor = inkTerracotta;
  static const Color secondaryAccent = inkGold;

  // Surfaces
  static const Color backgroundColor = Color(0xFFFEF9F3);
  static const Color surfaceColor = Colors.white;
  static const Color cardBackground = Color(0xFFFAF6F0);

  // Text
  static const Color textDark = inkEspresso;
  static const Color textLight = inkUmber;
  static const Color textMuted = inkSage;

  // Borders
  static const Color borderColor = Color(0xFFE9DCC5);

  // Genre Tag Colors
  static const Color inkTagRomance = Color(0xFFE8949A);     // Soft rose
  static const Color inkTagMystery = Color(0xFF8B9DC3);     // Muted blue
  static const Color inkTagFantasy = Color(0xFF9B8FBF);     // Soft purple
  static const Color inkTagSciFi = Color(0xFF7BA89F);       // Muted teal
  static const Color inkTagPoetry = Color(0xFFB8946E);      // Warm brown

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3D1C10),
      Color(0xFF5A2D1C),
      Color(0xFF8B4513),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFB8523F),
      Color(0xFFD4A574),
    ],
  );

  // ─────────────────────────────────────────────
  // Text Styles
  // ─────────────────────────────────────────────
  
  static const TextStyle headingXL = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: inkEspresso,
    height: 1.2,
  );

  static const TextStyle headingLg = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: inkEspresso,
    height: 1.2,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: inkEspresso,
  );

  static const TextStyle headingSm = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: inkEspresso,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textDark,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textDark,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textLight,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: textLight,
  );

  // ─────────────────────────────────────────────
  // Shadows
  // ─────────────────────────────────────────────
  
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x15000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // ─────────────────────────────────────────────
  // Border Radius
  // ─────────────────────────────────────────────
  
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusFull = 9999;
}