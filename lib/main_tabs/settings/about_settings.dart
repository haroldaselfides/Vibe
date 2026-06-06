import 'package:flutter/material.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.inkMaroon,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'About VibeWrite',
                      style: AppTypography.headingLg.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Version 1.0.0 · Information and legal',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _DecorativeShapes(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
              child: Column(
                children: [
                  const Icon(Icons.history_edu_rounded, size: 84, color: AppTheme.inkMaroon),
                  const SizedBox(height: 24),
                  Text('VibeWrite', style: AppTypography.headingXL),
                  Text('Version 1.0.0', style: AppTypography.authorMeta.copyWith(fontSize: 14)),
                  const SizedBox(height: 40),
                  Text(
                    'A sanctuary for the written word. VibeWrite is a professional platform designed for writers who value focus, elegance, and the literary craft.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(height: 1.7, color: AppTheme.inkEspresso),
                  ),
                  const SizedBox(height: 48),
                  _buildLink('Terms of Service'),
                  _buildLink('Privacy Policy'),
                  _buildLink('Open Source Licenses'),
                  const SizedBox(height: 64),
                  Text('© 2024 VibeWrite Inc.', style: AppTypography.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLink(String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelMd.copyWith(color: AppTheme.inkEspresso)),
            const Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.inkGold),
          ],
        ),
      ),
    );
  }
}

class _DecorativeShapes extends StatelessWidget {
  const _DecorativeShapes();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 60,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 18,
            child: Icon(Icons.auto_awesome_rounded,
                size: 16, color: Colors.white.withValues(alpha: 0.55)),
          ),
          Positioned(
            left: 20,
            top: 4,
            child: Icon(Icons.auto_awesome_rounded,
                size: 11, color: Colors.white.withValues(alpha: 0.4)),
          ),
          Positioned(
            left: 8,
            top: 38,
            child: Icon(Icons.auto_awesome_rounded,
                size: 9, color: Colors.white.withValues(alpha: 0.3)),
          ),
          Positioned(
            right: 0,
            top: 2,
            child: CustomPaint(
              size: const Size(26, 26),
              painter: _TrianglePainter(
                  color: Colors.white.withValues(alpha: 0.30)),
            ),
          ),
          Positioned(
            right: 30,
            top: 32,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 32,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0x33FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

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
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}