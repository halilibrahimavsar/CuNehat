import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringTransactionModel', () {
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
      anchorDay: nextDate.day,
      isActive: true,
    );

    test('is a subclass of RecurringTransactionEntity', () {
      final model = RecurringTransactionModel.fromEntity(entity);
      expect(model, isA<RecurringTransactionEntity>());
    });

    test('fromEntity should return a valid model matching the entity', () {
      final model = RecurringTransactionModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.walletId, entity.walletId);
      expect(model.title, entity.title);
      expect(model.tag, entity.tag);
      expect(model.amount, entity.amount);
      expect(model.type, entity.type);
      expect(model.frequency, entity.frequency);
      expect(model.nextExecutionDate, entity.nextExecutionDate);
      expect(model.isActive, entity.isActive);
    });

    test('toEntity should return a valid entity matching the model', () {
      final model = RecurringTransactionModel(
        id: 'rec_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Rent',
        tag: 'housing',
        amount: 1500.0,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: nextDate,
        anchorDay: nextDate.day,
        isActive: true,
      );

      final mappedEntity = model.toEntity();
      expect(mappedEntity, entity);
    });
  });
}
