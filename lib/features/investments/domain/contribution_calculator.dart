import 'package:cunehat/core/utils/money_math.dart';
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
/// (yeniMiktar × [livePrice]); bilinmiyorsa yalnız ödenen kadar artar.
/// `paid` 0 olabilir (hediye varlık) — defterde hareket oluşmaz, fark kâr
/// olarak görünür.
///
/// [livePrice] CÜZDANIN biriminde olmalıdır (bkz. `LivePriceQuote
/// .convertedPrice`); `amount` ve `currentValue` aynı birimde tutulur.
/// [liveCurrency] ise fiyat KAYNAĞININ birimi — kayıtta bilgi olarak saklanır,
/// değerleme birimi değildir.
InvestmentEntity applyAssetPurchase(
  InvestmentEntity inv, {
  required double qtyAdded,
  required double paid,
  double? livePrice,
  String? liveCurrency,
}) {
  final newQuantity = (inv.quantity ?? 0) + qtyAdded;
  final newCurrentValue =
      livePrice != null ? newQuantity * livePrice : inv.currentValue + paid;
  return inv.copyWith(
    amount: inv.amount + paid,
    currentValue: newCurrentValue,
    quantity: newQuantity,
    currency: liveCurrency ?? inv.currency,
  );
}

/// Kısmi satış: kaydın [ratio] kadarlık kısmı elden çıkar.
///
/// Maliyet ORTALAMA maliyetten düşülür (FIFO/LIFO yok — kayıt tek kalemde
/// kümülatif `amount` tutuyor), böylece kalanın birim maliyeti değişmez ve
/// kâr/zarar yüzdesi satıştan etkilenmez.
///
/// Güncel değer: [livePrice] verilirse kalan miktar piyasaya oturtulur,
/// verilmezse aynı oranda düşülür. Satıştan gelen NAKİT burada hesaplanmaz;
/// kullanıcının eline geçen tutar ayrı girilir (defter kuplajı bloc'ta).
InvestmentEntity applyPartialSale(
  InvestmentEntity inv, {
  required double ratio,
  double? livePrice,
}) {
  assert(ratio > 0 && ratio < 1, 'ratio 0 ile 1 arasında olmalı');
  final remaining = 1 - ratio;
  final newQuantity = inv.quantity == null ? null : inv.quantity! * remaining;
  final newValue = (livePrice != null && newQuantity != null)
      ? newQuantity * livePrice
      : inv.currentValue * remaining;
  return inv.copyWith(
    amount: roundToCents(inv.amount * remaining),
    currentValue: roundToCents(newValue),
    quantity: newQuantity,
    // Deftere işlenmemiş maliyet de aynı oranda küçülür: kalan kaydın
    // "iade edilebilir" kısmı maliyetiyle aynı oranı korumalı.
    unbookedCost: roundToCents(inv.unbookedCost * remaining),
  );
}
