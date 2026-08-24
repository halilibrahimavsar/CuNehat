import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvestmentEntity', () {
    final date = DateTime(2026, 6, 1);
    final entity = InvestmentEntity(
      id: 'inv_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      name: 'Bitcoin',
      amount: 1000.0,
      currentValue: 1200.0,
      type: InvestmentType.custom,
      color: Colors.orange,
      dateAdded: date,
      symbol: 'BTC',
      quantity: 0.05,
      currency: 'USD',
    );

    test('supports value comparisons (Equatable)', () {
      expect(
        InvestmentEntity(
          id: 'inv_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          name: 'Bitcoin',
          amount: 1000.0,
          currentValue: 1200.0,
          type: InvestmentType.custom,
          color: Colors.orange,
          dateAdded: date,
          symbol: 'BTC',
          quantity: 0.05,
          currency: 'USD',
        ),
        InvestmentEntity(
          id: 'inv_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          name: 'Bitcoin',
          amount: 1000.0,
          currentValue: 1200.0,
          type: InvestmentType.custom,
          color: Colors.orange,
          dateAdded: date,
          symbol: 'BTC',
          quantity: 0.05,
          currency: 'USD',
        ),
      );
    });

    test('copyWith returns updated object', () {
      final updated = entity.copyWith(
        id: 'inv_2',
        userId: 'user_2',
        walletId: 'wallet_2',
        name: 'Ethereum',
        amount: 2000.0,
        currentValue: 1800.0,
        type: InvestmentType.stock,
        color: Colors.blue,
        dateAdded: DateTime(2026, 6, 2),
        symbol: 'ETH',
        returnRate: 5.0,
        quantity: 1.0,
        currency: 'TRY',
      );

      expect(updated.id, 'inv_2');
      expect(updated.userId, 'user_2');
      expect(updated.walletId, 'wallet_2');
      expect(updated.name, 'Ethereum');
      expect(updated.amount, 2000.0);
      expect(updated.currentValue, 1800.0);
      expect(updated.type, InvestmentType.stock);
      expect(updated.color, Colors.blue);
      expect(updated.dateAdded, DateTime(2026, 6, 2));
      expect(updated.symbol, 'ETH');
      expect(updated.returnRate, 5.0);
      expect(updated.quantity, 1.0);
      expect(updated.currency, 'TRY');
    });

    test('copyWith returns same object when no arguments are provided', () {
      expect(entity.copyWith(), entity);
    });

    group('calculations', () {
      test('profit and profitPercentage return correct values', () {
        expect(entity.profit, 200.0);
        expect(entity.profitPercentage, 20.0);
        expect(entity.isProfitable, true);

        final lossEntity = entity.copyWith(amount: 1000.0, currentValue: 800.0);
        expect(lossEntity.profit, -200.0);
        expect(lossEntity.profitPercentage, -20.0);
        expect(lossEntity.isProfitable, false);
      });

      test('profitPercentage returns 0 if amount is 0', () {
        final zeroAmount = entity.copyWith(amount: 0.0);
        expect(zeroAmount.profitPercentage, 0.0);
      });

      test('clearGoal hedef bağını koparır (copyWith null ile yapamaz)', () {
        final linked = entity.copyWith(goalId: 'goal_1');
        expect(linked.goalId, 'goal_1');
        expect(linked.copyWith().goalId, 'goal_1');
        expect(linked.clearGoal().goalId, isNull);
        // Diğer alanlar korunur.
        expect(linked.clearGoal().copyWith(goalId: 'goal_1'), linked);
      });

      test('unitValue calculation', () {
        expect(entity.unitValue, 24000.0); // 1200 / 0.05 = 24000

        final noQuantity = InvestmentEntity(
          id: 'inv_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          name: 'Bitcoin',
          amount: 1000.0,
          currentValue: 1200.0,
          type: InvestmentType.custom,
          color: Colors.orange,
          dateAdded: date,
          symbol: 'BTC',
          quantity: null,
          currency: 'USD',
        );
        expect(noQuantity.unitValue, null);

        final zeroQuantity = entity.copyWith(quantity: 0.0);
        expect(zeroQuantity.unitValue, null);
      });

      test(
          'canRefreshPrice returns true only when symbol and quantity > 0 are present',
          () {
        expect(entity.canRefreshPrice, true);

        final noSymbol = InvestmentEntity(
          id: 'inv_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          name: 'Bitcoin',
          amount: 1000.0,
          currentValue: 1200.0,
          type: InvestmentType.custom,
          color: Colors.orange,
          dateAdded: date,
          symbol: null,
          quantity: 0.05,
          currency: 'USD',
        );
        expect(noSymbol.canRefreshPrice, false);

        final noQuantity = InvestmentEntity(
          id: 'inv_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          name: 'Bitcoin',
          amount: 1000.0,
          currentValue: 1200.0,
          type: InvestmentType.custom,
          color: Colors.orange,
          dateAdded: date,
          symbol: 'BTC',
          quantity: null,
          currency: 'USD',
        );
        expect(noQuantity.canRefreshPrice, false);

        final zeroQuantity = entity.copyWith(quantity: 0.0);
        expect(zeroQuantity.canRefreshPrice, false);
      });
    });
  });
}
