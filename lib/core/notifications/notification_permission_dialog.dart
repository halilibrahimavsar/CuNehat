import 'package:flutter/material.dart';

/// Sistem bildirim izni istenmeden önce gösterilen gerekçe diyaloğu.
/// Kardeşi [showPrivacyConsentDialog] (privacy_policy_page.dart) ile aynı
/// stile sadıktır: kapatılamaz, kısa gerekçe + net eylem.
///
/// Döndürdüğü `true`, kullanıcının "İzin Ver" dediğini; çağıran taraf bu
/// durumda `NotificationService.requestPermissions()`'ı tetiklemelidir.
Future<bool> showNotificationPermissionRationale(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: const Text('Bildirimler'),
        content: Text(
          'CuNehat; borç/alacak vade tarihleri yaklaştığında ve tekrarlayan '
          'işlemler onay beklediğinde size hatırlatma gönderebilir. Bunun '
          'için bildirim izni gerekir. İzin vermeseniz de uygulamayı '
          'kullanmaya devam edebilirsiniz; sadece hatırlatmalar gösterilmez.',
          style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Şimdi Değil'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('İzin Ver'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
