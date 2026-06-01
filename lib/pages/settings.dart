import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_tabs/edit_profile.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.inkBgMain,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(color: AppTheme.inkEspresso, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(fontSize: 14, color: AppTheme.inkUmber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.inkUmber)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.inkTerracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Future<void> _navigateToPersonalInfo(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.inkTerracotta),
      ),
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (context.mounted) {
        Navigator.pop(context); // Remove loading indicator
        if (doc.exists) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(userData: doc.data()!),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.inkTerracotta),
        );
      }
    }
  }

  Future<void> _handleSecurity(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.inkBgMain,
        title: const Text('Security', style: TextStyle(color: AppTheme.inkEspresso)),
        content: Text('Send a password reset email to ${user.email}?', 
            style: const TextStyle(color: AppTheme.inkUmber)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.inkUmber)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Reset Link', style: TextStyle(color: AppTheme.inkTerracotta)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset link sent to your email!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.inkTerracotta),
          );
        }
      }
    }
  }

  void _showFeatureUnavailable(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature settings will be available in a future update.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkBgMain,
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(color: AppTheme.inkEspresso, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.inkBgMain,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.inkEspresso),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSettingsSection(
            'Account',
            [
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: 'Personal Information',
                onTap: () => _navigateToPersonalInfo(context),
              ),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Security',
                onTap: () => _handleSecurity(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSettingsSection(
            'Preferences',
            [
              _buildSettingsTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () => _showFeatureUnavailable(context, 'Notifications'),
              ),
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                onTap: () => _showFeatureUnavailable(context, 'Appearance'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSettingsSection(
            'Support',
            [
              _buildSettingsTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () => _showFeatureUnavailable(context, 'Help Center'),
              ),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'About VibeWrite',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'VibeWrite',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.edit_note, color: AppTheme.inkTerracotta, size: 48),
                    children: const [
                      Text('VibeWrite is a professional platform for writers to compose, organize, and share their stories with the world.'),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.inkTerracotta,
                side: const BorderSide(color: AppTheme.inkTerracotta),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.inkUmber,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.inkBgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.inkUmber.withValues(alpha: 0.1)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.inkEspresso, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.inkEspresso)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.inkUmber),
      onTap: onTap,
    );
  }
}