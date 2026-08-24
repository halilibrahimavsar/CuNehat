import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/widgets.dart';

/// Üç ekleme formunun (altın/hisse/özel) ORTAK alan doğrulaması.
///
/// Ayrı ayrı yazıldıklarında üçü üç farklı kural uyguluyordu: özel yatırım
/// sıfır maliyeti reddederken altın/hisse tamamen boş bir kaydı (0 maliyet +
/// 0 değer) kabul ediyor, hedef tutarı yalnız özel form doğruluyordu.
///
/// Kurallar:
/// - Maliyet ve mevcut değer sayı olmalı ve negatif olmamalı.
/// - İkisi birden 0 olamaz (boş kayıt); biri 0 olabilir — bedelsiz gelen
///   varlığın maliyeti sıfırdır, değeri henüz bilinmeyenin değeri sıfırdır.
///
/// Hedef tutarı burada YOK: hedef artık kaydın alanı değil, kendi kaydı
/// (`GoalEntity`) — doğrulaması hedef formunda.
///
/// Geçerliyse `null`, değilse gösterilecek hata metni döner.
String? validateInvestmentForm(
  BuildContext context, {
  required double? cost,
  required double? currentValue,
}) {
  final l10n = context.l10n;
  if (cost == null || cost < 0) return l10n.gecerliYatirimMiktariGirin;
  if (currentValue == null || currentValue < 0) {
    return l10n.gecerliMevcutDegerGirin;
  }
  if (cost == 0 && currentValue == 0) {
    return l10n.maliyetVeyaDegerSifirdanBuyuk;
  }
  return null;
}
