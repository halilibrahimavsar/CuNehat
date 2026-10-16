import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_engine.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_cubit.dart';
import 'package:cunehat/features/forecast/presentation/pages/forecast_page.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final _today = DateTime(2026, 11, 10);
final _november =
    DateTimeRange(start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 30));

class _FakeService extends Fake implements ForecastService {
  final ForecastResult result;
  _FakeService(this.result);

  @override
  Future<ForecastResult> forecast({
    required String userId,
    required DateTimeRange period,
    DateTimeRange? previousPeriod,
    DateTime? today,
    int horizonDays = 30,
  }) async =>
      result;
}

WalletEntity _wallet(String id,
        {double balance = 20000, CreditCardInfo? card, String? name}) =>
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

ForecastResult _result({double balance = 20000, bool withHistory = true}) {
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
      {Size size = const Size(900, 4200), double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final cubit = ForecastCubit(
      _FakeService(result),
      userId: 'u',
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
      home: BlocProvider.value(
        value: cubit..load(),
        child: ForecastView(walletId: 'w', today: _today),
      ),
    ));
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  testWidgets(
      'manşet maaşa kadar yetiyor der; dönem, bütçe, yaklaşanlar ve kart '
      'bölümleri çizilir', (tester) async {
    final l10n = await pump(tester, _result());

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

  testWidgets('az kayıtta tahmin uydurulmaz: kapı kartı ve kalan gün',
      (tester) async {
    final l10n = await pump(tester, _result(withHistory: false));

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

  testWidgets('bakiye yetmeyecekse manşet UYARIR', (tester) async {
    final l10n = await pump(tester, _result(balance: 1000));
    // 1.000 − 100/gün − 15 Kas kart ödemesi (1.000) → 15 Kas'ta eksi.
    expect(find.text(l10n.forecastHeadlineNegative('15 Kas')), findsOneWidget);
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

  for (final scale in [1.0, 1.5]) {
    testWidgets('360×800 telefonda (metin ölçeği $scale) taşma yok',
        (tester) async {
      await pump(tester, _result(),
          size: const Size(360, 800), textScale: scale);
      final list = find.byKey(const ValueKey('forecast-list'));
      for (var i = 0; i < 12; i++) {
        await tester.drag(list, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
