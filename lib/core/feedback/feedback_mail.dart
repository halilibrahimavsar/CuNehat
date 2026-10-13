import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// "Görüş gönder": alıcısı ve konusu dolu bir e-posta taslağı açar.
///
/// Kapalı testte 13 kişi uygulamayı kendi verisiyle kullanıyor; onlara
/// ulaşmanın yolu vardı ama onların bize ulaşmasının yolu yalnız gizlilik
/// sayfasının dibindeki adresti. Görüşün gidecek bir yeri olması,
/// "dinleniyorum" duygusunun en ucuz yoludur.
///
/// Bkz. `android/.../FeedbackMailPlugin.kt`.
class FeedbackMail {
  const FeedbackMail._();

  static const MethodChannel _channel =
      MethodChannel('dev.halilibrahim.cunehat/feedback_mail');

  /// E-posta uygulaması açıldıysa `true`. Açılamadıysa (uygulama yok, başka
  /// platform, kanal yok) `false` — çağıran adresi başka yolla sunar.
  static Future<bool> compose({
    required String to,
    required String subject,
    required String body,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final opened = await _channel.invokeMethod<bool>('compose', {
        'to': to,
        'subject': subject,
        'body': body,
      });
      return opened ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
