import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_engine.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_cubit.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_estimates_cubit.dart';
import 'package:cunehat/features/forecast/presentation/pages/forecast_page.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_timeline_card.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _today = DateTime(2026, 11, 10);
final _november =
    DateTimeRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 30));

class _FakeService extends Fake implements ForecastService {
  final ForecastResult result;
  _FakeService(this.result);

  @override
  Future<ForecastResult> forecast({
    required String? userId,
    required DateTimeRange period,
    DateTimeRange? previousPeriod,
    DateTime? today,
    int horizonDays = 30,
    String? walletId,
  }) async =>
      result;
}

WalletEntity _wallet(String id,
        {double balance = 20000,
        CreditCardInfo? card,
        String? name,
        String currency = 'TRY'}) =>
    WalletEntity(
      id: id,
      userId: 'u',
      name: name ?? id,
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'wallet',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
      currency: currency,
      creditCard: card,
    );

TransactionEntity _tx(DateTime d, double amount,
        {String walletId = 'w', String tag = 'food', String? title}) =>
    TransactionEntity(
      id: '$walletId-${d.toIso8601String()}-$amount',
      userId: 'u',
      walletId: walletId,
      title: title ?? tag,
      tag: tag,
      amount: amount,
      date: d,
      type: TransactionTypeModel.expense,
    );

RecurringTransactionEntity _template(String title, double amount, DateTime next,
        {bool income = false, String tag = 'rent'}) =>
    RecurringTransactionEntity(
      id: title,
      userId: 'u',
      walletId: 'w',
      title: title,
      tag: tag,
      amount: amount,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      frequency: RecurringFrequency.monthly,
      nextExecutionDate: next,
      anchorDay: next.day,
    );

const _categories = [
  CategoryEntity(id: 'food', name: 'Yeme', iconName: 'x', isExpense: true),
  CategoryEntity(id: 'rent', name: 'Kira', iconName: 'x', isExpense: true),
];

ForecastResult _result(
    {double balance = 20000, bool withHistory = true, bool withUsd = false}) {
  final ledger = withHistory
      ? [
          for (var i = 0; i < 28; i++) _tx(DateTime(2026, 10, 13 + i, 12), 100),
          _tx(DateTime(2026, 11, 3), 9000, tag: 'tech', title: 'Telefon'),
        ]
      : [_tx(DateTime(2026, 11, 8), 100)];
  final inputs = [
    WalletForecastInput(
      wallet: _wallet('w', balance: balance, name: 'Maaş hesabı'),
      ledger: ledger,
      templates: [
        _template('Maaş', 30000, DateTime(2026, 11, 25),
            income: true, tag: 'salary'),
        _template('Kira', 8000, DateTime(2026, 12, 1)),
      ],
      budgets: const [
        BudgetEntity(categoryId: 'food', walletId: 'w', limitAmount: 2500),
      ],
      tempBudgets: [
        TempBudgetEntity(
          id: 'trip',
          walletId: 'w',
          name: 'Gezi',
          limitAmount: 200,
          startDate: DateTime(2026, 11, 20),
          endDate: DateTime(2026, 11, 22),
          categoryIds: const ['food'],
        ),
      ],
    ),
    WalletForecastInput(
      wallet: _wallet('card',
          balance: -1000,
          name: 'Bonus',
          card: const CreditCardInfo(
              closingDay: 25, dueDay: 15, paymentWalletId: 'w')),
      ledger: [_tx(DateTime(2026, 10, 20), 1000, walletId: 'card')],
    ),
    if (withUsd)
      WalletForecastInput(
        wallet: _wallet('usd', balance: 100, name: 'Dolar', currency: 'USD'),
        ledger: const [],
        templates: [_template('Netflix', 15, DateTime(2026, 11, 18))],
        tempBudgets: [
          TempBudgetEntity(
            id: 'holiday',
            walletId: 'usd',
            name: 'Tatil',
            limitAmount: 300,
            startDate: DateTime(2026, 11, 20),
            endDate: DateTime(2026, 11, 22),
            categoryIds: const ['food'],
          ),
        ],
      ),
  ];
  return ForecastResult(
    wallets: ForecastEngine(
      today: _today,
      period: _november,
      categories: _categories,
    ).projectAll(inputs),
    categories: _categories,
  );
}

