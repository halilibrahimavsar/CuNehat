import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringTransactionEntity', () {
    final nextDate = DateTime(2026, 6, 15);
    final entity = RecurringTransactionEntity(
      id: 'rec_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Rent',
      tag: 'housing',
      amount: 1500.0,
      type: TransactionTypeModel.expense,
      frequency: RecurringFrequency.monthly,
      nextExecutionDate: nextDate,
      isActive: true,
    );

    test('supports value comparisons (Equatable)', () {
      expect(
        RecurringTransactionEntity(
          id: 'rec_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'Rent',
          tag: 'housing',
          amount: 1500.0,
          type: TransactionTypeModel.expense,
          frequency: RecurringFrequency.monthly,
          nextExecutionDate: nextDate,
          isActive: true,
        ),
        RecurringTransactionEntity(
          id: 'rec_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'Rent',
          tag: 'housing',
          amount: 1500.0,
          type: TransactionTypeModel.expense,
          frequency: RecurringFrequency.monthly,
          nextExecutionDate: nextDate,
          isActive: true,
        ),
      );
    });

    test('copyWith returns updated object', () {
      final updated = entity.copyWith(
        id: 'rec_2',
        userId: 'user_2',
        walletId: 'wallet_2',
        title: 'Salary',
        tag: 'salary',
        amount: 5000.0,
        type: TransactionTypeModel.income,
        frequency: RecurringFrequency.weekly,
        nextExecutionDate: DateTime(2026, 6, 20),
        isActive: false,
      );

      expect(updated.id, 'rec_2');
      expect(updated.userId, 'user_2');
      expect(updated.walletId, 'wallet_2');
      expect(updated.title, 'Salary');
      expect(updated.tag, 'salary');
      expect(updated.amount, 5000.0);
      expect(updated.type, TransactionTypeModel.income);
      expect(updated.frequency, RecurringFrequency.weekly);
      expect(updated.nextExecutionDate, DateTime(2026, 6, 20));
      expect(updated.isActive, false);
    });

    test('copyWith returns same object when no arguments are provided', () {
      expect(entity.copyWith(), entity);
    });
  });

  group('RecurringFrequency', () {
    test('displayName returns correct Turkish labels', () {
      expect(RecurringFrequency.daily.displayName, 'Günlük');
      expect(RecurringFrequency.weekly.displayName, 'Haftalık');
      expect(RecurringFrequency.monthly.displayName, 'Aylık');
      expect(RecurringFrequency.yearly.displayName, 'Yıllık');
    });
  });
}
