import 'package:flutter/material.dart';

import 'package:cunehat/core/extensions/context_extensions.dart';

/// "Bildirim gerekçesi gösterildi" kalıcı bayrağı. Değeri DEĞİŞMEZ: eski
/// kurulumlarda bu anahtarla yazılı ve onlara yeniden sorulmamalı.
const String kNotificationRationaleShownKey =
    'notification_permission_explained';

/// Bildirim izni ŞİMDİ sorulmalı mı?
///
/// - [alreadyExplained]: gerekçe daha önce gösterildi (kullanıcı ne dediyse
///   dedi) → bir daha sorulmaz; dönüş yolu Ayarlar > Bildirimler.
/// - [reminderWanted]: bu oturumda hatırlatma taşıyan bir kayıt var/oluştu
///   (bkz. `ReminderSyncService.reminderWanted`). Yoksa sorunun konusu yok.
///
/// Eskiden izin ilk açılışta, bu ikinci koşul aranmadan soruluyordu.
bool shouldAskNotificationPermission({
  required bool alreadyExplained,
  required bool reminderWanted,
}) =>
    !alreadyExplained && reminderWanted;

/// Sistem bildirim izni istenmeden önce gösterilen gerekçe diyaloğu.
/// Kapatılamaz, kısa gerekçe + net eylem.
///
/// Döndürdüğü `true`, kullanıcının "İzin Ver" dediğini; çağıran taraf bu
/// durumda `NotificationService.requestPermissions()`'ı tetiklemelidir.
/// Kullanıcı reddederse tek dönüş yolu Ayarlar > Bildirimler kartıdır.
Future<bool> showNotificationPermissionRationale(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final l10n = dialogContext.l10n;
      return AlertDialog(
        title: Text(l10n.notificationRationaleTitle),
        content: Text(
          l10n.notificationRationaleBody,
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notificationRationaleLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.notificationPermissionGrant),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
