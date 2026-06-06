import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';

class SettingsWidgets {
  // Local overrides that can't live in AppTypography
  // (white/on-dark variants used only in the header)
  static TextStyle get serifTitleOnDark => GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        color: Colors.white,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: 0.3,
      );

  static TextStyle get headerSubOnDark => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.white60,
      );

  // Build header widget
  static Widget buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(
        top: topPad + 14,
        left: 14,
        right: 14,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.inkMaroon,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Settings', style: serifTitleOnDark),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your account and preferences',
                          style: headerSubOnDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            buildShapes(),
          ],
        ),
      ),
    );
  }

  // Build decorative shapes
  static Widget buildShapes() {
    // Slightly lighter than inkMaroon for the muted overlay effect
    const color = Color(0xFFAB4040);
    return SizedBox(
      width: 100,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 28,
            top: 0,
            child: CustomPaint(
              size: const Size(42, 48),
              painter: TrianglePainter(color),
            ),
          ),
          Positioned(
            left: 6,
            top: 30,
            child: Text(
              '✦',
              style: TextStyle(fontSize: 16, color: color),
            ),
          ),
          Positioned(
            left: 0,
            top: 44,
            child: Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 0,
            top: 50,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build settings section card
  static Widget buildSettingsSection({
    required IconData icon,
    required String title,
    required String desc,
    required List<Widget> tiles,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.inkBgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: AppTheme.inkMaroon, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTypography.storyTitle.copyWith(
                            fontSize: 17,
                            height: 1.2,
                          )),
                      const SizedBox(height: 1),
                      Text(desc, style: AppTypography.authorMeta),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.borderColor),
          ...tiles,
        ],
      ),
    );
  }
}

// Triangle CustomPainter
class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter old) => old.color != color;
}