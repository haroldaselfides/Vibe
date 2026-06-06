import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'new_app_theme.dart';

class AppTypography {
  // ─────────────────────────────────────────────
  // HEADING STYLES (DM Serif Display)
  // ─────────────────────────────────────────────
  
  // Logo / Hero Titles
  static TextStyle headingXL = GoogleFonts.dmSerifDisplay(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppTheme.inkEspresso,
    height: 1.1,
    letterSpacing: 0.5,
  );

  static TextStyle headingLg = GoogleFonts.dmSerifDisplay(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppTheme.inkEspresso,
    height: 1.15,
  );

  static TextStyle headingMd = GoogleFonts.dmSerifDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppTheme.inkEspresso,
  );

  static TextStyle headingSm = GoogleFonts.dmSerifDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.inkEspresso,
  );

  // ─────────────────────────────────────────────
  // BODY STYLES (Manrope)
  // ─────────────────────────────────────────────
  
  // Reading Content - Large
  static TextStyle bodyLg = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppTheme.textDark,
    height: 1.6,
  );

  // Reading Content - Medium
  static TextStyle bodyMd = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTheme.textDark,
    height: 1.5,
  );

  // Reading Content - Small
  static TextStyle bodySm = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppTheme.textLight,
    height: 1.4,
  );

  // ─────────────────────────────────────────────
  // LABEL STYLES (Manrope - Uppercase/Accent)
  // ─────────────────────────────────────────────
  
  static TextStyle labelMd = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppTheme.textDark,
    letterSpacing: 0.4,
  );

  static TextStyle labelSm = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppTheme.textLight,
    letterSpacing: 0.3,
  );

  // ─────────────────────────────────────────────
  // SPECIALIZED STYLES
  // ─────────────────────────────────────────────
  
  // Story Title (Serif for literary feel)
  static TextStyle storyTitle = GoogleFonts.dmSerifDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppTheme.inkMaroon,
    height: 1.2,
  );

  // Story Subtitle
  static TextStyle storySubtitle = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTheme.textLight,
    height: 1.5,
  );

  // Author Name
  static TextStyle authorName = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppTheme.inkUmber,
    letterSpacing: 0.2,
  );

  // Author Meta (smaller, muted)
  static TextStyle authorMeta = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppTheme.textMuted,
    letterSpacing: 0.1,
  );

  // Quote Style (Serif + Italic for emphasis)
  static TextStyle quote = GoogleFonts.dmSerifDisplay(
    fontSize: 22,
    fontStyle: FontStyle.italic,
    color: AppTheme.inkEspresso,
    height: 1.4,
  );

  // Quote Attribution
  static TextStyle quoteAttribution = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppTheme.textLight,
    fontStyle: FontStyle.italic,
  );

  // ─────────────────────────────────────────────
  // CAPTION STYLES (Utility)
  // ─────────────────────────────────────────────
  
  // Caption - Standard
  static TextStyle caption = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppTheme.textMuted,
  );

  // Caption - Emphasized
  static TextStyle captionBold = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppTheme.textLight,
  );

  // ─────────────────────────────────────────────
  // BUTTON STYLES
  // ─────────────────────────────────────────────
  
  static TextStyle buttonLarge = GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  static TextStyle buttonMedium = GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  // ─────────────────────────────────────────────
  // TAG & METADATA STYLES
  // ─────────────────────────────────────────────
  
  static TextStyle tagGenre = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppTheme.inkMaroon,
    letterSpacing: 0.5,
  );

  static TextStyle tagStoryType = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppTheme.textLight,
    letterSpacing: 0.5,
  );

  static TextStyle wordCount = GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppTheme.textMuted,
  );
}