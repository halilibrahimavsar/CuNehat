import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_change_badge.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_top_payees_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Raporun analiz kartları: en çok harcanan yer, bütçe özeti ve kategori
/// bazlı değişim rozeti.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  Widget host(Widget child, {double width = 360}) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: width, child: child),
          ),
        ),
      );

  TransactionEntity tx(DateTime d, String title, double a,
          {bool income = false}) =>
      TransactionEntity(
        id: 'tx-${d.millisecondsSinceEpoch}-$title-$a',
        userId: 'u',
        walletId: 'w',
        title: title,
        tag: 'Market',
        amount: a,
        date: d,
        type:
            income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      );

  group('en çok harcanan yer', () {
    List<TransactionEntity> statementLike() => [
          tx(DateTime(2026, 6, 1), 'SOK-10419-USKUDAR', 320),
          tx(DateTime(2026, 6, 4), 'SOK-22133-KADIKOY', 280),
          tx(DateTime(2026, 6, 9), 'SOK-10419-USKUDAR', 190),
          tx(DateTime(2026, 6, 2), 'MIGROS TICARET AS', 640),
          tx(DateTime(2026, 6, 8), 'MIGROS TICARET AS', 410),
          tx(DateTime(2026, 6, 11), 'Kahve', 90),
        ];

    test('REGRESYON: gruplar İŞLEM SAYISINA değil TUTARA göre sıralanır', () {
      // Cihazda görülen: SPOR (4 işlem, 4.193 ₺) İNTERNET'in (5 işlem,
      // 2.607 ₺) altında duruyordu — gruplama motoru sayıya göre sıralıyor.
      final groups = ReportTopPayeesCard.buildGroups([
        for (var i = 0; i < 5; i++)
          tx(DateTime(2026, 8, 1 + i), 'INTERNET', 521.5),
        for (var i = 0; i < 4; i++)
          tx(DateTime(2026, 8, 10 + i), 'SPOR', 1048.25),
      ]);
      expect([for (final g in groups) g.label.toUpperCase()],
          ['SPOR', 'INTERNET']);
      expect(groups.first.total, closeTo(4193, 0.01));
    });

    test('maxRows kesimi seyrek ama BÜYÜK yeri listeden atmaz', () {
      final groups = ReportTopPayeesCard.buildGroups([
        // maxRows kadar sık ama küçük yer…
        for (var p = 0; p < ReportTopPayeesCard.maxRows; p++)
          for (var i = 0; i < 4; i++)
            tx(DateTime(2026, 8, 1 + i), 'KUCUK$p YER', 10),
        // …ve iki kez gidilmiş büyük yer.
        tx(DateTime(2026, 8, 20), 'MOBILYACI', 9000),
        tx(DateTime(2026, 8, 21), 'MOBILYACI', 6000),
      ]);
      expect(groups.first.label.toUpperCase(), 'MOBILYACI');
    });

    testWidgets('şube kodlu başlıklar TEK kaleme iner', (tester) async {
      await tester.pumpWidget(host(ReportTopPayeesCard(
        groups: ReportTopPayeesCard.buildGroups(statementLike()),
        onGroupTap: (_, __) {},
      )));
      await tester.pumpAndSettle();

      // "SOK-10419-USKUDAR" + "SOK-22133-KADIKOY" tek grup.
      expect(find.textContaining('SOK'), findsOneWidget);
      expect(find.text('3 işlem'), findsOneWidget);
      expect(find.text('790,00 ₺'), findsOneWidget);
    });

    testWidgets('tek seferlik başlık grup KURMAZ', (tester) async {
      await tester.pumpWidget(host(ReportTopPayeesCard(
        groups: ReportTopPayeesCard.buildGroups(statementLike()),
        onGroupTap: (_, __) {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('Kahve'), findsNothing);
    });

    testWidgets('gruba dokunmak işlemleri bildirir', (tester) async {
      String? label;
      List<TransactionEntity>? items;
      await tester.pumpWidget(host(ReportTopPayeesCard(
        groups: ReportTopPayeesCard.buildGroups(statementLike()),
        onGroupTap: (l, i) {
          label = l;
          items = i;
        },
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('MIGROS'));
      await tester.pumpAndSettle();
      expect(label, contains('MIGROS'));
      expect(items, hasLength(2));
    });

    testWidgets('grup yoksa kart HİÇ çizilmez', (tester) async {
      await tester.pumpWidget(host(ReportTopPayeesCard(
        groups: ReportTopPayeesCard.buildGroups(
            [tx(DateTime(2026, 6, 1), 'Tek', 100)]),
        onGroupTap: (_, __) {},
      )));
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Tek'), findsNothing);
    });
  });

  group('bütçe özeti', () {
    const statuses = [
      BudgetStatus(
          categoryId: 'market', label: 'Market', spent: 12000, limit: 9000),
      BudgetStatus(
          categoryId: 'kira', label: 'Kira', spent: 12000, limit: 20000),
      BudgetStatus(
          categoryId: 'yakit', label: 'Yakıt', spent: 980, limit: 1000),
      BudgetStatus(
          categoryId: 'giyim', label: 'Giyim', spent: 100, limit: 5000),
    ];

    testWidgets('kaç bütçeden kaçının aşıldığını yazar', (tester) async {
      await tester.pumpWidget(host(ReportBudgetSummaryCard(
        statuses: statuses,
        onTap: (_) {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('4 bütçeden 1 tanesi aşıldı'), findsOneWidget);
    });

    testWidgets('sıralama ORANA göre — limite en yakın önce', (tester) async {
      await tester.pumpWidget(host(ReportBudgetSummaryCard(
        statuses: statuses,
        onTap: (_) {},
      )));
      await tester.pumpAndSettle();

      // Market %133, Yakıt %98, Kira %60 → Giyim (%2) listeye girmez.
      expect(find.text('Market'), findsOneWidget);
      expect(find.text('Yakıt'), findsOneWidget);
      expect(find.text('Kira'), findsOneWidget);
      expect(find.text('Giyim'), findsNothing);
      expect(find.text('+1 bütçe daha'), findsOneWidget);

      final marketY = tester.getTopLeft(find.text('Market')).dy;
      final yakitY = tester.getTopLeft(find.text('Yakıt')).dy;
      final kiraY = tester.getTopLeft(find.text('Kira')).dy;
      expect(marketY, lessThan(yakitY));
      expect(yakitY, lessThan(kiraY));
    });

    testWidgets('hepsi limit içindeyse uyarı değil onay yazar', (tester) async {
      await tester.pumpWidget(host(ReportBudgetSummaryCard(
        statuses: const [
          BudgetStatus(categoryId: 'a', label: 'A', spent: 100, limit: 1000),
        ],
        onTap: (_) {},
      )));
      await tester.pumpAndSettle();
      expect(find.text('1 bütçenin hepsi limit içinde'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('bütçe yoksa kart çizilmez', (tester) async {
      await tester.pumpWidget(host(
        ReportBudgetSummaryCard(statuses: const [], onTap: (_) {}),
      ));
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('değişim rozeti', () {
    testWidgets('kuruş oynamaları GÖSTERİLMEZ', (tester) async {
      await tester.pumpWidget(host(const ReportChangeBadge(
        percent: 0.4,
        increaseIsGood: false,
      )));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('çok büyük değişim kısaltılır', (tester) async {
      await tester.pumpWidget(host(const ReportChangeBadge(
        percent: 29900,
        increaseIsGood: false,
      )));
      // "%29.900" satırın yarısını yiyordu.
      expect(find.text('%999+'), findsOneWidget);
    });

    testWidgets('kutupluluk tarafa göre — gelirde artış İYİ', (tester) async {
      await tester.pumpWidget(host(const Column(children: [
        ReportChangeBadge(percent: 30, increaseIsGood: true),
        ReportChangeBadge(percent: 30, increaseIsGood: false),
      ])));

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons, hasLength(2));
      expect(icons[0].color, MoneyColors.good);
      expect(icons[1].color, MoneyColors.bad);
      // Yön ikonu ikisinde de aynı: kutupluluğu renk DEĞİL taraf taşıyor.
      expect(icons[0].icon, Icons.arrow_upward_rounded);
      expect(icons[1].icon, Icons.arrow_upward_rounded);
    });

    testWidgets('kıyas yoksa hiçbir şey çizilmez', (tester) async {
      await tester.pumpWidget(host(const ReportChangeBadge(
        percent: null,
        increaseIsGood: false,
      )));
      expect(find.byType(Icon), findsNothing);
    });
  });
}
