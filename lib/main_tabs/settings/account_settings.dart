import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/new_app_theme.dart';
import '../../theme/app_typography.dart';
import 'edit_profile.dart';
import 'security_settings.dart';

class AccountSettings {
  // Navigate to Personal Information
  Future<void> navigateToPersonalInfo(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.inkMaroon),
      ),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (context.mounted) {
        Navigator.pop(context);
        if (doc.exists) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditProfileScreen(userData: doc.data()!),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: AppTypography.bodySm),
            backgroundColor: AppTheme.inkMaroon,
          ),
        );
      }
    }
  }

  void handleSecurity(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()),
    );
  }

  // Get Account section tiles
  List<Widget> getAccountTiles(BuildContext context) {
    return [
      SettingsTile(
        icon: Icons.account_circle_outlined,
        title: 'Personal Information',
        subtitle: 'View and update your profile details',
        onTap: () => navigateToPersonalInfo(context),
      ),
      SettingsTile(
        icon: Icons.lock_outline_rounded,
        title: 'Security',
        subtitle: 'Manage your password and security settings',
        onTap: () => handleSecurity(context),
        isLast: true,
      ),
    ];
  }
}

// Reusable Settings Tile Widget
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? BorderRadius.only(
              bottomLeft: Radius.circular(AppTheme.radiusMd),
              bottomRight: Radius.circular(AppTheme.radiusMd),
            )
          : BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.inkBgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: AppTheme.inkGold, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.authorName.copyWith(
                    fontSize: 14,
                    color: AppTheme.inkEspresso,
                  )),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.authorMeta),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppTheme.inkGold),
          ],
        ),
      ),
    );
  }
}