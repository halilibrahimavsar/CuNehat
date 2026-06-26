import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/daily_spending_summary_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DailySpendingSummaryService();

  TransactionEntity tx(
    DateTime date,
    double amount,
    TransactionTypeModel type,
  ) =>
      TransactionEntity(
        id: null,
        userId: 'u',
        walletId: 'w',
        title: 't',
        tag: 'cat',
        amount: amount,
        date: date,
        type: type,
      );

  group('DailySpendingSummaryService.buildDailySummaries', () {
    test('boş liste boş harita döndürür', () {
      expect(service.buildDailySummaries([]), isEmpty);
    });

    test('tek gider günü: net negatif, count 1', () {
      final result = service.buildDailySummaries([
        tx(DateTime(2026, 6, 26, 14, 30), 150, TransactionTypeModel.expense),
      ]);

      expect(result, hasLength(1));
      final s = result[DateTime(2026, 6, 26)]!;
      expect(s.income, 0);
      expect(s.expense, 150);
      expect(s.count, 1);
      expect(s.net, -150);
      expect(s.hasExpense, isTrue);
    });

    test('aynı günde gelir + gider doğru toplanır, net ve count', () {
      final result = service.buildDailySummaries([
        tx(DateTime(2026, 6, 26, 9), 500, TransactionTypeModel.income),
        tx(DateTime(2026, 6, 26, 18), 200, TransactionTypeModel.expense),
      ]);

      expect(result, hasLength(1));
      final s = result[DateTime(2026, 6, 26)]!;
      expect(s.income, 500);
      expect(s.expense, 200);
      expect(s.count, 2);
      expect(s.net, 300);
    });

    test('saat bileşeni atılır: aynı günün farklı saatleri tek anahtar', () {
      final result = service.buildDailySummaries([
        tx(DateTime(2026, 6, 26, 0, 1), 10, TransactionTypeModel.expense),
        tx(DateTime(2026, 6, 26, 23, 59), 20, TransactionTypeModel.expense),
      ]);

      expect(result, hasLength(1));
      expect(result[DateTime(2026, 6, 26)]!.expense, 30);
      expect(result[DateTime(2026, 6, 26)]!.count, 2);
    });

    test('farklı günler ayrı anahtarlara gider', () {
      final result = service.buildDailySummaries([
        tx(DateTime(2026, 6, 25), 10, TransactionTypeModel.expense),
        tx(DateTime(2026, 6, 26), 20, TransactionTypeModel.income),
      ]);

      expect(result, hasLength(2));
      expect(result[DateTime(2026, 6, 25)]!.expense, 10);
      expect(result[DateTime(2026, 6, 26)]!.income, 20);
    });
  });
}
