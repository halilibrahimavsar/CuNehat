import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceivableModel', () {
    final dueDate = DateTime(2026, 12, 31);
    final entity = ReceivableEntity(
      id: 'rec_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      debtorName: 'John Doe',
      amount: 1500.0,
      dueDate: dueDate,
      isPaid: false,
      notes: 'Lent money for rent',
    );

    test('fromEntity should return valid ReceivableModel', () {
      final model = ReceivableModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.walletId, entity.walletId);
      expect(model.debtorName, entity.debtorName);
      expect(model.amount, entity.amount);
      expect(model.dueDate, entity.dueDate);
      expect(model.isPaid, entity.isPaid);
      expect(model.notes, entity.notes);
    });

    test('toEntity should return valid ReceivableEntity', () {
      final model = ReceivableModel(
        id: 'rec_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        debtorName: 'John Doe',
        amount: 1500.0,
        dueDate: dueDate,
        isPaid: false,
        notes: 'Lent money for rent',
      );
      final entityResult = model.toEntity();
      expect(entityResult.id, model.id);
      expect(entityResult.debtorName, model.debtorName);
    });

    test('copyWith returns updated object', () {
      final model = ReceivableModel(
        id: 'rec_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        debtorName: 'John Doe',
        amount: 1500.0,
        dueDate: dueDate,
      );
      final updated = model.copyWith(debtorName: 'Jane Smith', isPaid: true);
      expect(updated.debtorName, 'Jane Smith');
      expect(updated.isPaid, true);
    });

    test('toJson returns correct map', () {
      final model = ReceivableModel(
        id: 'rec_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        debtorName: 'John Doe',
        amount: 1500.0,
        dueDate: dueDate,
        isPaid: false,
        notes: 'Lent money for rent',
      );
      final json = model.toJson();
      expect(json, {
        'id': 'rec_1',
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'debtorName': 'John Doe',
        'amount': 1500.0,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': false,
        'notes': 'Lent money for rent',
      });
    });

    test('fromJson returns correct object', () {
      final json = {
        'id': 'rec_1',
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'debtorName': 'John Doe',
        'amount': 1500.0,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': false,
        'notes': 'Lent money for rent',
      };
      final model = ReceivableModel.fromJson(json);
      expect(model.id, 'rec_1');
      expect(model.debtorName, 'John Doe');
      expect(model.amount, 1500.0);
      expect(model.dueDate, dueDate);
      expect(model.isPaid, false);
      expect(model.notes, 'Lent money for rent');
    });
  });
}
