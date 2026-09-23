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
        'receiptFileName': null,
        'reference': null,
      });
    });

    group('edited (düzenleme formu)', () {
      final imported = entity.copyWith(
        reference: 'DK-77',
        receiptFileName: 'fis.jpg',
      );

      test('formda olmayan alanları özgünden taşır', () {
        final e = imported.edited(
          title: 'Bim',
          tag: 'Market',
          amount: 913.15,
          date: DateTime(2026, 6, 3),
          type: TransactionTypeModel.expense,
          receiptFileName: 'fis.jpg',
        );
        expect(e.id, 'tx_1');
        expect(e.userId, 'user_1');
        expect(e.walletId, 'wallet_1');
        expect(e.isSystem, isFalse);
        expect(e.reference, 'DK-77');
        expect(e.title, 'Bim');
        expect(e.tag, 'Market');
        expect(e.amount, 913.15);
      });

      test('fiş kaldırılabilir (copyWith bunu yapamaz)', () {
        final e = imported.edited(
          title: imported.title,
          tag: imported.tag,
          amount: imported.amount,
          date: imported.date,
          type: imported.type,
          receiptFileName: null,
        );
        expect(e.receiptFileName, isNull);
        expect(e.reference, 'DK-77');
      });
    });
  });
}
