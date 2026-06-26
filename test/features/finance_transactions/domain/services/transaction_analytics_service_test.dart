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

  group('TransactionAnalyticsService.analyze', () {
    test('boş listede güvenli boş içgörü döner', () {
      final result = service.analyze([], rangeStart: start, rangeEnd: end);

      expect(result.isEmpty, true);
      expect(result.hasExpense, false);
      expect(result.totalExpense, 0);
      expect(result.dailyAverageExpense, 0);
      expect(result.topExpenseWeekday, isNull);
      expect(result.topExpenseCategory, isNull);
      expect(result.largestExpense, isNull);
      expect(result.savingsRate, 0);
    });

    test('toplamları, kategori/gün kırılımını ve en büyük gideri hesaplar', () {
      final txs = [
        _tx(title: 'Maaş', tag: 'Maaş', amount: 1000, date: DateTime(2026, 6, 1), type: TransactionTypeModel.income),
        _tx(title: 'Market', tag: 'Market', amount: 300, date: DateTime(2026, 6, 5)),
        // 06-12, 06-05 ile aynı haftanın günü (7 gün arayla).
        _tx(title: 'Market', tag: 'Market', amount: 300, date: DateTime(2026, 6, 12)),
        _tx(title: 'Kira', tag: 'Fatura', amount: 500, date: DateTime(2026, 6, 10)),
        // Aralık dışı — elenmel.
        _tx(title: 'Eski', tag: 'Market', amount: 9999, date: DateTime(2026, 5, 30)),
        _tx(title: 'Gelecek', tag: 'Market', amount: 9999, date: DateTime(2026, 7, 2)),
      ];

      final r = service.analyze(txs, rangeStart: start, rangeEnd: end);

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
    });

    test('birikim oranı = net / gelir (pozitif)', () {
      final txs = [
        _tx(title: 'Maaş', tag: 'Maaş', amount: 1000, date: DateTime(2026, 6, 3), type: TransactionTypeModel.income),
        _tx(title: 'Market', tag: 'Market', amount: 250, date: DateTime(2026, 6, 4)),
      ];

      final r = service.analyze(txs, rangeStart: start, rangeEnd: end);

      expect(r.net, 750);
      expect(r.savingsRate, closeTo(0.75, 1e-9));
    });
  });
}
