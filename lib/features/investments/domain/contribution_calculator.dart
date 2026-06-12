import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';

/// Katkı muhasebesinin saf kuralları. UI'dan bağımsız test edilebilsin diye
/// burada yaşar; cüzdan kuplajı (costDiff) bloc'ta aynen kalır.

/// Mod A — nakit katkı: tutar hem maliyete hem güncel değere eklenir.
InvestmentEntity applyCashContribution(
  InvestmentEntity inv,
  double contribution,
) {
  return inv.copyWith(
    amount: inv.amount + contribution,
    currentValue: inv.currentValue + contribution,
  );
}

/// Mod B — varlık alımı: miktar ve ödenen ayrı ayrı işlenir.
/// Canlı fiyat biliniyorsa güncel değer piyasaya oturtulur
/// (yeniMiktar × fiyatTL); bilinmiyorsa yalnız ödenen kadar artar.
/// `paid` 0 olabilir (hediye varlık) — defterde hareket oluşmaz, fark kâr
/// olarak görünür.
InvestmentEntity applyAssetPurchase(
  InvestmentEntity inv, {
  required double qtyAdded,
  required double paid,
  double? livePriceTl,
  String? liveCurrency,
}) {
  final newQuantity = (inv.quantity ?? 0) + qtyAdded;
  final newCurrentValue = livePriceTl != null
      ? newQuantity * livePriceTl
      : inv.currentValue + paid;
  return inv.copyWith(
    amount: inv.amount + paid,
    currentValue: newCurrentValue,
    quantity: newQuantity,
    currency: liveCurrency ?? inv.currency,
  );
}
