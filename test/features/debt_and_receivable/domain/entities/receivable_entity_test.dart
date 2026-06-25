import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceivableEntity', () {
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

    test('supports value comparisons (Equatable)', () {
      expect(
        ReceivableEntity(
          id: 'rec_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          debtorName: 'John Doe',
          amount: 1500.0,
          dueDate: dueDate,
          isPaid: false,
          notes: 'Lent money for rent',
        ),
        ReceivableEntity(
          id: 'rec_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          debtorName: 'John Doe',
          amount: 1500.0,
          dueDate: dueDate,
          isPaid: false,
          notes: 'Lent money for rent',
        ),
      );
    });

    test('copyWith returns updated object', () {
      final updated = entity.copyWith(
        id: 'rec_2',
        userId: 'user_2',
        walletId: 'wallet_2',
        debtorName: 'Jane Smith',
        amount: 2500.0,
        dueDate: DateTime(2027, 1, 1),
        isPaid: true,
        notes: 'Updated note',
      );

      expect(updated.id, 'rec_2');
      expect(updated.userId, 'user_2');
      expect(updated.walletId, 'wallet_2');
      expect(updated.debtorName, 'Jane Smith');
      expect(updated.amount, 2500.0);
      expect(updated.dueDate, DateTime(2027, 1, 1));
      expect(updated.isPaid, true);
      expect(updated.notes, 'Updated note');
    });

    test('copyWith returns same object when no arguments are provided', () {
      expect(entity.copyWith(), entity);
    });
  });
}
