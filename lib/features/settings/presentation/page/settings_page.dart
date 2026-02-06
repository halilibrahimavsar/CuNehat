import 'package:flutter/material.dart';
import 'package:cunehat/features/settings/presentation/widgets/about_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/security_settings_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_header.dart';
import 'package:cunehat/features/settings/presentation/widgets/theme_selector_dropdown.dart';
import 'package:cunehat/features/settings/presentation/widgets/user_profile_card.dart';

/// Main settings page.
///
/// Organized into sections:
/// - User Profile
/// - Appearance (Theme)
/// - Security
/// - About
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          UserProfileCard(),
          SizedBox(height: 24),
          SettingsHeader(title: 'GÖRÜNÜM'),
          ThemeSelectorDropdown(),
          SizedBox(height: 24),
          SettingsHeader(title: 'GÜVENLİK'),
          SecuritySettingsCard(),
          SizedBox(height: 24),
          SettingsHeader(title: 'HAKKINDA'),
          AboutCard(),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}
