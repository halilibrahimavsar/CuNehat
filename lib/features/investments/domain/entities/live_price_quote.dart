import 'package:equatable/equatable.dart';

/// Canlı fiyat sorgusu sonucu. [price] kaynağın para biriminde,
/// [priceTl] her zaman TRY'ye çevrilmiş birim fiyattır; kur alınamazsa
/// sorgu hata ile düşer, asla kısmi/karışık birim değer dönmez.
class LivePriceQuote extends Equatable {
  final double price;
  final String currency;
  final double priceTl;

  const LivePriceQuote({
    required this.price,
    required this.currency,
    required this.priceTl,
  });

  @override
  List<Object?> get props => [price, currency, priceTl];
}
