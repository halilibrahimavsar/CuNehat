import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx({
  required double amount,
  required bool income,
  required DateTime date,
}) =>
    TransactionEntity(
      id: date.toIso8601String(),
      userId: 'u',
      walletId: 'w',
      title: 't',
      tag: 'g',
      amount: amount,
      date: date,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );

void main() {
  group('calculateRunningBalance', () {
    test('en yeni işlem güncel (final) bakiyeyi gösterir, geri çözülür', () {
      // newest -> oldest, current balance = 250 (opening 0)
      final txs = [
        _tx(amount: 200, income: true, date: DateTime(2026, 5, 10)),
        _tx(amount: 50, income: false, date: DateTime(2026, 5, 5)),
        _tx(amount: 100, income: true, date: DateTime(2026, 5, 1)),
      ];

      final result = calculateRunningBalance(txs, 250);

      expect(result[0].balanceAfter, 250); // en yeni gelir sonrası
      expect(result[1].balanceAfter, 50); // 250 - 200
      expect(result[2].balanceAfter, 100); // 50 + 50 (gideri geri al)
    });

    test('boş liste boş döner', () {
      expect(calculateRunningBalance(const [], 100), isEmpty);
    });

    test('tek gider işlemi en yeni satırda final bakiyeyi gösterir', () {
      final txs = [_tx(amount: 30, income: false, date: DateTime(2026, 1, 2))];
      final r = calculateRunningBalance(txs, 70);
      expect(r.single.balanceAfter, 70);
    });
  });
}
