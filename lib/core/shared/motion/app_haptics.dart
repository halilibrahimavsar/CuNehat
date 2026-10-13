import 'package:flutter/services.dart';

/// Dokunsal geri bildirimin tek sözlüğü.
///
/// `lib/` içinde yalnız dört dokunsal çağrı vardı (PIN tuşları ve kart
/// düğmesi); kaydetme, silme, anahtar çevirme gibi sonucu olan eylemler
/// sessizdi. Üç anlam yeter — fazlası titreşimi gürültüye çevirir:
///
/// - [selection]: bir seçim değişti (sekme, çip, anahtar).
/// - [confirm]: bir eylem tamamlandı (kayıt eklendi, ödeme yazıldı).
/// - [warning]: geri alınması zor bir şey oldu ya da reddedildi (silme, hata).
abstract final class AppHaptics {
  static void selection() => HapticFeedback.selectionClick();

  static void confirm() => HapticFeedback.lightImpact();

  static void warning() => HapticFeedback.mediumImpact();
}
