import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx({
  String title = 'T',
  String tag = 'Genel',
  double amount = 100,
  required DateTime date,
  TransactionTypeModel type = TransactionTypeModel.expense,
  bool isSystem = false,
}) {
  return TransactionEntity(
    id: 'id-${date.microsecondsSinceEpoch}-$amount',
    userId: 'u',
    walletId: 'w',
    title: title,
    tag: tag,
    amount: amount,
    date: date,
    type: type,
    isSystem: isSystem,
  );
}

void main() {
  const service = TransactionAnalyticsService();
  final start = DateTime(2026, 6, 1);
  final end = DateTime(2026, 6, 30);
  final currentDate = DateTime(2026, 6, 15);

  group('TransactionAnalyticsService.analyze', () {
    test('boş listede güvenli boş içgörü döner', () {
      final result = service.analyze(
        [],
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(result.isEmpty, true);
      expect(result.hasExpense, false);
      expect(result.totalExpense, 0);
      expect(result.dailyAverageExpense, 0);
      expect(result.topExpenseWeekday, isNull);
      expect(result.topExpenseCategory, isNull);
      expect(result.largestExpense, isNull);
      expect(result.savingsRate, 0);
      expect(result.dailySafeToSpend, isNull);
      expect(result.categorySpike, isNull);
    });

    test('toplamları, kategori/gün kırılımını ve en büyük gideri hesaplar', () {
      final txs = [
        _tx(
            title: 'Maaş',
            tag: 'Maaş',
            amount: 1000,
            date: DateTime(2026, 6, 1),
            type: TransactionTypeModel.income),
        _tx(
            title: 'Market',
            tag: 'Market',
            amount: 300,
            date: DateTime(2026, 6, 5)),
        // 06-12, 06-05 ile aynı haftanın günü (7 gün arayla).
        _tx(
            title: 'Market',
            tag: 'Market',
            amount: 300,
            date: DateTime(2026, 6, 12)),
        _tx(
            title: 'Kira',
            tag: 'Fatura',
            amount: 500,
            date: DateTime(2026, 6, 10)),
        // Aralık dışı — elenmeli.
        _tx(
            title: 'Eski',
            tag: 'Kirasız',
            amount: 9999,
            date: DateTime(2026, 5, 30)),
        _tx(
            title: 'Gelecek',
            tag: 'Kirasız',
            amount: 9999,
            date: DateTime(2026, 7, 2)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      // Aralık dışındaki iki kayıt hiçbir toplama girmez.
      expect(r.transactionCount, 4);
      expect(r.totalIncome, 1000);
      expect(r.totalExpense, 1100);
      expect(r.net, -100);
      expect(r.dailyAverageExpense, closeTo(1100 / 30, 1e-9));

      // Market 600 > Fatura 500.
      expect(r.topExpenseCategory, 'Market');
      expect(r.topExpenseCategoryAmount, 600);

      // İki Market günü aynı haftanın günü → o gün toplamı 600 ile zirvede.
      expect(r.topExpenseWeekday, DateTime(2026, 6, 5).weekday);
      expect(r.topExpenseWeekdayAmount, 600);

      // En büyük tek gider: Kira 500.
      expect(r.largestExpense?.title, 'Kira');
      expect(r.largestExpense?.amount, 500);

      expect(r.savingsRate, closeTo(-0.1, 1e-9));
      // Net -100 olduğu için safe to spend null olmalı.
      expect(r.dailySafeToSpend, isNull);
    });

    test('birikim oranı = net / gelir (pozitif)', () {
      final txs = [
        _tx(
            title: 'Maaş',
            tag: 'Maaş',
            amount: 1000,
            date: DateTime(2026, 6, 3),
            type: TransactionTypeModel.income),
        _tx(
            title: 'Market',
            tag: 'Market',
            amount: 250,
            date: DateTime(2026, 6, 4)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(r.net, 750);
      expect(r.savingsRate, closeTo(0.75, 1e-9));
    });

    test('pozitif bakiye durumunda dailySafeToSpend doğru hesaplanır', () {
      final txs = [
        _tx(
            title: 'Maaş',
            tag: 'Maaş',
            amount: 4000,
            date: DateTime(2026, 6, 1),
            type: TransactionTypeModel.income),
        _tx(
            title: 'Market',
            tag: 'Market',
            amount: 1000,
            date: DateTime(2026, 6, 5)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride:
            currentDate, // 15 Haziran -> kalan gün sayısı = 30-15+1 = 16 gün
      );

      expect(r.net, 3000);
      expect(r.remainingDays, 16);
      expect(r.dailySafeToSpend, 3000 / 16);
    });

    test('geçen döneme göre sıçrama yapan kategoriyi doğru tespit eder', () {
      final txs = [
        // Geçen dönem (Mayıs): Market = 200 TL
        _tx(
            title: 'Market Eski',
            tag: 'Market',
            amount: 200,
            date: DateTime(2026, 5, 10)),
        // Bu dönem (Haziran): Market = 500 TL (%150 artış)
        _tx(
            title: 'Market Yeni',
            tag: 'Market',
            amount: 500,
            date: DateTime(2026, 6, 10)),
      ];

      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
      );

      expect(r.categorySpike, isNotNull);
      expect(r.categorySpike?.categoryName, 'Market');
      expect(r.categorySpike?.currentAmount, 500);
      expect(r.categorySpike?.previousAmount, 200);
      expect(r.categorySpike?.percentIncrease, 150);
    });

    test('sıçrama alt eşiği çağıran tarafından yükseltilebilir', () {
      final txs = [
        _tx(
            title: 'Kahve Eski',
            tag: 'Kahve',
            amount: 40,
            date: DateTime(2026, 5, 10)),
        _tx(
            title: 'Kahve Yeni',
            tag: 'Kahve',
            amount: 90,
            date: DateTime(2026, 6, 10)),
      ];

      // Varsayılan eşik (50) altında kaldığı için değil, üstünde olduğu için
      // yakalanır; eşik yükseltilince aynı sıçrama elenir.
      expect(
        service
            .analyze(txs,
                rangeStart: start,
                rangeEnd: end,
                currentDateOverride: currentDate)
            .categorySpike,
        isNotNull,
      );
      expect(
        service
            .analyze(txs,
                rangeStart: start,
                rangeEnd: end,
                currentDateOverride: currentDate,
                spikeMinimumAmount: 500)
            .categorySpike,
        isNull,
      );
    });
  });

  group('dailySafeToSpend yalnız ileriye dönük pencerede üretilir', () {
    final txs = [
      _tx(
          title: 'Maaş',
          tag: 'Maaş',
          amount: 4000,
          date: DateTime(2026, 6, 1),
          type: TransactionTypeModel.income),
      _tx(
          title: 'Market',
          tag: 'Market',
          amount: 1000,
          date: DateTime(2026, 6, 5)),
    ];

    test('tamamı geçmişte kalan aralıkta ("Geçen Ay") hedef üretilmez', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: DateTime(2026, 7, 27),
      );

      expect(r.net, 3000);
      expect(r.remainingDays, 0);
      // Aksi halde dönemin tüm neti "bugünkü günlük limit" gibi görünürdü.
      expect(r.dailySafeToSpend, isNull);
    });

    test('bugün biten aralıkta ("Son 7 Gün") hedef üretilmez', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: end,
      );

      expect(r.remainingDays, 0);
      expect(r.dailySafeToSpend, isNull);
    });

    test('aralık gelecekteyse tüm pencere kalan gün sayılır', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: DateTime(2026, 5, 20),
      );

      expect(r.remainingDays, 30);
      expect(r.dailySafeToSpend, 3000 / 30);
    });

    test('bütçe döneminin son gününde ("Bu Ay", 30 Haziran) hedef üretilir',
        () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: end,
        rangeIsBudgetPeriod: true,
      );

      // Dönemin son günü: kalan net bugün harcanabilir.
      expect(r.remainingDays, 1);
      expect(r.dailySafeToSpend, 3000);
    });

    test('bütçe dönemi bayrağı geçmişte biten aralığı diriltmez', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: DateTime(2026, 7, 27),
        rangeIsBudgetPeriod: true,
      );

      expect(r.remainingDays, 0);
      expect(r.dailySafeToSpend, isNull);
    });

    test('bütçe dönemi bayrağı dönem ortasındaki hesabı değiştirmez', () {
      final r = service.analyze(
        txs,
        rangeStart: start,
        rangeEnd: end,
        currentDateOverride: currentDate,
        rangeIsBudgetPeriod: true,
      );

      expect(r.remainingDays, 16);
      expect(r.dailySafeToSpend, 3000 / 16);
    });
  });
}
