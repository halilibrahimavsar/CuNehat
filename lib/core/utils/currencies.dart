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
