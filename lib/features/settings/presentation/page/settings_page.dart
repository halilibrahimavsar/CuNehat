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
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Ayarlar',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
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
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                         )
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const ThemeSelectorDropdown(),
                  ),
                  const SizedBox(height: 24),
                  const SettingsHeader(title: 'GÜVENLİK'),
                  const SizedBox(height: 8),
                  const SecuritySettingsCard(), // Assuming this card has its own decoration
                  const SizedBox(height: 24),
                  const SettingsHeader(title: 'HAKKINDA'),
                  const SizedBox(height: 8),
                  const AboutCard(), // Assuming this card has its own decoration
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
