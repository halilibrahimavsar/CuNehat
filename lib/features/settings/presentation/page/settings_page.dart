import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/period_settings_card.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:cunehat/features/settings/presentation/widgets/about_card.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_estimates_switch.dart';
import 'package:cunehat/features/settings/presentation/widgets/home_sections_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/security_settings_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/settings_header.dart';
import 'package:cunehat/features/settings/presentation/widgets/theme_selector_dropdown.dart';
import 'package:cunehat/features/settings/presentation/widgets/language_selector_dropdown.dart';
import 'package:cunehat/features/settings/presentation/widgets/google_drive_backup_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/data_export_import_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/data_privacy_card.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/bank_import_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/onboarding_help_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/notification_debug_card.dart';
import 'package:cunehat/features/settings/presentation/widgets/notification_settings_card.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';

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
            // Standart yükseklikte SABİT çubuk. Eskiden 120dp'ye genişleyen
            // bir başlıktı: sayfa açıldığında boş gradyan çok yer kaplıyor
            // ve içerik aşağı itiliyordu (kullanıcı şikâyeti, 12 Eki 2026).
            pinned: true,
            backgroundColor: AppGradients.pageHeaderBase,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              context.l10n.settings,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppGradients.pageHeader,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0).plusSystemBottom(context),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  SettingsHeader(title: context.l10n.appearance),
                  const SizedBox(height: 8),
                  const AppCard(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: ThemeSelectorDropdown(),
                  ),
                  const SizedBox(height: 8),
                  const AppCard(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: LanguageSelectorDropdown(),
                  ),
                  const SizedBox(height: 24),
                  // Ana ekranın bölümleri: Birikim ve Borç kullandıkça açılır,
                  // buradan elle de açılıp kapatılır.
                  SettingsHeader(title: context.l10n.sectionsHeader),
                  const SizedBox(height: 8),
                  const HomeSectionsCard(),
                  const SizedBox(height: 24),
                  // Dönem birimi (gün / hafta / 2 hafta / ay + başlangıç):
                  // haftalık ya da maaş gününe göre ödeme alan kullanıcılar
                  // için; İşlemler, İçgörü ve Rapor aynı birimi kullanır.
                  SettingsHeader(title: context.l10n.settingsPeriodHeader),
                  const SizedBox(height: 8),
                  const PeriodSettingsCard(),
                  // Tahmin katmanı: Gelecek'in ufku bu bölümdeki dönemden
                  // gelir; anahtar Gelecek başlığında da var.
                  const SizedBox(height: 8),
                  const AppCard(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: ForecastEstimatesSwitch(settings: true),
                  ),
                  const SizedBox(height: 24),
                  SettingsHeader(title: context.l10n.security),
                  const SizedBox(height: 8),
                  const SecuritySettingsCard(),
                  const SizedBox(height: 24),
                  SettingsHeader(title: context.l10n.notificationSettings),
                  const SizedBox(height: 8),
                  const NotificationSettingsCard(),
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    const NotificationDebugCard(),
                  ],
                  const SizedBox(height: 24),
                  SettingsHeader(title: context.l10n.dataBackupTransfer),
                  const SizedBox(height: 8),
                  const GoogleDriveBackupCard(),
                  const SizedBox(height: 16),
                  const DataExportImportCard(),
                  const SizedBox(height: 24),
                  SettingsHeader(
                      title: context.l10n.bankStatementSectionHeader),
                  const SizedBox(height: 8),
                  const BankImportCard(),
                  const SizedBox(height: 24),
                  SettingsHeader(title: context.l10n.privacyDataHeader),
                  const SizedBox(height: 8),
                  const DataPrivacyCard(),
                  const SizedBox(height: 24),
                  SettingsHeader(title: context.l10n.yardimVeTurlar),
                  const SizedBox(height: 8),
                  const OnboardingHelpCard(),
                  const SizedBox(height: 24),
                  SettingsHeader(title: context.l10n.about),
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
