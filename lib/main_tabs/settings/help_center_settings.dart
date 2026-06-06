import 'package:flutter/material.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
                      'Help Center',
                      style: AppTypography.headingLg.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Guides and support for your writing journey',
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              children: [
                _buildHelpTile('Getting Started', 'Learn the basics of using VibeWrite.'),
                _buildHelpTile('Writing Tools', 'How to use the editor and chapter management.'),
                _buildHelpTile('Account & Privacy', 'Managing your data and visibility.'),
                _buildHelpTile('Publishing', 'Guidelines for sharing your stories.'),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.inkMaroon.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.inkMaroon.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Text('Still need help?', 
                        style: AppTypography.headingSm.copyWith(color: AppTheme.inkMaroon)),
                      const SizedBox(height: 8),
                      Text('Our support team is always here for you.', 
                        style: AppTypography.bodySm, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.inkMaroon,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text('Contact Support', style: AppTypography.buttonMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.inkUmber.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title, style: AppTypography.labelMd.copyWith(fontSize: 14)),
        subtitle: Text(subtitle, style: AppTypography.authorMeta.copyWith(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.inkGold, size: 20),
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