void main() {
  setUp(() => Intl.defaultLocale = 'tr_TR');

  Future<AppLocalizations> pump(WidgetTester tester, ForecastResult result,
      {Size size = const Size(900, 4200),
      double textScale = 1,
      bool? estimates = false,
      ForecastEstimatesCubit? estimatesCubit,
      bool reveal = false}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final cubit = ForecastCubit(
      _FakeService(result),
      userId: 'u',
      walletId: 'w',
      periodOf: () => _november,
      clock: () => _today,
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(
              value: reveal ? (cubit..reveal()) : (cubit..load())),
          if (estimatesCubit != null) BlocProvider.value(value: estimatesCubit),
        ],
        child: ForecastView(walletId: 'w', today: _today, estimates: estimates),
      ),
    ));
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  testWidgets(
      'TAHMİN: manşetin altında maaşa kadar yetiyor der; dönem, bütçe, '
      'yaklaşanlar ve kart bölümleri çizilir', (tester) async {
    final l10n = await pump(tester, _result(), estimates: true);

    expect(find.text(l10n.forecastHeadlineUntilIncome('Maaş', '25 Kas')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('forecast-period-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('forecast-no-pace')), findsNothing);

    // Aylık bütçe 2.500: bu hızla 25 Kas'ta dolar.
    final food = find.byKey(const ValueKey('forecast-budget-food'));
    expect(
        find.descendant(of: food, matching: find.text('Yeme')), findsOneWidget);
    expect(
        find.descendant(
            of: food,
            matching: find.text(l10n.forecastBudgetFillsOn('25 Kas'))),
        findsOneWidget);
    // Geçici bütçe yaklaşan: "bu hızla ~300 harcanır".
    final trip = find.byKey(const ValueKey('forecast-budget-trip'));
    expect(
        find.descendant(of: trip, matching: find.text('Gezi')), findsOneWidget);
    expect(find.descendant(of: trip, matching: find.textContaining('300')),
        findsWidgets);

    // Yaklaşanlar: kart ekstresi ödemesi (kesin) bu hesaptan çıkar.
    final upcoming = find.byKey(const ValueKey('forecast-upcoming-card'));
    expect(
        find.descendant(
            of: upcoming,
            matching: find.text(l10n.forecastEventCardPayment('Bonus'))),
        findsOneWidget);
    expect(find.descendant(of: upcoming, matching: find.text('Kira')),
        findsOneWidget);
    expect(find.descendant(of: upcoming, matching: find.text('Maaş')),
        findsOneWidget);

    expect(find.byKey(const ValueKey('forecast-cards-card')), findsOneWidget);
  });

  testWidgets('TAHMİN: az kayıtta tahmin uydurulmaz: kapı kartı ve kalan gün',
      (tester) async {
    final l10n =
        await pump(tester, _result(withHistory: false), estimates: true);

    expect(find.byKey(const ValueKey('forecast-no-pace')), findsOneWidget);
    // İlk kayıt 8 Kas → 2 gün gözlem → 12 gün daha.
    expect(find.text(l10n.forecastNoPaceBody(12)), findsOneWidget);
    // Planlı olaylar yine görünür.
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('forecast-upcoming-card')),
            matching: find.text('Kira')),
        findsOneWidget);
  });

  testWidgets('TAHMİN: bakiye yetmeyecekse mor satır UYARIR', (tester) async {
    final l10n = await pump(tester, _result(balance: 1000), estimates: true);
    // 1.000 − 100/gün − 15 Kas kart ödemesi (1.000) → 15 Kas'ta eksi.
    expect(find.text(l10n.forecastHeadlineNegative('15 Kas')), findsOneWidget);
    // Plan (hızsız) eksiye inmiyor: manşet plan cümlesi kalır.
    expect(find.text(l10n.forecastPlanHeadlineUntilIncome('Maaş', '25 Kas')),
        findsOneWidget);
  });

  group('PLAN (varsayılan)', () {
    testWidgets(
        'manşet yalnız planlıyla konuşur; hız cümlesi, mor satır ve hız kapısı '
        'yok', (tester) async {
      final l10n = await pump(tester, _result(), estimates: null);

      expect(find.text(l10n.forecastPlanHeadlineUntilIncome('Maaş', '25 Kas')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('forecast-headline-estimate')),
          findsNothing);
      expect(find.text(l10n.forecastHeadlineUntilIncome('Maaş', '25 Kas')),
          findsNothing);
      // Bütçe: hızdan "25 Kas'ta dolar" demez; planlılarla kalan yazar.
      expect(find.text(l10n.forecastBudgetFillsOn('25 Kas')), findsNothing);
      expect(find.byKey(const ValueKey('forecast-budget-estimate-food')),
          findsNothing);
      expect(
          find.byKey(const ValueKey('forecast-period-estimate')), findsNothing);
      // Yaklaşanlar yine tarihleriyle.
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('forecast-upcoming-card')),
              matching: find.text(l10n.forecastEventCardPayment('Bonus'))),
          findsOneWidget);
    });

    testWidgets('planlı ödemeler bakiyeyi eksiye indiriyorsa manşet UYARIR',
        (tester) async {
      final l10n = await pump(tester, _result(balance: 500));
      // 500 − 15 Kas kart ödemesi (1.000) → maaştan (25 Kas) önce eksi.
      expect(find.text(l10n.forecastPlanHeadlineNegative('15 Kas')),
          findsOneWidget);
    });

    testWidgets('az kayıtta hız kapısı kartı gösterilmez', (tester) async {
      await pump(tester, _result(withHistory: false));
      expect(find.byKey(const ValueKey('forecast-no-pace')), findsNothing);
    });

    testWidgets('güne dokununca o günün kalemleri panelde', (tester) async {
      final l10n = await pump(tester, _result());
      final panel = find.byKey(const ValueKey('forecast-day-panel'));
      expect(
          find.descendant(of: panel, matching: find.text(l10n.forecastDayHint)),
          findsOneWidget);

      // 15 Kas = bugünden 5 gün sonra (31 günlük ufuk).
      final chart = tester.getRect(find.byType(ForecastTimelineChart));
      final chartW = chart.width - 46;
      final step = chartW / 31;
      await tester.tapAt(Offset(chart.left + 46 + step * 5.5, chart.top + 20));
      await tester.pumpAndSettle();

      expect(
          find.descendant(
              of: panel,
              matching: find.text(l10n.forecastEventCardPayment('Bonus'))),
          findsOneWidget);
      expect(
          find.descendant(
              of: panel,
              matching: find.textContaining(l10n.forecastDaysAway(5))),
          findsOneWidget);
    });

    testWidgets('anahtar tahmini AÇAR: mor katman eklenir, plan manşeti kalır',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final estimates =
          ForecastEstimatesCubit(await SharedPreferences.getInstance());
      addTearDown(estimates.close);
      final l10n = await pump(tester, _result(),
          estimates: null, estimatesCubit: estimates);
      expect(find.byKey(const ValueKey('forecast-headline-estimate')),
          findsNothing);

      await tester.tap(find.byKey(const ValueKey('forecast-estimates-switch')));
      await tester.pumpAndSettle();

      expect(estimates.state, isTrue);
      expect(find.byKey(const ValueKey('forecast-headline-estimate')),
          findsOneWidget);
      expect(find.text(l10n.forecastPlanHeadlineUntilIncome('Maaş', '25 Kas')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('forecast-budget-estimate-food')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('forecast-period-estimate')),
          findsOneWidget);
    });
  });

  group('tahmin bildiriminden açılış', () {
    Future<ForecastEstimatesCubit> setting() async {
      SharedPreferences.setMockInitialValues({});
      final c = ForecastEstimatesCubit(await SharedPreferences.getInstance());
      addTearDown(c.close);
      return c;
    }

    testWidgets(
        'tahmin BU AÇILIŞ için görünür ve nedeni yazar; anahtarı kapatmak '
        'onu bitirir, kalıcı ayar hiç değişmez', (tester) async {
      final estimates = await setting();
      final l10n = await pump(tester, _result(),
          estimates: null, estimatesCubit: estimates, reveal: true);

      expect(find.byKey(const ValueKey('forecast-headline-estimate')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('forecast-budget-estimate-food')),
          findsOneWidget);
      expect(find.text(l10n.forecastEstimatesTemporaryDesc), findsOneWidget);
      expect(estimates.state, isFalse);

      await tester.tap(find.byKey(const ValueKey('forecast-estimates-switch')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('forecast-headline-estimate')),
          findsNothing);
      expect(find.text(l10n.forecastEstimatesOffDesc), findsOneWidget);
      expect(estimates.state, isFalse);
    });

    testWidgets('sayfa AÇIKKEN gelen bildirim isteği tahmini gösterir',
        (tester) async {
      final requests = HomeNavigationRequests();
      getIt.registerSingleton<HomeNavigationRequests>(requests);
      addTearDown(() => getIt.unregister<HomeNavigationRequests>());
      final estimates = await setting();
      await pump(tester, _result(), estimates: null, estimatesCubit: estimates);
      expect(find.byKey(const ValueKey('forecast-headline-estimate')),
          findsNothing);

      requests.focusForecast();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('forecast-headline-estimate')),
          findsOneWidget);
      expect(requests.takeForecastFocus(), isNull, reason: 'istek tüketildi');
      expect(estimates.state, isFalse);
    });
  });

  testWidgets('"Nasıl hesaplandı?" hızı ve kırpılan tek seferlik kalemi yazar',
      (tester) async {
    final l10n = await pump(tester, _result());

    await tester.tap(find.byKey(const ValueKey('forecast-how')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.forecastHowTitle), findsWidgets);
    expect(find.text(l10n.forecastHowOneOffs(1)), findsOneWidget);
    expect(find.textContaining('Telefon'), findsOneWidget);
  });

  for (final estimates in [false, true]) {
    for (final (size, scale) in [
      (const Size(360, 800), 1.0),
      (const Size(360, 800), 1.5),
      (const Size(320, 568), 1.3),
    ]) {
      testWidgets(
          '${size.width.toInt()}×${size.height.toInt()} telefonda (metin '
          'ölçeği $scale, ${estimates ? 'tahmin' : 'plan'}) taşma yok',
          (tester) async {
        await pump(tester, _result(withUsd: true),
            size: size, textScale: scale, estimates: estimates);
        // Gün paneli de açık olsun (en uzun hâli).
        final chart = tester.getRect(find.byType(ForecastTimelineChart));
        await tester.tapAt(Offset(chart.right - 4, chart.top + 20));
        await tester.pumpAndSettle();
        final list = find.byKey(const ValueKey('forecast-list'));
        for (var i = 0; i < 14; i++) {
          await tester.drag(list, const Offset(0, -400));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  // Cihazda 320dp + 1,3 yazı ölçeğinde "Bugün" ile bir haftalık etiket üst
  // üste biniyordu (sabit 7 günlük adım). Taşma istisnası ATMAZ — etiketin
  // varlığına bakılır.
  testWidgets('bakiye grafiği dar ekranda haftalık etiketi seyreltir',
      (tester) async {
    final week = AppFormatters.dayMonth.format(DateTime(2026, 11, 17));
    final twoWeeks = AppFormatters.dayMonth.format(DateTime(2026, 11, 24));

    await pump(tester, _result(), size: const Size(411, 900));
    expect(find.text(week), findsOneWidget);

    await pump(tester, _result(), size: const Size(320, 900), textScale: 1.3);
    expect(find.text(week), findsNothing);
    expect(find.text(twoWeeks), findsOneWidget);
  });

  // "Tüm cüzdanlar" tahmini sonraki sürümün tüm cüzdan raporunda; Gelecek
  // yalnız aktif cüzdanı gösterir.
  group('yalnız bu cüzdan', () {
    testWidgets('çok cüzdanda da kapsam seçimi yok', (tester) async {
      await pump(tester, _result(withUsd: true));
      expect(find.byKey(const ValueKey('forecast-scope')), findsNothing);
      expect(find.byType(SegmentedButton<Object>), findsNothing);
      expect(find.text('Tüm cüzdanlar'), findsNothing);
    });

    testWidgets('başka cüzdanın kalemi ve bütçesi görünmez', (tester) async {
      await pump(tester, _result(withUsd: true), estimates: true);
      // Bu cüzdanın tek seferlik bütçesi var, Dolar cüzdanınınki yok.
      expect(find.text('Gezi'), findsOneWidget);
      expect(find.text('Tatil'), findsNothing);
      expect(find.textContaining('Netflix'), findsNothing);
      expect(find.textContaining('Dolar'), findsNothing);
    });

    testWidgets('bağlı kart bölümde ve ödemesi bu hesabın kalemi olarak',
        (tester) async {
      final l10n = await pump(tester, _result(withUsd: true));
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('forecast-cards-card')),
              matching: find.text('Bonus')),
          findsOneWidget);
      expect(find.text(l10n.forecastEventCardPayment('Bonus')), findsOneWidget);
    });
  });
}
