import 'package:flutter/material.dart';
import 'account_settings.dart';
import 'help_center_settings.dart';
import 'about_settings.dart';

class SupportSettings {
  // Get Support section tiles
  List<Widget> getSupportTiles(BuildContext context) {
    return [
      SettingsTile(
        icon: Icons.help_outline_rounded,
        title: 'Help Center',
        subtitle: 'Browse help articles and guides',
        onTap: () {
          Navigator.push(context, 
            MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
        },
      ),
      SettingsTile(
        icon: Icons.info_outline_rounded,
        title: 'About VibeWrite',
        subtitle: 'App version, terms, and more',
        onTap: () {
          Navigator.push(context, 
            MaterialPageRoute(builder: (_) => const AboutSettingsScreen()));
        },
        isLast: true,
      ),
    ];
  }
}