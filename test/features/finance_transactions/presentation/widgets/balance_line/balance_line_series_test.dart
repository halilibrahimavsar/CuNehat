import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/transaction_filtering.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_day_notes.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_series.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx(
  String id,
  DateTime date,
  double amount, {
  bool income = false,
  bool system = false,
  String title = 'Kayıt',
  String tag = 'cat-market',
}) =>
    TransactionEntity(
      id: id,
      userId: 'u',
      walletId: 'w',
      title: title,
      tag: system ? CashMovementTags.debtPayment : tag,
      amount: amount,
      date: date,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      isSystem: system,
    );

void main() {
  // Sabit "bugün": tarihe bağlı testler takvim ilerledikçe kendiliğinden
  // kırılıyordu (bkz. gün şeridi testleri).
  final now = DateTime(2026, 10, 22, 15);
  final period = DateTimeRange(
    start: DateTime(2026, 10, 1),
    end: DateTime(2026, 10, 31, 23, 59, 59),
  );

  group('buildBalanceLineSeries', () {
    test('dönemin HER günü vardır; kayıtsız gün önceki bakiyeyi taşır', () {
      final ledger = buildLedger(transactions: [
        _tx('a', DateTime(2026, 9, 28, 10), 100), // dönem öncesi
        _tx('b', DateTime(2026, 10, 5, 10), 200),
        _tx('c', DateTime(2026, 10, 20, 10), 50),
      ], currentBalance: 1000);

      final s = buildBalanceLineSeries(
        estimates: true,
        ledger: ledger,
        currentBalance: 1000,
        period: period,
        now: now,
      );

      expect(s.days, hasLength(31));
      expect(s.todayIndex, 21);
      // 1000 = bugünkü bakiye → c öncesi 1050 → b öncesi 1250.
      expect(s.days[0].balance, 1250,
          reason: 'açılış = dönem öncesi son kayıt');
      expect(s.days[3].balance, 1250);
      expect(s.days[4].balance, 1050, reason: '5 Eki: −200');
      expect(s.days[18].balance, 1050);
      expect(s.days[19].balance, 1000);
      expect(s.days[21].balance, 1000, reason: 'bugün');
      expect(s.days[4].expense, 200);
      expect(s.days[4].items.single.transaction.id, 'b');
    });

    test('dönemden önce kayıt yoksa açılış en eski kaydın ÖNCESİDİR', () {
      final ledger = buildLedger(transactions: [
        _tx('a', DateTime(2026, 10, 10, 10), 300, income: true),
      ], currentBalance: 500);

      final s = buildBalanceLineSeries(
          estimates: true,
          ledger: ledger,
          currentBalance: 500,
          period: period,
          now: now);

      expect(s.days[0].balance, 200);
      expect(s.days[9].balance, 500);
      expect(s.days[9].income, 300);
    });

    test('gün içi satırlar ESKİDEN YENİYE dizilir (fiş akışı)', () {
      final ledger = buildLedger(transactions: [
        _tx('sabah', DateTime(2026, 10, 7, 9), 10),
        _tx('aksam', DateTime(2026, 10, 7, 20), 20),
      ], currentBalance: 100);

      final day = buildBalanceLineSeries(
              estimates: true,
              ledger: ledger,
              currentBalance: 100,
              period: period,
              now: now)
          .days[6];

      expect(day.items.map((e) => e.transaction.id), ['sabah', 'aksam']);
      expect(day.balance, 100, reason: 'gün sonu = en yeni satırdan sonrası');
    });

    test('para taşıma gider sayılmaz, moved\'da işaretli durur', () {
      final ledger = buildLedger(transactions: [
        _tx('t', DateTime(2026, 10, 8, 9), 400, system: true),
        _tx('m', DateTime(2026, 10, 8, 10), 60),
      ], currentBalance: 1000);

      final day = buildBalanceLineSeries(
              estimates: true,
              ledger: ledger,
              currentBalance: 1000,
              period: period,
              now: now)
          .days[7];

      expect(day.expense, 60);
      expect(day.moved, -400);
    });

    // QA D1: aynı gün +0,1 +0,2 −0,3 taşıma kayan noktada 5,55e-17 kalır;
    // "PARA TAŞIMA 0,00" satırı çizilir, oysa eşit giriş/çıkışta not hiç
    // çıkmıyordu. Zincir de kuruş artığı biriktiriyordu.
    test(
        'kuruş altı taşıma artığı taşıma TOPLAMI değildir ama günde taşıma '
        'satırı varsa not çıkar; zincir kuruşta tam', () {
      final ledger = buildLedger(transactions: [
        _tx('a', DateTime(2026, 10, 20, 9), 0.1, income: true, system: true),
        _tx('b', DateTime(2026, 10, 20, 10), 0.2, income: true, system: true),
        _tx('c', DateTime(2026, 10, 20, 11), 0.3, system: true),
        for (var i = 0; i < 40; i++)
          _tx('x$i', DateTime(2026, 9, 1 + i % 28, 12, i), 7.49),
      ], currentBalance: 1000);

      for (final e in ledger) {
        expect(e.balanceAfter, roundToCents(e.balanceAfter),
            reason: e.transaction.id);
      }
      final day = buildBalanceLineSeries(
              estimates: true,
              ledger: ledger,
              currentBalance: 1000,
              period: period,
              now: now)
          .days[19];
      expect(day.moved.abs() < 0.005, isTrue);
      expect(
          buildDayNotes(
                  day: day,
                  dailyExpense: const {},
                  firstRecord: DateTime(2026, 9, 1))
              .whereType<MovedNote>(),
          hasLength(1));
    });

    test('gelecek günler TAHMİNDEN gelir; ileri tarihli satır defterden düşmez',
        () {
      final ledger = buildLedger(transactions: [
        _tx('taksit', DateTime(2026, 10, 25, 9), 90),
        _tx('bugun', DateTime(2026, 10, 22, 9), 10),
      ], currentBalance: 900);

      final s = buildBalanceLineSeries(
        estimates: true,
        ledger: ledger,
        currentBalance: 900,
        period: period,
        now: now,
        forecastPath: [
          BalancePoint(
              day: DateTime(2026, 10, 25), expected: 900, low: 850, high: 950),
        ],
        forecastEvents: [
          ForecastEvent(
            date: DateTime(2026, 10, 25),
            amount: -90,
            walletId: 'w',
            kind: ForecastEventKind.scheduled,
            certainty: ForecastCertainty.known,
            title: 'taksit',
            countsAsSpending: true,
          ),
        ],
      );

      // Bugünün sonu: ileri tarihli taksit HENÜZ düşmedi.
      expect(s.days[21].balance, 990);
      final d25 = s.days[24];
      expect(d25.isFuture, isTrue);
      expect(d25.items, isEmpty, reason: 'taksit iki kez görünmesin');
      expect(d25.events, hasLength(1));
      expect(d25.balance, 900);
      expect((d25.low, d25.high), (850, 950));
      expect(d25.expense, 90);
      expect(s.days[23].balance, isNull,
          reason: 'tahmini olmayan gelecek gün uydurulmaz');
    });

    // QA O1: elle girilmiş ileri tarihli gelir fişte GELİR'dir, para
    // taşıma değil.
    test('ileri tarihli gelir gelecekte gelir sayılır, taşıma değil', () {
      final s = buildBalanceLineSeries(
        estimates: false,
        ledger: buildLedger(transactions: const [], currentBalance: 900),
        currentBalance: 900,
        period: period,
        now: now,
        forecastPath: [
          BalancePoint(
              day: DateTime(2026, 10, 25),
              expected: 30900,
              low: 30900,
              high: 30900),
        ],
        forecastEvents: [
          ForecastEvent(
            date: DateTime(2026, 10, 25),
            amount: 30000,
            walletId: 'w',
            kind: ForecastEventKind.scheduled,
            certainty: ForecastCertainty.known,
            title: 'Maaş',
            countsAsIncome: true,
          ),
        ],
      );
      final d25 = s.days[24];
      expect(d25.income, 30000);
      expect(d25.moved, 0);
    });

    test('geçmiş dönemde bugün yok; açılış seçimi son gün', () {
      final s = buildBalanceLineSeries(
        estimates: true,
        ledger: const [],
        currentBalance: 0,
        period: DateTimeRange(
            start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)),
        now: now,
      );
      expect(s.todayIndex, -1);
      expect(s.initialIndex, 29);
      expect(s.valueRange, (0.0, 0.0));
    });
  });

  group('buildDayNotes', () {
    BalanceDay dayOf(BalanceLineSeries s, int d) => s.days[d - 1];

    test('ortalamanın üstünde harcama yüzdeyle söylenir', () {
      final txs = [
        // İlk kayıt pencereden (22 Eyl – 19 Eki) önce: pencere tam 28 gün.
        _tx('ilk', DateTime(2026, 9, 1, 9), 70),
        // Önceki 28 gün: 4 harcamalı gün × 70 = 280 → günlük ort. 10.
        for (final d in [2, 5, 9, 14]) _tx('p$d', DateTime(2026, 10, d, 9), 70),
        _tx('x', DateTime(2026, 10, 20, 9), 15),
      ];
      final ledger = buildLedger(transactions: txs, currentBalance: 1000);
      final s = buildBalanceLineSeries(
          estimates: true,
          ledger: ledger,
          currentBalance: 1000,
          period: period,
          now: now);

      final notes = buildDayNotes(
        day: dayOf(s, 20),
        dailyExpense: dailyExpenseOf(ledger),
        firstRecord: DateTime(2026, 9, 1),
      );
      expect(notes.whereType<PaceNote>().single.percent, 50);
    });

    // QA D3: bugün yarım bir gündür; sabah "ortalamanın %70 altında" demek
    // anlamsız. Bugün için yalnız ortalamanın belirgin ÜSTÜ söylenir.
    test('bugün için yalnız ortalamanın üstü söylenir; geçmiş gün değişmez',
        () {
      List<DayNote> notesFor(double todaySpend, {int day = 22}) {
        final txs = [
          _tx('ilk', DateTime(2026, 9, 1, 9), 70),
          for (final d in [2, 5, 9, 14])
            _tx('p$d', DateTime(2026, 10, d, 9), 70),
          _tx('x', DateTime(2026, 10, day, 9), todaySpend),
        ];
        final ledger = buildLedger(transactions: txs, currentBalance: 1000);
        final s = buildBalanceLineSeries(
            estimates: true,
            ledger: ledger,
            currentBalance: 1000,
            period: period,
            now: now);
        return buildDayNotes(
          day: dayOf(s, day),
          dailyExpense: dailyExpenseOf(ledger),
          firstRecord: DateTime(2026, 9, 1),
        );
      }

      // Bugün (22 Eki), ortalama 10: 3 harcandı → not yok.
      expect(notesFor(3).whereType<PaceNote>(), isEmpty);
      // Bugün 15 → %50 üstünde: söylenir.
      expect(notesFor(15).whereType<PaceNote>().single.percent, 50);
      // Geçmiş gün (20 Eki) 3 → %70 altında: eskisi gibi söylenir.
      expect(notesFor(3, day: 20).whereType<PaceNote>().single.percent, -70);
    });

    test('kısa geçmişte ortalama ilk kayıttan beri hesaplanır, 28 güne değil',
        () {
      // 5 günlük cüzdan, her gün 100. 28'e bölünseydi ortalama ~18 olur ve
      // sıradan bir 100'lük gün "%460 üstünde" çıkardı.
      final ledger = buildLedger(transactions: [
        for (final d in [15, 16, 17, 18, 19])
          _tx('p$d', DateTime(2026, 10, d, 9), 100),
        _tx('x', DateTime(2026, 10, 20, 9), 100),
      ], currentBalance: 1000);
      final s = buildBalanceLineSeries(
          estimates: true,
          ledger: ledger,
          currentBalance: 1000,
          period: period,
          now: now);

      final notes = buildDayNotes(
        day: dayOf(s, 20),
        dailyExpense: dailyExpenseOf(ledger),
        firstRecord: DateTime(2026, 10, 15),
      );
      final pace = notes.whereType<PaceNote>().single;
      expect(pace.percent, 0);
      expect(pace.isNear, isTrue);
    });

    test('taban çizgisi zayıfsa (3 günden az harcama) yüzde söylenmez', () {
      final ledger = buildLedger(transactions: [
        _tx('p', DateTime(2026, 10, 2, 9), 70),
        _tx('x', DateTime(2026, 10, 20, 9), 15),
      ], currentBalance: 1000);
      final s = buildBalanceLineSeries(
          estimates: true,
          ledger: ledger,
          currentBalance: 1000,
          period: period,
          now: now);

      final notes = buildDayNotes(
        day: dayOf(s, 20),
        dailyExpense: dailyExpenseOf(ledger),
        firstRecord: DateTime(2026, 10, 2),
      );
      expect(notes.whereType<PaceNote>(), isEmpty);
    });

    test('harcamasız seri ilk kayıttan GERİYE sayılmaz', () {
      final ledger = buildLedger(transactions: [
        _tx('ilk', DateTime(2026, 10, 10, 9), 5),
      ], currentBalance: 100);
      final s = buildBalanceLineSeries(
          estimates: true,
          ledger: ledger,
          currentBalance: 100,
          period: period,
          now: now);
      final daily = dailyExpenseOf(ledger);

      final onFirst = buildDayNotes(
          day: dayOf(s, 9),
          dailyExpense: daily,
          firstRecord: DateTime(2026, 10, 10));
      expect(onFirst, [isA<NoRecordsNote>()],
          reason: 'kurulumdan önceki gün "seri" değil');

      final later = buildDayNotes(
          day: dayOf(s, 14),
          dailyExpense: daily,
          firstRecord: DateTime(2026, 10, 10));
      expect(later.whereType<StreakNote>().single.days, 4);
    });

    test('gelirli günde gelir notu, en büyük kalem notu YOK', () {
      final ledger = buildLedger(transactions: [
        _tx('maas', DateTime(2026, 10, 16, 9), 42000,
            income: true, title: 'Maaş'),
        _tx('a', DateTime(2026, 10, 16, 10), 600, title: 'Migros'),
        _tx('b', DateTime(2026, 10, 16, 11), 95, title: 'Kahve'),
        _tx('t', DateTime(2026, 10, 16, 12), 100, system: true),
      ], currentBalance: 50000);
      final s = buildBalanceLineSeries(
          estimates: true,
          ledger: ledger,
          currentBalance: 50000,
          period: period,
          now: now);

      final notes = buildDayNotes(
          day: dayOf(s, 16),
          dailyExpense: dailyExpenseOf(ledger),
          firstRecord: DateTime(2026, 10, 16));
      expect(notes.whereType<IncomeDayNote>().single.title, 'Maaş');
      expect(notes.whereType<MovedNote>(), hasLength(1));
      expect(notes.whereType<BiggestNote>(), isEmpty);
    });

    test('gelirsiz günde birden çok giderin en büyüğü söylenir', () {
      final ledger = buildLedger(transactions: [
        _tx('a', DateTime(2026, 10, 17, 10), 238.5, title: 'A101'),
        _tx('b', DateTime(2026, 10, 17, 11), 410, title: 'Yemek siparişi'),
      ], currentBalance: 1000);
      final s = buildBalanceLineSeries(
          estimates: true,
          ledger: ledger,
          currentBalance: 1000,
          period: period,
          now: now);

      final notes = buildDayNotes(
          day: dayOf(s, 17),
          dailyExpense: dailyExpenseOf(ledger),
          firstRecord: DateTime(2026, 10, 17));
      expect(notes.whereType<BiggestNote>().single.title, 'Yemek siparişi');
    });

    test('gelecek gün yalnız bekleyen hareket sayısını söyler', () {
      final s = buildBalanceLineSeries(
          estimates: true,
          ledger: const [],
          currentBalance: 0,
          period: period,
          now: now);
      final notes = buildDayNotes(
          day: dayOf(s, 30), dailyExpense: const {}, firstRecord: null);
      expect(notes, [isA<FutureNote>()]);
      expect((notes.single as FutureNote).count, 0);
    });
  });

  group('plan / tahmin', () {
    final today = DateTime(2026, 10, 22);
    final path = [
      BalancePoint(
          day: today,
          expected: 880,
          low: 870,
          high: 890,
          planned: 900,
          paceSpend: 20),
      BalancePoint(
          day: DateTime(2026, 10, 23),
          expected: 850,
          low: 830,
          high: 870,
          planned: 900,
          paceSpend: 30),
      BalancePoint(
          day: DateTime(2026, 10, 24),
          expected: 820,
          low: 790,
          high: 850,
          planned: 900,
          paceSpend: 30),
      BalancePoint(
          day: DateTime(2026, 10, 25),
          expected: 220,
          low: 150,
          high: 450,
          planned: 500,
          paceSpend: 50),
      BalancePoint(
          day: DateTime(2026, 10, 26),
          expected: 100,
          low: 20,
          high: 330,
          planned: 500,
          paceSpend: 50),
    ];
    final events = [
      ForecastEvent(
        date: DateTime(2026, 10, 25),
        amount: -100,
        walletId: 'w',
        kind: ForecastEventKind.recurringExpense,
        certainty: ForecastCertainty.known,
        title: 'Netflix',
        countsAsSpending: true,
      ),
      // Kesilmemiş ekstre: 300 kesin (harcandı), 200 hızdan.
      ForecastEvent(
        date: DateTime(2026, 10, 25),
        amount: -500,
        walletId: 'w',
        kind: ForecastEventKind.cardStatementEstimate,
        certainty: ForecastCertainty.expected,
        title: 'Bonus',
        knownAmount: -300,
      ),
      ForecastEvent(
        date: DateTime(2026, 10, 25),
        amount: 200,
        pathMin: 0,
        pathExpected: 0,
        pathMax: 200,
        walletId: 'w',
        kind: ForecastEventKind.receivable,
        certainty: ForecastCertainty.expected,
        title: 'Ali',
      ),
      // Kesin kısmı OLMAYAN ekstre tahmini.
      ForecastEvent(
        date: DateTime(2026, 10, 26),
        amount: -70,
        walletId: 'w',
        kind: ForecastEventKind.cardStatementEstimate,
        certainty: ForecastCertainty.expected,
        title: 'Axess',
        knownAmount: 0,
      ),
    ];
    final ledger = buildLedger(transactions: [
      _tx('a', DateTime(2026, 10, 20, 10), 100),
    ], currentBalance: 900);

    BalanceLineSeries build(bool estimates) => buildBalanceLineSeries(
          estimates: estimates,
          ledger: ledger,
          currentBalance: 900,
          period: period,
          now: now,
          forecastPath: path,
          forecastEvents: events,
        );

    test('PLAN: bakiye yalnız kesin kalemler, bant yok, hız payı yok', () {
      final s = build(false);
      expect(s.estimates, isFalse);
      final d25 = s.days[24];
      expect(d25.balance, 500);
      expect(d25.planned, 500);
      expect((d25.low, d25.high), (null, null));
      expect(d25.estimatedSpend, 0);
      // Alacak bilgi olarak kalır ama toplamlara girmez; ekstre kesin
      // kısmıyla.
      expect(d25.events.map((e) => e.title), ['Netflix', 'Bonus', 'Ali']);
      expect(d25.expense, 100);
      expect(d25.moved, -300);
      expect(d25.income, 0);
      // Yalnız tahmini olan ekstre plan gününde yok.
      expect(s.days[25].events, isEmpty);
    });

    test('TAHMİN: beklenen yol + bant + günün hız payı', () {
      final s = build(true);
      expect(s.estimates, isTrue);
      final d25 = s.days[24];
      expect(d25.balance, 220);
      expect(d25.planned, 500);
      expect((d25.low, d25.high), (150, 450));
      expect(d25.estimatedSpend, 50);
      expect(d25.moved, -500);
      expect(s.days[25].events.single.title, 'Axess');
      // İlk gelecek gün bugünün kalan hız payını da taşır.
      expect(s.days[22].estimatedSpend, 30 + 20);
    });

    test(
        'bugün vadeli, kaydedilmemiş kalem YARININ fişine taşınır: '
        'bugün + giriş − çıkış = yarının gün sonu (iki modda)', () {
      // Gün başı 1.000; bugün vadeli 200 kira yolun bugününde düşer.
      final today = DateTime(2026, 10, 22);
      final tomorrow = DateTime(2026, 10, 23);
      final rent = ForecastEvent(
        date: today,
        amount: -200,
        walletId: 'w',
        kind: ForecastEventKind.recurringExpense,
        certainty: ForecastCertainty.known,
        title: 'Kira',
        countsAsSpending: true,
      );
      for (final estimates in [false, true]) {
        final s = buildBalanceLineSeries(
          estimates: estimates,
          ledger: const [],
          currentBalance: 1000,
          period: DateTimeRange(start: today, end: DateTime(2026, 10, 24)),
          now: now,
          forecastPath: [
            BalancePoint(
                day: today,
                expected: 770,
                low: 770,
                high: 770,
                planned: 800,
                paceSpend: 30),
            BalancePoint(
                day: tomorrow,
                expected: 720,
                low: 700,
                high: 740,
                planned: 800,
                paceSpend: 50),
          ],
          forecastEvents: [rent],
        );
        final t = s.days[0], m = s.days[1];
        expect(t.balance, 1000, reason: 'bugün defterden');
        expect(m.events.single.title, 'Kira');
        expect(m.expense, 200);
        expect(t.balance! - m.expense - m.estimatedSpend, m.balance,
            reason: 'estimates=$estimates');
      }
    });

    test('ölçek planlı çizgiyi de kapsar', () {
      final (lo, hi) = build(true).valueRange!;
      expect(lo, lessThanOrEqualTo(20));
      expect(hi, greaterThanOrEqualTo(1000));
    });

    test('gelecek notu moda göre', () {
      final s = build(false);
      final plan = buildDayNotes(
          day: s.days[24], dailyExpense: const {}, firstRecord: null);
      expect((plan.single as FutureNote).estimates, isFalse);
      final est = buildDayNotes(
          day: s.days[24],
          dailyExpense: const {},
          firstRecord: null,
          estimates: true);
      expect((est.single as FutureNote).estimates, isTrue);
    });
  });
}
