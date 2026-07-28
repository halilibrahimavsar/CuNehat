import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Uygulama-içi gizlilik politikası ekranı. İçerik, barındırılan
/// `docs/privacy-policy.html` ile aynı bilgileri özetler; çevrimdışı da
/// erişilebilir olsun diye metin gömülüdür (harici bağımlılık yok).
///
/// Metinler l10n'dan gelir: uygulama tr+en yayınlanıyor ve bu, mağaza
/// incelemesinin baktığı ekranlardan biri — sabit Türkçe bırakılırsa İngilizce
/// kullanıcı gizlilik politikasını okuyamaz. İngilizce karşılıklar
/// `docs/privacy-policy.html`'in EN bölümünden alınmıştır (uydurulmadı).
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String contactEmail = 'halirlnj@gmail.com';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicyTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            l10n.privacyIntro,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 8),
          _Section(
            title: l10n.privacyLocalDataTitle,
            body: l10n.privacyLocalDataBody,
          ),
          _Section(
            title: l10n.privacyDriveTitle,
            body: l10n.privacyDriveBody,
          ),
          _Section(
            title: l10n.privacyMarketDataTitle,
            body: l10n.privacyMarketDataBody,
          ),
          _Section(
            title: l10n.privacySharingTitle,
            body: l10n.privacySharingBody,
          ),
          _Section(
            title: l10n.privacySecurityTitle,
            body: l10n.privacySecurityBody,
          ),
          _Section(
            title: l10n.privacyRetentionTitle,
            body: l10n.privacyRetentionBody,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.privacyContactLabel(contactEmail),
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.privacyLastUpdated,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// İlk açılışta bir kez gösterilen gizlilik bilgilendirme/onam diyaloğu.
/// Kapatılamaz; kullanıcı "Anladım" diyerek devam eder. "Gizlilik Politikası"
/// tam metni açar. Çağıran, gösterildikten sonra kalıcı bayrağı yazar.
Future<void> showPrivacyConsentDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final l10n = dialogContext.l10n;
      return AlertDialog(
        title: Text(l10n.privacyConsentTitle),
        content: Text(
          l10n.privacyConsentBody,
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(AppRoutes.privacyPolicy);
            },
            child: Text(l10n.privacyPolicyTitle),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.privacyConsentAcknowledge),
          ),
        ],
      );
    },
  );
}
