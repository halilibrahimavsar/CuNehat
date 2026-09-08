import 'package:flutter/material.dart' show kFloatingActionButtonMargin;
import 'package:flutter/widgets.dart';

/// Sistem çubuklarının (durum çubuğu / gezinme çubuğu) kapladığı payları
/// içerik dolgusuna eklemenin tek yolu.
///
/// **Neden gerekli.** `targetSdk 36` ile Android edge-to-edge'i ZORUNLU
/// kılıyor: uygulama artık her zaman durum çubuğunun ve gezinme çubuğunun
/// ALTINA çiziyor, `SystemChrome` ile bundan çıkmak mümkün değil. Sayfaların
/// sabit alt dolguları (`EdgeInsets.all(16)`, `fromLTRB(..., 32)`) bu payı
/// hesaba katmadığı için son kart/son satır gezinme çubuğunun altında
/// kalıyordu — ölçüldü: 3 tuşlu gezinmede 16dp, jest tutamağında düşük ama
/// yine de sıfır boşluk.
///
/// **Neden `SafeArea` değil.** Kaydırıcıyı `SafeArea` ile sarmak içeriği
/// çubuğun üstünde SERT keser: liste çubuğun altından akmaz, kaydırma çubuğu
/// ve overscroll parıltısı içeri gömülür. Doğrusu içeriğin çubuğun altından
/// akmaya devam etmesi ama SONUNA kadar kaydırılabilmesidir — yani dolgu
/// eklemek. `SafeArea` yalnız alt kenara ÇİVİLENMİŞ (kaydırılmayan) çubuklar
/// ve düğmeler için doğrudur.
///
/// **Neden `padding`, `viewPadding` değil.** Klavye açıkken gezinme çubuğu
/// zaten klavyenin altında kalır; `padding.bottom` o anda 0'a düşer ve çift
/// boşluk oluşmaz. `viewPadding` düşmez, klavyenin üstüne 48dp fazladan
/// boşluk bırakırdı.
extension SystemBarInsets on EdgeInsets {
  /// Alt dolguya gezinme çubuğu payını ekler.
  EdgeInsets plusSystemBottom(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return inset == 0 ? this : copyWith(bottom: bottom + inset);
  }

  /// Üst dolguya durum çubuğu payını ekler.
  ///
  /// `AppBar`'ı olan sayfalar buna İHTİYAÇ DUYMAZ (Scaffold payı çubuğa
  /// verir); yalnız üst çubuğu olmayan tam ekran yüzeyler için.
  EdgeInsets plusSystemTop(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).top;
    return inset == 0 ? this : copyWith(top: top + inset);
  }
}

/// Alta serbestçe duran `FloatingActionButton`'ın kapladığı yükseklik.
///
/// **Neden gerekli.** Scaffold FAB'ı sistem payının ÜSTÜNE koyar
/// (`FabFloatOffsetY.getOffsetY`:
/// `safeMargin = max(16, minViewPadding.bottom - bottomContentHeight + 16)`),
/// ama listeye bunu SÖYLEMEZ: gövdenin `MediaQuery`'si FAB'dan habersizdir.
/// Ölçüldü — 411×914dp yüzeyde 48dp gezinme çubuğuyla `safeMargin` 64 oluyor,
/// FAB y **794–850** arasına düşüyor; alt dolgusu `16 + 48 = 64` olan liste ise
/// tam **850**'de bitiyor. Yani son kartın sağ alt köşesi birebir FAB'ın
/// altında kalıyor.
///
/// [plusSystemBottom] ile birlikte kullanılır; sırası önemsizdir çünkü ikisi de
/// yalnız `bottom`'a ekler.
extension FabClearance on EdgeInsets {
  /// [fabHeight]: normal FAB 56, `FloatingActionButton.extended` **48**.
  EdgeInsets plusFabClearance({double fabHeight = 56}) =>
      copyWith(bottom: bottom + fabHeight + kFloatingActionButtonMargin);
}
