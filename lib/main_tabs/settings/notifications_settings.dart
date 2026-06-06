import 'package:flutter/material.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

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
                      'Notifications',
                      style: AppTypography.headingLg.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manage your push and email preferences',
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
                _buildSectionTitle('Push Notifications'),
                const SizedBox(height: 12),
                _buildToggleTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Story Updates',
                  subtitle: 'Get notified when stories you follow are updated',
                  initialValue: true,
                ),
                _buildToggleTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Comments & Replies',
                  subtitle: 'Notify when someone comments on your stories',
                  initialValue: true,
                ),
                _buildToggleTile(
                  icon: Icons.favorite_border,
                  title: 'Likes & Reactions',
                  subtitle: 'Get notified when your stories are liked',
                  initialValue: true,
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('Email Notifications'),
                const SizedBox(height: 12),
                _buildToggleTile(
                  icon: Icons.email_outlined,
                  title: 'Weekly Digest',
                  subtitle: 'Receive a weekly summary of new stories',
                  initialValue: false,
                ),
                _buildToggleTile(
                  icon: Icons.person_add_outlined,
                  title: 'New Followers',
                  subtitle: 'Get notified when someone follows you',
                  initialValue: true,
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('Privacy & Behavior'),
                const SizedBox(height: 12),
                _buildToggleTile(
                  icon: Icons.vibration_outlined,
                  title: 'Vibration',
                  subtitle: 'Enable tactile feedback for alerts',
                  initialValue: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.authorName.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.inkEspresso,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool initialValue,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.inkUmber.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.inkMaroon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppTheme.inkMaroon, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.authorName.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.authorMeta.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: initialValue,
            onChanged: (value) {
              // TODO: Implement toggle functionality
            },
            activeColor: Colors.white,
            activeTrackColor: AppTheme.inkMaroon,
            inactiveThumbColor: AppTheme.inkGold,
            inactiveTrackColor: AppTheme.inkGold.withValues(alpha: 0.2),
          ),
        ],
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