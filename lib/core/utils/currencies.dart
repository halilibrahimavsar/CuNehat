/// Desteklenen para birimleri — tek kayıt noktası.
///
/// Cüzdan bazlı model: her cüzdanın bir birimi var (varsayılan TRY);
/// işlemler cüzdanın biriminde tutulur. Sembol her yerde SONEK olarak
/// yazılır ("12.50 $") — mevcut ₺ kullanımıyla tutarlı.
library;

const String kDefaultCurrency = 'TRY';

const List<String> kSupportedCurrencies = ['TRY', 'USD', 'EUR'];

const Map<String, String> kCurrencySymbols = {
  'TRY': '₺',
  'USD': r'$',
  'EUR': '€',
};

/// Bilinmeyen kod gelirse (eski/bozuk veri) kodun kendisi gösterilir;
/// sessizce ₺'ye düşmek yanlış birim iması olurdu.
String currencySymbol(String code) => kCurrencySymbols[code] ?? code;

/// "Küçük tutar" kabul edilen üst sınır — gürültü eşiği olarak kullanılır
/// (ör. harcama sıçraması uyarısında birkaç liralık kalemi elemek için).
///
/// Canlı kur DEĞİLDİR ve öyle olmamalı: eşik yalnız bir büyüklük mertebesi
/// ayarıdır, kur servisine bağlamak içgörü kartını ağa bağımlı kılardı.
/// Kabaca aynı alım gücüne denk gelen yuvarlak sayılar seçilmiştir.
const Map<String, double> kNoiseThresholds = {
  'TRY': 50,
  'USD': 2,
  'EUR': 2,
};

/// [code] birimi için gürültü eşiği; bilinmeyen kodda TRY değeri kullanılır.
double noiseThresholdFor(String code) =>
    kNoiseThresholds[code] ?? kNoiseThresholds[kDefaultCurrency]!;
