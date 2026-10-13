import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/notifications/notification_permission_dialog.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Yardım kartı: gizlilik/bildirim notunu ve kalan tanıtımları (kaydırıcı,
/// kart düğmesi) istenildiğinde yeniden gösterir. `DataPrivacyCard` deseni
/// (AppCard + ListTile satırları) taklit edilir.
///
/// Eskiden üç satırdı ve üçüncüsü "tüm turları sıfırla" idi: altı turun beş
/// bayrağını birden siliyordu. Form ve cüzdan sayfası turları kaldırıldı
/// (açıklamalar artık alanların altında duruyor); kalan iki tur tek satırdan
/// yeniden oynatılır.
class OnboardingHelpCard extends StatelessWidget {
  const OnboardingHelpCard({super.key});

  Future<void> _replayIntro(BuildContext context) async {
    await showPrivacyConsentDialog(context);
    if (!context.mounted) return;
    await showNotificationPermissionRationale(context);
  }

  /// Kalan tanıtımların bayraklarını siler ve Ayarlar'dan geri döner ki
  /// tanıtım ana ekranda görünür olsun. HomePage (Ayarlar'ın altında canlı)
  /// isteği yeniden açar.
  Future<void> _replayTours(BuildContext context) async {
    await getIt<OnboardingCoordinator>().resetAll();
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sections = getIt.isRegistered<SectionVisibility>()
        ? getIt<SectionVisibility>()
        : null;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListenableBuilder(
        listenable: sections ?? const AlwaysStoppedAnimation<double>(0),
        builder: (context, _) => Column(
          children: [
            ListTile(
              leading: Icon(Icons.info_outline, color: scheme.primary),
              title: Text(context.l10n.genelTanitimiTekrarGoster),
              onTap: () => _replayIntro(context),
            ),
            // Anlatılacak jest yalnız kaydırıcıda: yalnız İşlemler açıkken
            // (sade çubuk) tekrar gösterilecek bir tanıtım yoktur.
            if (!(sections?.hasOnlyTransactions ?? false)) ...[
              Divider(height: 1, color: scheme.outlineVariant),
              ListTile(
                key: const ValueKey('help-replay-tours'),
                leading: Icon(Icons.explore_outlined, color: scheme.primary),
                title: Text(context.l10n.uygulamaTuruTekrarGoster),
                onTap: () => _replayTours(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
