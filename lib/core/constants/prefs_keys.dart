/// Birden fazla katmanın paylaştığı SharedPreferences anahtarları.
///
/// Yalnızca tek bir sınıfın kullandığı anahtarlar burada değil, sahibinin
/// yanında durur. Buradakiler bilinçli olarak paylaşımlıdır: değeri yazan ve
/// okuyan taraflar farklı katmanlarda.
class PrefsKeys {
  const PrefsKeys._();

  /// Seçili arayüz dili ('tr' | 'en'). LanguageBloc yazar; bildirim metinleri
  /// widget ağacının dışında üretildiği için NotificationLocalizer da okur.
  static const String language = 'selected_language';
}
