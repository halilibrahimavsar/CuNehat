import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvestmentModel', () {
    final date = DateTime(2026, 6, 1);

    // We cannot use const because date is a final variable.
    late InvestmentEntity testEntity;

    setUp(() {
      testEntity = InvestmentEntity(
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
        targetAmount: 2000.0,
        quantity: 0.05,
        goalCategory: 'acil_fon',
        currency: 'USD',
      );
    });

    test('fromEntity should return valid InvestmentModel', () {
      final model = InvestmentModel.fromEntity(testEntity);
      expect(model.id, testEntity.id);
      expect(model.userId, testEntity.userId);
      expect(model.walletId, testEntity.walletId);
      expect(model.name, testEntity.name);
      expect(model.amount, testEntity.amount);
      expect(model.currentValue, testEntity.currentValue);
      expect(model.type, testEntity.type);
      expect(model.color, testEntity.color);
      expect(model.dateAdded, testEntity.dateAdded);
      expect(model.symbol, testEntity.symbol);
      expect(model.targetAmount, testEntity.targetAmount);
      expect(model.quantity, testEntity.quantity);
      expect(model.goalCategory, testEntity.goalCategory);
      expect(model.currency, testEntity.currency);
    });

    test('is an instance of InvestmentEntity', () {
      final model = InvestmentModel(
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
        targetAmount: 2000.0,
        quantity: 0.05,
        goalCategory: 'acil_fon',
        currency: 'USD',
      );
      expect(model, isA<InvestmentEntity>());
      expect(model.name, 'Bitcoin');
    });

    test('toJson returns correct map', () {
      final model = InvestmentModel(
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
        targetAmount: 2000.0,
        quantity: 0.05,
        goalCategory: 'acil_fon',
        currency: 'USD',
      );
      final json = model.toJson();
      expect(json['id'], 'inv_1');
      expect(json['userId'], 'user_1');
      expect(json['type'], 'InvestmentType.custom');
      expect(json['color'], Colors.orange.toARGB32());
      expect(json['dateAdded'], date.toIso8601String());
    });

    test('fromJson returns correct object', () {
      final json = {
        'userId': 'user_1',
        'walletId': 'wallet_1',
        'name': 'Bitcoin',
        'amount': 1000.0,
        'currentValue': 1200.0,
        'type': 'InvestmentType.custom',
        'color': Colors.orange.toARGB32(),
        'dateAdded': date.toIso8601String(),
        'symbol': 'BTC',
        'targetAmount': 2000.0,
        'quantity': 0.05,
        'goalCategory': 'acil_fon',
        'currency': 'USD',
      };
      final model = InvestmentModel.fromJson('inv_1', json);
      expect(model.id, 'inv_1');
      expect(model.name, 'Bitcoin');
      expect(model.type, InvestmentType.custom);
      expect(model.color.toARGB32(), Colors.orange.toARGB32());
      expect(model.dateAdded, date);
    });

    test('copyWith returns updated object', () {
      final model = InvestmentModel(
        id: 'inv_1',
        userId: 'user_1',
        walletId: 'wallet_1',
        name: 'Bitcoin',
        amount: 1000.0,
        currentValue: 1200.0,
        type: InvestmentType.custom,
        color: Colors.orange,
        dateAdded: date,
      );
      final updated =
          model.copyWith(name: 'Bitcoin Updated', currentValue: 1300.0);
      expect(updated.name, 'Bitcoin Updated');
      expect(updated.currentValue, 1300.0);
      expect(updated.id, 'inv_1');
    });
  });
}
