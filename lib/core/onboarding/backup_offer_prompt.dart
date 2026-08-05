import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "Verin var ama yedeğin yok" durumundaki kullanıcıya bir kez gösterilen
/// yedekleme teklifi.
///
/// Otomatik Drive yedeği varsayılan olarak KAPALI ve uygulama yerel-öncelikli:
/// yedeklemeyi hiç açmayan bir kullanıcı telefonunu kaybettiğinde ya da
/// uygulamayı kaldırdığında verisinin tamamını kaybeder, geri dönüşü yoktur.
/// Ayarlar'daki yedekleme kartını kendiliğinden bulmayan kullanıcı için tek
/// hatırlatma bu.
class BackupOfferPrompt {
  const BackupOfferPrompt._();

  static const String seenKey = 'backup_offer_shown';

  /// Bu eşiğin altında SORULMAZ ve bayrak da YAZILMAZ. Sıfır veriyle sorulan
  /// "yedekleme açmak ister misin?" kullanıcıya hiçbir şey ifade etmez;
  /// refleksle kapatılır ve tek şansımızı harcamış oluruz. Veri birikince
  /// sonraki açılışta yeniden denenir.
  static const int minTransactions = 5;

  static bool shouldOffer({
    required bool alreadyOffered,
    required bool autoBackupEnabled,
    required int transactionCount,
  }) {
    if (alreadyOffered) return false;
    // Yedekleme zaten açıksa teklif anlamsız; bayrağı çağıran yazar ki
    // kullanıcı sonradan kapatırsa tekrar rahatsız edilmesin.
    if (autoBackupEnabled) return false;
    return transactionCount >= minTransactions;
  }
}

/// Teklif diyaloğu. "Kur" Ayarlar'a götürür — oturum açma ve sıklık seçimi
/// zaten yedekleme kartının işi; burada ikinci bir akış kurmak o kartın
/// hata durumlarını (bağlantı yok, kota dolu, oturum süresi doldu…) yeniden
/// yazmak olurdu.
Future<void> showBackupOfferDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final l10n = dialogContext.l10n;
      return AlertDialog(
        icon: Icon(Icons.cloud_off_rounded, color: scheme.error),
        title: Text(l10n.backupOfferTitle),
        content: Text(
          l10n.backupOfferBody,
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.backupOfferLater),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(AppRoutes.settings);
            },
            child: Text(l10n.backupOfferSetup),
          ),
        ],
      );
    },
  );
}
