import 'package:flutter/material.dart';

/// Uygulamanın tasarım jetonları: renk tabanı, köşe ve yazı ölçeği.
///
/// Bu dosya gelene kadar ölçek yoktu, yalnız alışkanlık vardı: `lib/` içinde
/// 25 ayrı yazı boyutu (10,5 · 11,5 · 12,5 · 13,5 · 14,5 dahil), 17 ayrı köşe
/// yarıçapı ve 61 ayrı renk kodu sayıldı. "Premium" eksikliği süsten değil bu
/// dağınıklıktan geliyordu — iki komşu kart 12 ve 14 yarıçapla, iki komşu
/// etiket 12 ve 12,5 puntoyla çiziliyordu.
///
/// Yeni kod buradan ve temadan okur. Eski satır içi değerler yüzey yüzey
/// taşınıyor; `test/guards/design_tokens_guard_test.dart` o arada sayının
/// ARTMASINI engeller.
abstract final class AppPalette {
  /// Marka rengi = işlemler bölümünün mavisi (üst çubuk gradyanıyla aynı).
  static const Color brand = Color(0xFF3B82F6);

  /// Açık zeminde METİN ve dolu düğme için marka tonu. [brand] beyaz üstünde
  /// 3,7:1 veriyor (AA'nın altında); bu ton sayfa zemininde 4,9:1, kartta
  /// 5,2:1. Oranlar `app_theme_test.dart`'ta ölçülür.
  static const Color brandOnLight = Color(0xFF2563EB);

  /// Koyu zeminde marka tonu.
  static const Color brandOnDark = Color(0xFF7AB0FF);

  // Sayfa zemini ile kart zemini AYRI: kart, gölgeye yaslanmadan zeminden
  // ayrılır (açıkta beyaz kart / kırık beyaz sayfa, koyuda bir ton açık kart).
  static const Color pageLight = Color(0xFFF7F8FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color pageDark = Color(0xFF111319);
  static const Color cardDark = Color(0xFF171A22);

  static const Color inkLight = Color(0xFF0F172A);
  static const Color inkMutedLight = Color(0xFF55606F);
  static const Color inkDark = Color(0xFFF2F4F8);
  static const Color inkMutedDark = Color(0xFFA7B0BE);

  /// Hata/uyarı METNİ. Bölüm kırmızısı (`AppGradients.debt`) metin için
  /// fazla açık; bu ton sayfa zemininde 4,8:1.
  static const Color dangerOnLight = Color(0xFFD81743);
  static const Color dangerOnDark = Color(0xFFFB7185);
}

/// Köşe yarıçapları. Üç değer + hap.
abstract final class AppRadius {
  /// Düğme, alan, çip, satır.
  static const double control = 12;

  /// Kart, diyalog.
  static const double card = 20;

  /// Alt sayfanın üst köşeleri.
  static const double sheet = 28;

  /// Tam yuvarlak (hap, rozet).
  static const double pill = 999;

  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}

/// Yazı ölçeği: altı boyut, üç ağırlık.
///
/// Tema rolleri ([AppTheme]) bunlardan kurulur; satır içi `fontSize` yazmak
/// yerine `Theme.of(context).textTheme` rolü kullanılır.
abstract final class AppType {
  static const double caption = 12;
  static const double body = 14;
  static const double bodyLarge = 16;
  static const double title = 20;
  static const double headline = 28;
  static const double display = 40;

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w600;
  static const FontWeight strong = FontWeight.w700;

  /// Ölçekteki boyutlar (bekçi testi bunu okur).
  static const List<double> sizes = [
    caption,
    body,
    bodyLarge,
    title,
    headline,
    display,
  ];
}
