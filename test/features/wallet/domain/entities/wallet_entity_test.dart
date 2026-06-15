import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletEntity', () {
    final createdDate = DateTime(2026, 6, 1);
    final entity = WalletEntity(
      id: 'wallet_1',
      userId: 'user_1',
      name: 'Cash',
      balance: 1000.0,
      debt: 100.0,
      credit: 50.0,
      investment: 200.0,
      colorHex: '0xFF4CAF50',
      iconName: 'money',
      createdAt: createdDate,
      isActive: true,
      sortOrder: 1,
      openingBalance: 800.0,
    );

    test('supports value comparisons (Equatable)', () {
      expect(
        WalletEntity(
          id: 'wallet_1',
          userId: 'user_1',
          name: 'Cash',
          balance: 1000.0,
          debt: 100.0,
          credit: 50.0,
          investment: 200.0,
          colorHex: '0xFF4CAF50',
          iconName: 'money',
          createdAt: createdDate,
          isActive: true,
          sortOrder: 1,
          openingBalance: 800.0,
        ),
        WalletEntity(
          id: 'wallet_1',
          userId: 'user_1',
          name: 'Cash',
          balance: 1000.0,
          debt: 100.0,
          credit: 50.0,
          investment: 200.0,
          colorHex: '0xFF4CAF50',
          iconName: 'money',
          createdAt: createdDate,
          isActive: true,
          sortOrder: 1,
          openingBalance: 800.0,
        ),
      );
    });

    test('copyWith returns updated object', () {
      final updated = entity.copyWith(
        id: 'wallet_2',
        userId: 'user_2',
        name: 'Bank',
        balance: 2000.0,
        debt: 0.0,
        credit: 0.0,
        investment: 500.0,
        colorHex: '0xFF2196F3',
        iconName: 'account_balance',
        createdAt: DateTime(2026, 6, 2),
        isActive: false,
        sortOrder: 2,
        openingBalance: 1500.0,
      );

      expect(updated.id, 'wallet_2');
      expect(updated.userId, 'user_2');
      expect(updated.name, 'Bank');
      expect(updated.balance, 2000.0);
      expect(updated.debt, 0.0);
      expect(updated.credit, 0.0);
      expect(updated.investment, 500.0);
      expect(updated.colorHex, '0xFF2196F3');
      expect(updated.iconName, 'account_balance');
      expect(updated.createdAt, DateTime(2026, 6, 2));
      expect(updated.isActive, false);
      expect(updated.sortOrder, 2);
      expect(updated.openingBalance, 1500.0);
    });

    test('copyWith returns same object when no arguments are provided', () {
      expect(entity.copyWith(), entity);
    });
  });
}
