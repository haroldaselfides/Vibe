import 'package:flutter/material.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';
import '../main_tabs/settings/account_settings.dart';
import '../main_tabs/settings/support_settings.dart';
import '../main_tabs/settings/logout_handler.dart';
import '../main_tabs/settings/notifications_settings.dart';
import '../main_tabs/settings/appearance_settings.dart';
import '../main_tabs/settings/help_center_settings.dart';
import '../main_tabs/settings/about_settings.dart';
import '../main_tabs/settings/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accountSettings = AccountSettings();
    final supportSettings = SupportSettings();
    final logoutHandler = LogoutHandler();

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                // ── Account Section ───────────────────────────
                _SettingsSection(
                  icon: Icons.person_outline_rounded,
                  title: 'Account',
                  subtitle: 'Manage your personal information and security',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      subtitle: 'View and update your profile details',
                      onTap: () => accountSettings.navigateToPersonalInfo(context),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Security',
                      subtitle: 'Manage your password and security settings',
                      onTap: () => accountSettings.handleSecurity(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Preferences Section ───────────────────────
                _SettingsSection(
                  icon: Icons.tune_rounded,
                  title: 'Preferences',
                  subtitle: 'Customize your app experience',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage your notification preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const NotificationsSettingsScreen()),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Appearance',
                      subtitle: 'Customize how VibeWrite looks',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AppearanceSettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Support Section ───────────────────────────
                _SettingsSection(
                  icon: Icons.help_outline_rounded,
                  title: 'Support',
                  subtitle: 'Get help and learn more about VibeWrite',
                  tiles: [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help Center',
                      subtitle: 'Browse help articles and guides',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const HelpCenterScreen()),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About VibeWrite',
                      subtitle: 'App version, terms, and more',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AboutSettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Logout ────────────────────────────────────
                _buildLogoutButton(context, logoutHandler),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

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
              // Back button
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
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Settings',
                      style: AppTypography.headingLg.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manage your account and preferences',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Decorative shapes
              _DecorativeShapes(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout button ──────────────────────────────────────────────────────────

  Widget _buildLogoutButton(BuildContext context, LogoutHandler handler) {
    return GestureDetector(
      onTap: () => handler.buildLogoutButton(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.inkMaroon.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 18, color: AppTheme.inkMaroon),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: AppTypography.labelMd.copyWith(
                color: AppTheme.inkMaroon,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section: label outside, each tile its own card ──────────────────────────

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_SettingsTile> tiles;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: AppTheme.inkUmber.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label row ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.inkMaroon.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppTheme.inkMaroon),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headingSm.copyWith(
                        color: AppTheme.inkMaroon,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppTheme.inkUmber.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Each tile in its own rounded card ───────────────────────
          ...tiles.asMap().entries.map((entry) {
            final isLast = entry.key == tiles.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.inkUmber.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
                child: entry.value,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Individual tile row ──────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.inkMaroon.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppTheme.inkMaroon.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMd.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkEspresso,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: AppTheme.inkUmber.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.inkUmber.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Decorative geometric shapes ─────────────────────────────────────────────

class _DecorativeShapes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
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
            left: 22,
            top: 4,
            child: Icon(Icons.auto_awesome_rounded,
                size: 11, color: Colors.white.withValues(alpha: 0.4)),
          ),
          Positioned(
            left: 10,
            top: 38,
            child: Icon(Icons.auto_awesome_rounded,
                size: 9, color: Colors.white.withValues(alpha: 0.3)),
          ),
          Positioned(
            right: 0,
            top: 2,
            child: CustomPaint(
              size: const Size(28, 28),
              painter: _TrianglePainter(
                  color: Colors.white.withValues(alpha: 0.30)),
            ),
          ),
          Positioned(
            right: 34,
            top: 32,
            child: Container(
              width: 22,
              height: 22,
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
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
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