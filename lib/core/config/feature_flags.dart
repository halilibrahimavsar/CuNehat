import 'package:flutter/foundation.dart';

/// Geliştirilmekte olan özelliklerin derleme zamanı bayrakları.
///
/// **Kural:** bayrak yalnız ARAYÜZ GİRİŞLERİNİ gizler. Şema, adapter ve veri
/// yolu her derlemede vardır: bayrağı kapalı bir sürüm, bayrağı açık bir
/// sürümün yazdığı veriyi (ya da yedeği) okuyabilmeli — aksi hâlde bayrak
/// veri kaybına dönüşürdü.
abstract final class FeatureFlags {
  /// Kredi kartı cüzdanı (kesim/son ödeme, ekstre özeti, borç sayfası kart
  /// bölümü, taksitli harcama).
  ///
  /// Geliştirme ve profil derlemelerinde AÇIK, Play'e giden release
  /// derlemesinde KAPALI; açmak için
  /// `--dart-define=CUHAT_CREDIT_CARDS=true`. Ücretsiz/Pro kararı verilmeden
  /// ve kart ekstresi okuma gerçek örneklerle ölçülmeden açılmaz.
  static const bool creditCards = bool.fromEnvironment(
    'CUHAT_CREDIT_CARDS',
    defaultValue: !kReleaseMode,
  );
}
