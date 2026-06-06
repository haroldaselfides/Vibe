import 'package:flutter/material.dart';
import 'account_settings.dart';
import 'notifications_settings.dart';
import 'appearance_settings.dart';

class PreferenceSettings {
  // Get Preferences section tiles
  List<Widget> getPreferenceTiles(BuildContext context) {
    return [
      SettingsTile(
        icon: Icons.notifications_none_rounded,
        title: 'Notifications',
        subtitle: 'Manage your notification preferences',
        onTap: () {
          Navigator.push(context, 
            MaterialPageRoute(builder: (_) => const NotificationsSettingsScreen()));
        },
      ),
      SettingsTile(
        icon: Icons.dark_mode_outlined,
        title: 'Appearance',
        subtitle: 'Customize how VibeWrite looks',
        onTap: () {
          Navigator.push(context, 
            MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()));
        },
        isLast: true,
      ),
    ];
  }
}