import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionModel', () {
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

    test('toEntity should return a valid TransactionEntity', () {
      final model = TransactionModel(
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
      final resultEntity = model.toEntity();
      expect(resultEntity, entity);
    });

    test('fromEntity should return a valid TransactionModel', () {
      final model = TransactionModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.walletId, entity.walletId);
      expect(model.title, entity.title);
      expect(model.tag, entity.tag);
      expect(model.amount, entity.amount);
      expect(model.date, entity.date);
      expect(model.type, entity.type);
      expect(model.isSystem, entity.isSystem);
    });

    test('toJson returns correct map', () {
      final model = TransactionModel(
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
      final json = model.toJson();
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

    test('fromJson returns correct object', () {
      final json = {
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'title': 'Lunch',
        'tag': 'Food',
        'amount': 250.0,
        'date': date.toIso8601String(),
        'type': 'expense',
        'isSystem': false,
      };
      final model = TransactionModel.fromJson('tx_1', json);
      expect(model.id, 'tx_1');
      expect(model.userId, 'user_1');
      expect(model.walletId, 'wallet_1');
      expect(model.title, 'Lunch');
      expect(model.tag, 'Food');
      expect(model.amount, 250.0);
      expect(model.date, date);
      expect(model.type, TransactionTypeModel.expense);
      expect(model.isSystem, false);
    });

    test('fromJson throws Exception for invalid date format', () {
      final json = {
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'title': 'Lunch',
        'tag': 'Food',
        'amount': 250.0,
        'date': 12345678, // invalid date type
        'type': 'expense',
        'isSystem': false,
      };
      expect(() => TransactionModel.fromJson('tx_1', json), throwsException);
    });

    test('copyWith returns updated object', () {
      final model = TransactionModel(
        id: 'tx_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        title: 'Lunch',
        tag: 'Food',
        amount: 250.0,
        date: date,
        type: TransactionTypeModel.expense,
      );

      final updated = model.copyWith(title: 'Dinner', amount: 300.0);
      expect(updated.title, 'Dinner');
      expect(updated.amount, 300.0);
      expect(updated.id, 'tx_1');
    });
  });
}
