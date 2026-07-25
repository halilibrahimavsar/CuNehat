import 'package:flutter/material.dart';

import 'package:cunehat/core/extensions/context_extensions.dart';

/// Sistem bildirim izni istenmeden önce gösterilen gerekçe diyaloğu.
/// Kardeşi [showPrivacyConsentDialog] (privacy_policy_page.dart) ile aynı
/// stile sadıktır: kapatılamaz, kısa gerekçe + net eylem.
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
