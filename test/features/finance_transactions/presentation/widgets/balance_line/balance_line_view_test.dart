import 'dart:io';
import 'dart:ui' show SemanticsAction;

import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/transaction_filtering.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_series.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_view.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

import '../../../../../support/real_font.dart';

TransactionEntity _tx(String id, DateTime date, double amount,
        {String title = 'Kayıt',
        String tag = 'cat-market',
        bool income = false,
        int? no,
        int? count}) =>
    TransactionEntity(
      id: id,
      userId: 'u',
      walletId: 'w',
      title: title,
      tag: tag,
      amount: amount,
      date: date,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      installmentNo: no,
      installmentCount: count,
    );

void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  // Sabit "bugün": Perşembe 22 Ekim 2026.
  final now = DateTime(2026, 10, 22, 15);
  final period = DateTimeRange(
    start: DateTime(2026, 10, 16),
    end: DateTime(2026, 10, 31, 23, 59, 59),
  );

  final ledger = buildLedger(transactions: [
    _tx('maas', DateTime(2026, 10, 16, 9), 42000,
        title: 'Maaş', tag: 'cat-salary', income: true),
    _tx('a101', DateTime(2026, 10, 21, 11, 30), 238.5, title: 'A101'),
    _tx('simit', DateTime(2026, 10, 22, 9, 12), 45, title: 'Simit Sarayı'),
    _tx('migros', DateTime(2026, 10, 22, 13, 40), 612, title: 'Migros'),
    _tx('tel', DateTime(2026, 10, 22), 1250,
        title: 'Telefon', tag: 'cat-tech', no: 3, count: 6),
  ], currentBalance: 25745.90);

  BalanceLineSeries series({List<ForecastEvent> events = const []}) =>
      buildBalanceLineSeries(
        ledger: ledger,
        currentBalance: 25745.90,
        period: period,
        now: now,
        forecastPath: [
          for (var d = 22; d <= 31; d++)
            BalancePoint(
              day: DateTime(2026, 10, d),
              expected: 25745.90 - (d - 22) * 100,
              low: 25745.90 - (d - 22) * 160,
              high: 25745.90 - (d - 22) * 60,
            ),
        ],
        forecastEvents: events,
      );

  final netflix = ForecastEvent(
    date: DateTime(2026, 10, 23),
    amount: -229.99,
    walletId: 'w',
    kind: ForecastEventKind.recurringExpense,
    certainty: ForecastCertainty.known,
    title: 'Netflix',
    countsAsSpending: true,
  );

  DateTime? added;

  Future<void> pump(
    WidgetTester tester, {
    BalanceLineSeries? s,
    Size size = const Size(400, 1400),
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    added = null;
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AmountVisibilityCubit(),
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BalanceLineView(
                series: s ?? series(),
                ledger: ledger,
                currency: 'TRY',
                categoryLabels: const {
                  'cat-market': 'Market',
                  'cat-tech': 'Elektronik',
                  'cat-salary': 'Maaş',
                },
                categoryIcons: const {},
                onAddForDay: (d) => added = d,
                onShowList: () {},
                now: now,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('bugünle açılır: başlık, fişin kalemleri ve "ŞU AN"',
      (tester) async {
    await pump(tester);

    expect(find.text('BAKİYE · BUGÜN · 22 EKİM PERŞEMBE'), findsOneWidget);
    expect(find.text('GÜN FİŞİ'), findsOneWidget);
    expect(find.text('Simit Sarayı'), findsOneWidget);
    expect(find.text('Migros'), findsOneWidget);
    expect(find.text('Telefon'), findsOneWidget);
    expect(find.textContaining('TAKSİT 3/6'), findsOneWidget);
    expect(find.text('ŞU AN'), findsOneWidget);
    // Saatsiz (ekstreden) satırın saat sütunu boş kalır, "00:00" yazmaz.
    expect(find.text('00:00'), findsNothing);
  });

  testWidgets('‹ önceki güne geçer, fiş yenilenir', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('bl-prev')));
    await tester.pumpAndSettle();

    expect(find.text('BAKİYE · DÜN · 21 EKİM ÇARŞAMBA'), findsOneWidget);
    expect(find.text('A101'), findsOneWidget);
    expect(find.text('Migros'), findsNothing);
    expect(find.text('GÜN SONU'), findsOneWidget);
    // Bugün başka bir gün seçiliyken "Bugün" düğmesi çıkar ve geri döndürür.
    await tester.tap(find.byKey(const ValueKey('bl-today')));
    await tester.pumpAndSettle();
    expect(find.text('Migros'), findsOneWidget);
  });

  testWidgets('grafik ekran okuyucuda artır/azalt ile gezilir', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);

    final node = tester.getSemantics(find.byType(BalanceLineChart));
    expect(node.value, '22 Ekim Perşembe');
    node.owner!.performAction(node.id, SemanticsAction.increase);
    await tester.pumpAndSettle();

    expect(find.text('TAHMİNİ BAKİYE · YARIN · 23 EKİM CUMA'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('satıra dokununca ayrıntı fişin İÇİNDE açılır', (tester) async {
    await pump(tester);
    expect(find.text('Sonrası bakiye'), findsNothing);

    await tester.tap(find.text('Telefon'));
    await tester.pumpAndSettle();

    expect(find.text('Sonrası bakiye'), findsOneWidget);
    expect(find.text('Kalan taksit'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Bu dönem Elektronik'), findsOneWidget);
    expect(find.text('Ayrıntı ›'), findsOneWidget);

    // Başka satır açılınca önceki kapanır (tek açık satır).
    await tester.tap(find.text('Migros'));
    await tester.pumpAndSettle();
    expect(find.text('Kalan taksit'), findsNothing);
    expect(find.text('Bu dönem Market'), findsOneWidget);
  });

  testWidgets('kayıtsız geçmiş gün: "fiş yok" + o güne ekle', (tester) async {
    await pump(tester);
    // 22 → 20 (kayıtsız).
    await tester.tap(find.byKey(const ValueKey('bl-prev')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bl-prev')));
    await tester.pumpAndSettle();

    expect(find.text('BU GÜN FİŞ YOK'), findsOneWidget);
    expect(find.textContaining('Bu gün kayıt yok', findRichText: true),
        findsNothing,
        reason: 'ilk kayıttan (16 Eki) beri 4 gündür harcama yok → seri');
    expect(find.textContaining('gündür harcama yok', findRichText: true),
        findsOneWidget);

    await tester.tap(find.text('BU GÜNE EKLE'));
    expect(added, DateTime(2026, 10, 20));
  });

  testWidgets('gelecek gün: PLANLI damgası, plan satırı, tahmini bakiye',
      (tester) async {
    await pump(tester, s: series(events: [netflix]));
    await tester.tap(find.byKey(const ValueKey('bl-next')));
    await tester.pumpAndSettle();

    expect(find.text('PLANLI'), findsWidgets);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('PLAN'), findsOneWidget);
    expect(find.text('TAHMİNİ'), findsOneWidget);
    expect(find.text('BEKLENEN ÇIKIŞ'), findsOneWidget);
    expect(find.textContaining('aralık'), findsOneWidget);
  });

  testWidgets('tutarlar gizliyken fiş rakam göstermez', (tester) async {
    await pump(tester);
    final context = tester.element(find.byType(BalanceLineView));
    await context.read<AmountVisibilityCubit>().setVisibility(false);
    await tester.pumpAndSettle();

    expect(find.textContaining('612,00'), findsNothing);
    expect(find.textContaining('25.745,90'), findsNothing);
    expect(find.textContaining('****'), findsWidgets);
  });

  testWidgets('320×568 + yazı 1,3: taşma yok', (tester) async {
    await loadRealRoboto();
    for (final name in ['Regular', 'Bold']) {
      final bytes =
          File('assets/fonts/JetBrainsMono-$name.ttf').readAsBytesSync();
      await (FontLoader('JetBrainsMono')
            ..addFont(Future.value(ByteData.view(bytes.buffer))))
          .load();
    }
    await pump(tester, size: const Size(320, 568), textScale: 1.3);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Telefon'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Gelecek gün: aralık satırı (iki tutar) + PLANLI damgası.
    await tester.tap(find.byKey(const ValueKey('bl-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('aralık'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
