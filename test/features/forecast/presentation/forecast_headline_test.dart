import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_timeline_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Hesap ZATEN ekside (ör. KMH) iken manşet "eksiye düşüyor" demez; bugün
/// vadeli bir kalemin eksiye ittiği hesap ise gerçekten düşüyordur.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    Intl.defaultLocale = 'tr_TR';
  });

  final l10n = lookupAppLocalizations(const Locale('tr'));
  const money = MoneyWriter(currency: 'TRY', visible: true);
  final today = DateTime(2026, 11, 10);
  DateTime day(int i) => DateTime(2026, 11, 10 + i);
  final horizonEnd = day(3);

  ForecastEvent event(int i, double amount,
          {ForecastEventKind kind = ForecastEventKind.recurringExpense}) =>
      ForecastEvent(
        date: day(i),
        amount: amount,
        walletId: 'w',
        kind: kind,
        certainty: ForecastCertainty.known,
        title: kind == ForecastEventKind.recurringIncome ? 'Maaş' : 'Kira',
      );

  WalletForecast forecast(List<double> planned, List<ForecastEvent> events,
          {List<double>? expected}) =>
      WalletForecast(
        walletId: 'w',
        walletName: 'Hesap',
        currency: 'TRY',
        isCard: false,
        pace: null,
        daysUntilPace: 0,
        events: events,
        overdue: const [],
        path: [
          for (var i = 0; i < planned.length; i++)
            BalancePoint(
              day: day(i),
              expected: (expected ?? planned)[i],
              low: (expected ?? planned)[i],
              high: (expected ?? planned)[i],
              planned: planned[i],
            ),
        ],
        period: null,
        budgets: const [],
        card: null,
        goals: const [],
      );

  test('zaten ekside: plan "şu an ekside" + en dip gün; tahmin en dibi söyler',
      () {
    final f = forecast([-500, -500, -1500, -1500], [event(2, -1000)],
        expected: [-550, -600, -1700, -1800]);

    final plan =
        forecastPlanHeadline(l10n, f, money, today, horizonEnd: horizonEnd);
    expect(plan.headline, l10n.forecastPlanHeadlineBelowZero);
    expect(plan.warning, isTrue);
    expect(plan.details,
        contains(l10n.forecastLowestPoint('12 Kas', money(-1500))));

    final estimate =
        forecastHeadline(l10n, f, money, today, horizonEnd: horizonEnd);
    expect(estimate.headline,
        l10n.forecastHeadlineBelowZeroLowest('13 Kas', money(-1800)));
    expect(estimate.warning, isTrue);
  });

  test('bugün vadeli kira artıdaki hesabı eksiye itiyorsa bu bir DÜŞÜŞTÜR', () {
    // Gün başı 300; bugünkü 1.000 kira yolun ilk noktasında: −700.
    final f = forecast([-700, -700, -700, -700], [event(0, -1000)]);

    final plan =
        forecastPlanHeadline(l10n, f, money, today, horizonEnd: horizonEnd);
    expect(plan.headline,
        l10n.forecastPlanHeadlineNegative(l10n.forecastTodayInline));
  });

  test('zaten ekside ve maaş bugün: tahmin manşeti çökmez (pencere boş)', () {
    final f = forecast([-500, -500, -500, -500],
        [event(0, 0.01, kind: ForecastEventKind.recurringIncome)]);
    // Gün başı −500,01 → zaten ekside; maaşa kadar pencere boş: bugün.
    final estimate =
        forecastHeadline(l10n, f, money, today, horizonEnd: horizonEnd);
    expect(
        estimate.headline,
        l10n.forecastHeadlineBelowZeroLowest(
            l10n.forecastTodayInline, money(-500)));
  });
}
