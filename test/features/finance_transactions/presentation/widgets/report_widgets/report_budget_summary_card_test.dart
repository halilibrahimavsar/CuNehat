import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Bütçe limitleri AYLIKTIR (`BudgetEntity.limitAmount`).
///
/// Ölçülen hata: rapor kartı harcamayı SEÇİLİ ARALIKTAN, limiti ise aylık
/// tanımdan alıyordu. "Bu Yıl" seçiliyken 12 aylık harcama 1 aylık limite
/// bölünüyor ve kart "%340 aşıldı" derken Bütçeler sayfası aynı anda "%28"
/// diyordu — aynı bütçe, aynı veri, iki ekran, iki cevap.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget host(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: 328, child: child),
          ),
        ),
      );

  const statuses = [
    BudgetStatus(categoryId: 'm', label: 'Market', spent: 1200, limit: 1000),
  ];

  testWidgets('tam ayda RAKAM gösterir, orantılama notu YOK', (tester) async {
    await tester.pumpWidget(host(ReportBudgetSummaryCard(
      statuses: statuses,
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Market'), findsOneWidget);
    expect(find.byKey(const ValueKey('budget-prorated-note')), findsNothing);
  });

  testWidgets('ay olmayan dönemde limit orantılıdır ve kart bunu SÖYLER',
      (tester) async {
    // Haftalık bakan kullanıcı bütçesini görmeye devam eder (eskiden kart
    // yalnız "bütçeler aylıktır" diyordu).
    await tester.pumpWidget(host(ReportBudgetSummaryCard(
      statuses: const [
        BudgetStatus(
            categoryId: 'm',
            label: 'Market',
            spent: 200,
            limit: 230,
            prorated: true),
      ],
      periodDays: 7,
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Market'), findsOneWidget);
    expect(find.text('Aylık limitler bu 7 günlük döneme orantılandı.'),
        findsOneWidget);
  });

  testWidgets('bütçe yokken hiç çizilmez', (tester) async {
    await tester.pumpWidget(host(ReportBudgetSummaryCard(
      statuses: const [],
      onTap: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(ReportBudgetSummaryCard)).height, 0);
  });

  group('computeBudgetStatuses', () {
    CategoryData cat(String id, double total) =>
        CategoryData(id, total, const [], const Color(0xFF000000));

    test('tam ay (15–14 dahil) limiti OLDUĞU gibi kullanır', () {
      for (final range in [
        DateTimeRange(
            start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30, 23, 59)),
        DateTimeRange(
            start: DateTime(2026, 9, 15), end: DateTime(2026, 10, 14, 23, 59)),
      ]) {
        final s = computeBudgetStatuses(
          budgets: const [BudgetEntity(categoryId: 'm', limitAmount: 3000)],
          expenseFull: [cat('m', 500)],
          range: range,
          labelFor: (t) => t,
        ).single;
        expect(s.limit, 3000);
        expect(s.prorated, isFalse);
      }
    });

    test('haftalık dönemde limit gün sayısıyla orantılanır', () {
      final s = computeBudgetStatuses(
        budgets: const [BudgetEntity(categoryId: 'm', limitAmount: 3043.75)],
        expenseFull: [cat('m', 500)],
        range: DateTimeRange(
            start: DateTime(2026, 9, 23), end: DateTime(2026, 9, 29, 23, 59)),
        labelFor: (t) => t,
      ).single;
      expect(s.limit, closeTo(700, 0.001)); // 3043,75 × 7 / 30,4375
      expect(s.prorated, isTrue);
    });
  });
}
