import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_timeline_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Gün paneli kesilmemiş ekstreyi yaklaşanlar listesiyle aynı dille yazar:
/// planda yalnız şimdiye kadarki kısım ("şimdiye kadar" etiketiyle) —
/// etiketsiz tutar kesinleşmiş ekstre gibi okunuyordu.
void main() {
  setUp(() => Intl.defaultLocale = 'tr_TR');

  final today = DateTime(2026, 11, 10);
  DateTime day(int i) => DateTime(2026, 11, 10 + i);
  const money = MoneyWriter(currency: 'TRY', visible: true);

  final f = WalletForecast(
    walletId: 'w',
    walletName: 'Hesap',
    currency: 'TRY',
    isCard: false,
    pace: null,
    daysUntilPace: 0,
    events: [
      ForecastEvent(
        date: day(1),
        amount: -500,
        walletId: 'w',
        kind: ForecastEventKind.cardStatementEstimate,
        certainty: ForecastCertainty.expected,
        title: 'Bonus',
        knownAmount: -300,
      ),
    ],
    overdue: const [],
    path: [
      BalancePoint(day: day(0), expected: 1000, low: 1000, high: 1000),
      BalancePoint(
          day: day(1), expected: 500, low: 450, high: 550, planned: 700),
      BalancePoint(
          day: day(2), expected: 500, low: 450, high: 550, planned: 700),
    ],
    period: null,
    budgets: const [],
    card: null,
    goals: const [],
  );

  Future<AppLocalizations> pump(WidgetTester tester,
      {required bool estimates}) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ForecastTimelineCard(
            forecast: f,
            money: money,
            today: today,
            horizonEnd: day(2),
            estimates: estimates,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final chart = tester.getRect(find.byType(ForecastTimelineChart));
    final step = (chart.width - 46) / 3;
    await tester.tapAt(Offset(chart.left + 46 + step * 1.5, chart.top + 20));
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  Finder inPanel(Finder f) => find.descendant(
      of: find.byKey(const ValueKey('forecast-day-panel')), matching: f);

  testWidgets('plan: ekstrenin şimdiye kadarki kısmı etiketiyle',
      (tester) async {
    final l10n = await pump(tester, estimates: false);
    expect(inPanel(find.text(money.withSign(-300))), findsOneWidget);
    expect(inPanel(find.text(l10n.forecastSoFarShort)), findsOneWidget);
  });

  testWidgets('tahmin: altında mor tahmini pay', (tester) async {
    final l10n = await pump(tester, estimates: true);
    expect(inPanel(find.text(l10n.forecastEstimatedPart(money(200)))),
        findsOneWidget);
    expect(inPanel(find.text(l10n.forecastSoFarShort)), findsNothing);
  });
}
