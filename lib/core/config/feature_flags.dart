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
  /// 1.1.0 (versionCode 9) ile release derlemesinde de AÇIK. Gerekirse
  /// `--dart-define=CUHAT_CREDIT_CARDS=false` ile girişler yeniden gizlenir.
  static const bool creditCards = bool.fromEnvironment(
    'CUHAT_CREDIT_CARDS',
    defaultValue: true,
  );
}
