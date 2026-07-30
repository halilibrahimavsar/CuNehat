import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/notifications/notification_permission_dialog.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

/// Gizlilik/bildirim tanıtımını ve üç ana ekranın interaktif turlarını
/// istenildiğinde yeniden başlatma imkanı sunan kart. `DataPrivacyCard`
/// deseni (AppCard + ListTile satırları) taklit edilir.
class OnboardingHelpCard extends StatelessWidget {
  const OnboardingHelpCard({super.key});

  Future<void> _replayIntro(BuildContext context) async {
    await showPrivacyConsentDialog(context);
    if (!context.mounted) return;
    await showNotificationPermissionRationale(context);
  }

  /// Ekran turunu sıfırlayıp HomePage'in (Settings altında canlı kalan)
  /// dinleyicisini tetikler; sonra Settings'ten geri dönülür ki tur o
  /// ekranda görünür olsun.
  Future<void> _replayScreenTour(
      BuildContext context, OnboardingFlow flow) async {
    await getIt<OnboardingCoordinator>().resetAndReplay(flow);
    if (context.mounted) context.pop();
  }

  /// Ana ekranlar dışında alt sayfaların (Detay/İçgörü/Rapor/Geçmiş) da
  /// bir replay tile'ı yok — o sayfaya gidildiğinde zaten otomatik
  /// tetikleniyor. Bu, hepsinin bayrağını tek seferde sıfırlar.
  Future<void> _resetAll(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.tumTurlariSifirla,
      message: context.l10n.tumTurlariSifirlaOnayMesaji,
      confirmText: context.l10n.sifirla,
    );
    if (!confirmed || !context.mounted) return;

    await getIt<OnboardingCoordinator>().resetAll();
    if (!context.mounted) return;
    AppMessenger.success(context.l10n.tumTurlarSifirlandi);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget divider() =>
        Divider(height: 1, color: scheme.outline.withValues(alpha: 0.1));

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: scheme.primary),
            title: Text(
              context.l10n.genelTanitimiTekrarGoster,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () => _replayIntro(context),
          ),
          divider(),
          ListTile(
            leading: Icon(Icons.savings_outlined, color: scheme.primary),
            title: Text(
              context.l10n.yatirimBirikimTuru,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () => _replayScreenTour(context, OnboardingFlow.investment),
          ),
          divider(),
          ListTile(
            leading: Icon(Icons.receipt_long_outlined, color: scheme.primary),
            title: Text(
              context.l10n.islemlerTuru,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () =>
                _replayScreenTour(context, OnboardingFlow.transactions),
          ),
          divider(),
          ListTile(
            leading: Icon(Icons.account_balance_wallet_outlined,
                color: scheme.primary),
            title: Text(
              context.l10n.borcAlacakTuru,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onTap: () => _replayScreenTour(context, OnboardingFlow.debt),
          ),
          divider(),
          ListTile(
            leading: Icon(Icons.replay_outlined, color: scheme.primary),
            title: Text(
              context.l10n.tumTurlariSifirla,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              context.l10n.tumTurlariSifirlaAciklama,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            onTap: () => _resetAll(context),
          ),
        ],
      ),
    );
  }
}
