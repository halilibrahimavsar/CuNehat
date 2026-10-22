import 'package:cunehat/core/services/wallet_metrics_service.dart';
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
          ledger: ledger, currentBalance: 500, period: period, now: now);

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
              ledger: ledger, currentBalance: 100, period: period, now: now)
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
              ledger: ledger, currentBalance: 1000, period: period, now: now)
          .days[7];

      expect(day.expense, 60);
      expect(day.moved, -400);
    });

    test('gelecek günler TAHMİNDEN gelir; ileri tarihli satır defterden düşmez',
        () {
      final ledger = buildLedger(transactions: [
        _tx('taksit', DateTime(2026, 10, 25, 9), 90),
        _tx('bugun', DateTime(2026, 10, 22, 9), 10),
      ], currentBalance: 900);

      final s = buildBalanceLineSeries(
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

    test('geçmiş dönemde bugün yok; açılış seçimi son gün', () {
      final s = buildBalanceLineSeries(
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
          ledger: ledger, currentBalance: 1000, period: period, now: now);

      final notes = buildDayNotes(
        day: dayOf(s, 20),
        dailyExpense: dailyExpenseOf(ledger),
        firstRecord: DateTime(2026, 9, 1),
      );
      expect(notes.whereType<PaceNote>().single.percent, 50);
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
          ledger: ledger, currentBalance: 1000, period: period, now: now);

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
          ledger: ledger, currentBalance: 1000, period: period, now: now);

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
          ledger: ledger, currentBalance: 100, period: period, now: now);
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
          ledger: ledger, currentBalance: 50000, period: period, now: now);

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
          ledger: ledger, currentBalance: 1000, period: period, now: now);

      final notes = buildDayNotes(
          day: dayOf(s, 17),
          dailyExpense: dailyExpenseOf(ledger),
          firstRecord: DateTime(2026, 10, 17));
      expect(notes.whereType<BiggestNote>().single.title, 'Yemek siparişi');
    });

    test('gelecek gün yalnız bekleyen hareket sayısını söyler', () {
      final s = buildBalanceLineSeries(
          ledger: const [], currentBalance: 0, period: period, now: now);
      final notes = buildDayNotes(
          day: dayOf(s, 30), dailyExpense: const {}, firstRecord: null);
      expect(notes, [isA<FutureNote>()]);
      expect((notes.single as FutureNote).count, 0);
    });
  });
}
