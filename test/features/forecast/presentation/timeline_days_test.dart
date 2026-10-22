import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_timeline_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final d1 = DateTime(2026, 11, 10);
  final d2 = DateTime(2026, 11, 11);
  final path = [
    BalancePoint(day: d1, expected: 900, low: 900, high: 900, planned: 1000),
    BalancePoint(day: d2, expected: 300, low: 200, high: 600, planned: 500),
  ];

  ForecastEvent event(double amount,
          {ForecastEventKind kind = ForecastEventKind.recurringExpense,
          ForecastCertainty certainty = ForecastCertainty.known,
          double? known,
          String walletId = 'w'}) =>
      ForecastEvent(
        date: d2,
        amount: amount,
        walletId: walletId,
        kind: kind,
        certainty: certainty,
        title: 't',
        knownAmount: known,
      );

  test('kesin çıkış/giriş, ekstrenin tahmini payı ve alacak ayrı kovalarda',
      () {
    final days = buildTimelineDays(path, [
      event(-200),
      event(5000, kind: ForecastEventKind.recurringIncome),
      event(-500,
          kind: ForecastEventKind.cardStatementEstimate,
          certainty: ForecastCertainty.expected,
          known: -300),
      event(700,
          kind: ForecastEventKind.receivable,
          certainty: ForecastCertainty.expected),
    ]);
    expect(days, hasLength(2));
    expect(days.first.events, isEmpty);
    final d = days.last;
    expect(d.out, 500); // 200 + ekstrenin kesin 300'ü
    expect(d.inn, 5000);
    expect(d.estimatedOut, 200);
    expect(d.expectedIn, 700);
    expect((d.planned, d.expected, d.low, d.high), (500, 300, 200, 600));
  });

  test('"Tüm cüzdanlar": olay KENDİ biriminden görüntü birimine çevrilir', () {
    final days = buildTimelineDays(
        path,
        [
          event(-10, walletId: 'usd'),
          event(-100),
        ],
        rateOf: (e) => e.walletId == 'usd' ? 30 : 1);
    expect(days.last.out, 10 * 30 + 100);
  });
}
