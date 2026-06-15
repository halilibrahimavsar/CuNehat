import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionEntity', () {
    final date = DateTime(2026, 6, 1);
    final entity = TransactionEntity(
      id: 'tx_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Lunch',
      tag: 'Food',
      amount: 250.0,
      date: date,
      type: TransactionTypeModel.expense,
      isSystem: false,
    );

    test('supports value comparisons (Equatable)', () {
      expect(
        TransactionEntity(
          id: 'tx_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'Lunch',
          tag: 'Food',
          amount: 250.0,
          date: date,
          type: TransactionTypeModel.expense,
          isSystem: false,
        ),
        TransactionEntity(
          id: 'tx_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'Lunch',
          tag: 'Food',
          amount: 250.0,
          date: date,
          type: TransactionTypeModel.expense,
          isSystem: false,
        ),
      );
    });

    test('copyWith returns updated object', () {
      final updated = entity.copyWith(
        id: 'tx_2',
        userId: 'user_2',
        walletId: 'wallet_2',
        title: 'Salary',
        tag: 'Job',
        amount: 5000.0,
        date: DateTime(2026, 6, 2),
        type: TransactionTypeModel.income,
        isSystem: true,
      );

      expect(updated.id, 'tx_2');
      expect(updated.userId, 'user_2');
      expect(updated.walletId, 'wallet_2');
      expect(updated.title, 'Salary');
      expect(updated.tag, 'Job');
      expect(updated.amount, 5000.0);
      expect(updated.date, DateTime(2026, 6, 2));
      expect(updated.type, TransactionTypeModel.income);
      expect(updated.isSystem, true);
    });

    test('copyWith returns same object when no arguments are provided', () {
      expect(entity.copyWith(), entity);
    });

    test('isIncome / isExpense return correct flags', () {
      expect(entity.isExpense, true);
      expect(entity.isIncome, false);

      final incomeEntity = entity.copyWith(type: TransactionTypeModel.income);
      expect(incomeEntity.isExpense, false);
      expect(incomeEntity.isIncome, true);
    });

    test('toJson returns correct map', () {
      final json = entity.toJson();
      expect(json, {
        'id': 'tx_1',
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'title': 'Lunch',
        'tag': 'Food',
        'amount': 250.0,
        'date': date.toIso8601String(),
        'type': 'expense',
        'isSystem': false,
      });
    });
  });
}
