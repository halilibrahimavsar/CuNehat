import 'package:equatable/equatable.dart';

/// Canlı fiyat sorgusu sonucu.
///
/// [price] kaynağın kendi para biriminde ([currency]), [convertedPrice] ise
/// sorguda istenen hedef birime ([targetCurrency]) çevrilmiş birim fiyattır.
/// Hedef birim cüzdanın birimidir: portföy değerlemesi her zaman cüzdanın
/// biriminde yapılır (eskiden hedef koşulsuz TRY idi). Kur alınamazsa sorgu
/// hata ile düşer, asla kısmi/karışık birim değer dönmez.
class LivePriceQuote extends Equatable {
  final double price;
  final String currency;
  final double convertedPrice;
  final String targetCurrency;

  const LivePriceQuote({
    required this.price,
    required this.currency,
    required this.convertedPrice,
    required this.targetCurrency,
  });

  /// Fiyat kaynağı ile hedef birim aynı mı? Aynıysa "≈ karşılık" satırı
  /// gösterilmez (iki kez aynı sayıyı yazmak olurdu).
  bool get isSameCurrency => currency == targetCurrency;

  @override
  List<Object?> get props => [price, currency, convertedPrice, targetCurrency];
}
