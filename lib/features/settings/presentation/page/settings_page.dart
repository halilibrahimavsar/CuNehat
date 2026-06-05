import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/features/settings/presentation/widgets/about_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/security_settings_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_header.dart';
import 'package:cunehat/features/settings/presentation/widgets/theme_selector_dropdown.dart';
import 'package:cunehat/features/settings/presentation/widgets/user_profile_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/google_drive_backup_card.dart';

/// Main settings page, styled with premium, theme-aware AppCards.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Ayarlar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  const UserProfileCard(),
                  const SizedBox(height: 24),
                  const SettingsHeader(title: 'GÖRÜNÜM'),
                  const SizedBox(height: 8),
                  const AppCard(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: ThemeSelectorDropdown(),
                  ),
                  const SizedBox(height: 24),
                  const SettingsHeader(title: 'GÜVENLİK'),
                  const SizedBox(height: 8),
                  const SecuritySettingsCard(),
                  const SizedBox(height: 24),
                  const SettingsHeader(title: 'VERİ YEDEKLEME'),
                  const SizedBox(height: 8),
                  const GoogleDriveBackupCard(),
                  const SizedBox(height: 24),
                  const SettingsHeader(title: 'HAKKINDA'),
                  const SizedBox(height: 8),
                  const AboutCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
