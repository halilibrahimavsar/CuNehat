import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_engine.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/widgets/report_temp_budget_section.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final _today = DateTime(2026, 11, 10);

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
  }) async =>
      result;
}

const _categories = [
  CategoryEntity(id: 'food', name: 'Yeme', iconName: 'x', isExpense: true),
  CategoryEntity(
      id: 'cafe',
      name: 'Kafe',
      iconName: 'x',
      isExpense: true,
      parentId: 'food'),
];

TempBudgetEntity _temp(String id, DateTime start, DateTime end) =>
    TempBudgetEntity(
      id: id,
      walletId: 'w',
      name: 'Bütçe $id',
      limitAmount: 1000,
      startDate: start,
      endDate: end,
      categoryIds: const ['food'],
    );

ForecastResult _result() => ForecastResult(
      wallets: ForecastEngine(
        today: _today,
        period: DateTimeRange(
            start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 30)),
        categories: _categories,
      ).projectAll([
        WalletForecastInput(
          wallet: WalletEntity(
            id: 'w',
            userId: 'u',
            name: 'w',
            balance: 0,
            debt: 0,
            credit: 0,
            investment: 0,
            colorHex: '0xFF000000',
            iconName: 'x',
            createdAt: DateTime(2026, 1, 1),
            openingBalance: 0,
          ),
          ledger: [
            TransactionEntity(
              id: 't',
              userId: 'u',
              walletId: 'w',
              title: 'kahve',
              tag: 'cafe',
              amount: 1200,
              date: DateTime(2026, 10, 21),
              type: TransactionTypeModel.expense,
            ),
          ],
          tempBudgets: [
            _temp('oct', DateTime(2026, 10, 20), DateTime(2026, 10, 25)),
            _temp('nov', DateTime(2026, 11, 20), DateTime(2026, 11, 22)),
          ],
        ),
      ]),
      categories: _categories,
    );

void main() {
  setUp(() => Intl.defaultLocale = 'tr_TR');

  Future<AppLocalizations> pump(
    WidgetTester tester, {
    required DateTimeRange range,
    void Function(BudgetOutlook, Set<String>)? onTap,
  }) async {
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
          child: ReportTempBudgetSection(
            userId: 'u',
            walletId: 'w',
            range: range,
            periodOf: () => range,
            onTap: onTap ?? (_, __) {},
            service: _FakeService(_result()),
            today: _today,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  testWidgets(
      'yalnız seçili dönemle KESİŞEN bütçeler; biten sonucunu yazar, alt '
      'kategori harcaması sayılmış', (tester) async {
    final l10n = await pump(tester,
        range: DateTimeRange(
            start: DateTime(2026, 10, 1), end: DateTime(2026, 10, 31)));

    expect(find.text(l10n.tempBudgetSectionTitle), findsOneWidget);
    expect(
        find.byKey(const ValueKey('report-temp-budget-oct')), findsOneWidget);
    expect(find.byKey(const ValueKey('report-temp-budget-nov')), findsNothing);
    // 1.200 / 1.000 → 200 aştı.
    expect(find.textContaining('aştı'), findsOneWidget);
  });

  testWidgets('kesişen yoksa bölüm hiç çizilmez', (tester) async {
    await pump(tester,
        range: DateTimeRange(
            start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)));
    expect(find.byKey(const ValueKey('report-temp-budgets')), findsNothing);
  });

  testWidgets('dokunuş bütçeyi ve alt kategorileri dahil kümeyi iletir',
      (tester) async {
    BudgetOutlook? tapped;
    Set<String>? tags;
    await pump(
      tester,
      range: DateTimeRange(
          start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 30)),
      onTap: (o, t) {
        tapped = o;
        tags = t;
      },
    );

    await tester.tap(find.byKey(const ValueKey('report-temp-budget-nov')));
    expect(tapped!.id, 'nov');
    expect(tags, {'food', 'cafe'});
  });
}
