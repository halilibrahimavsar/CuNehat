import 'dart:ui';

import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Portföy toplamı İKİ ayrı yoldan hesaplanıyor:
///
/// * üst çubuk → `WalletMetricsService._syncInvestmentImpl`, `roundToCents` ile
/// * özet kart → `InvestmentLoaded.totalCurrentValue`
///
/// İkisi farklı yuvarlarsa kullanıcı aynı portföy için iki sayı görüyor.
/// Cihazda ölçülen gerçek hata buydu: üst çubuk 5.968.277,09 ₺ derken kart
/// 5.968.277,08 ₺ diyordu (ham toplam tam .085'e denk geliyor; `roundToCents`
/// yarımı yukarı, `NumberFormat` çifte yuvarlar).
void main() {
  setUp(() => Intl.defaultLocale = 'tr');

  InvestmentEntity asset(String id, double amount, double currentValue) =>
      InvestmentEntity(
        id: id,
        userId: 'u1',
        walletId: 'w1',
        name: id,
        amount: amount,
        currentValue: currentValue,
        type: InvestmentType.gold,
        color: const Color(0xFFFFC107),
        dateAdded: DateTime(2026, 1, 1),
      );

  /// Cüzdan metriğinin yaptığı hesabın birebir aynısı.
  double walletMetricTotal(List<InvestmentEntity> list) => roundToCents(
      list.fold<double>(0.0, (sum, item) => sum + item.currentValue));

  test('özet kart toplamı cüzdan metriğiyle AYNI kuruşa düşer', () {
    // .085'e denk gelen gerçek senaryo: ikisi ayrışıyordu.
    final list = [
      asset('a', 5000000.0, 5968277.0),
      asset('b', 900000.0, 0.045),
      asset('c', 72369.76, 0.04),
    ];
    final state = InvestmentLoaded(list, totalAmount: 5972369.76);

    expect(state.totalCurrentValue, walletMetricTotal(list));
    expect(
      formatMoney(state.totalCurrentValue),
      formatMoney(walletMetricTotal(list)),
      reason: 'üst çubuk ile özet kart aynı metni yazmalı',
    );
  });

  test('gösterilen kâr, gösterilen iki sayının farkına eşittir', () {
    // Kullanıcı ekrandaki değeri ve maliyeti çıkarınca kâr/zararı bulmalı.
    final list = [
      asset('a', 5000000.0, 5968277.0),
      asset('b', 900000.0, 0.045),
      asset('c', 72369.76, 0.04),
    ];
    final state = InvestmentLoaded(list, totalAmount: 5972369.76);

    expect(
      state.totalProfit,
      roundToCents(state.totalCurrentValue - 5972369.76),
    );
    // Kart artık üst çubukla aynı toplamı (…,09) yazdığı için kâr da onunla
    // tutarlı: 5.968.277,09 − 5.972.369,76 = −4.092,67. Hata, kartın …,08
    // yazarken farkı …,09 üzerinden hesaplamasıydı — ekrandaki üç sayı
    // birbirini tutmuyordu.
    expect(formatMoney(state.totalCurrentValue), '5.968.277,09 ₺');
    expect(formatMoney(state.totalProfit), '-4.092,67 ₺');
  });

  test('boş portföyde toplamlar sıfır, yüzde sıfıra bölmez', () {
    const state = InvestmentLoaded([]);
    expect(state.totalCurrentValue, 0.0);
    expect(state.totalProfit, 0.0);
    expect(state.totalProfitPercentage, 0.0);
  });
}
