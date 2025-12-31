import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvestmentModel', () {
    test('toJson should serialize all fields correctly', () {
      final model = InvestmentModel(
        id: '123',
        name: 'Apple Inc.',
        amount: 1000.0,
        currentValue: 1200.0,
        type: InvestmentType.stock,
        color: const Color(0xFF112233),
        dateAdded: DateTime.parse('2024-01-10T12:30:00.000Z'),
        symbol: 'AAPL',
        returnRate: 20.0,
      );

      final json = model.toJson();

      expect(json['id'], '123');
      expect(json['name'], 'Apple Inc.');
      expect(json['amount'], 1000.0);
      expect(json['currentValue'], 1200.0);
      expect(json['type'], InvestmentType.stock.toString());
      expect(json['color'], const Color(0xFF112233).value);
      expect(json['dateAdded'], '2024-01-10T12:30:00.000Z');
      expect(json['symbol'], 'AAPL');
      expect(json['returnRate'], 20.0);
    });

    test('fromJson should parse with defaults when fields missing', () {
      final json = <String, dynamic>{
        'name': 'Gold',
        'dateAdded': '2024-02-01T00:00:00.000Z',
      };

      final model = InvestmentModel.fromJson('id-1', json);

      expect(model.id, 'id-1');
      expect(model.name, 'Gold');
      expect(model.amount, 0.0);
      expect(model.currentValue, 0.0);
      expect(model.type, InvestmentType.stock); // default
      expect(model.color, const Color(0xFF0000)); // default
      expect(model.dateAdded, DateTime.parse('2024-02-01T00:00:00.000Z'));
      expect(model.symbol, isNull);
      expect(model.returnRate, 0.0);
    });

    test(
        'fromJson should respect provided type, color, and numeric conversions',
        () {
      final json = <String, dynamic>{
        'name': 'Custom Asset',
        'amount': 1500, // int provided, should convert to double
        'currentValue': 1750.5, // already double
        'type': InvestmentType.gold.toString(),
        'color': const Color(0xFFABCDEF).value,
        'dateAdded': '2023-12-31T23:59:59.000Z',
        'symbol': 'XAU',
        'returnRate': 5, // int should convert to double
      };

      final model = InvestmentModel.fromJson('gold-1', json);

      expect(model.id, 'gold-1');
      expect(model.name, 'Custom Asset');
      expect(model.amount, 1500.0);
      expect(model.currentValue, 1750.5);
      expect(model.type, InvestmentType.gold);
      expect(model.color, const Color(0xFFABCDEF));
      expect(model.dateAdded, DateTime.parse('2023-12-31T23:59:59.000Z'));
      expect(model.symbol, 'XAU');
      expect(model.returnRate, 5.0);
    });

    test('copyWith should override only specified fields', () {
      final original = InvestmentModel(
        id: 'base',
        name: 'Original',
        amount: 2000.0,
        currentValue: 2100.0,
        type: InvestmentType.custom,
        color: Colors.green,
        dateAdded: DateTime.parse('2023-01-01T00:00:00.000Z'),
        symbol: 'ORG',
        returnRate: 2.0,
      );

      final updated = original.copyWith(
        name: 'Updated',
        currentValue: 2200.0,
        color: Colors.blue,
      );

      expect(updated.id, 'base');
      expect(updated.name, 'Updated');
      expect(updated.amount, 2000.0);
      expect(updated.currentValue, 2200.0);
      expect(updated.type, InvestmentType.custom);
      expect(updated.color, Colors.blue);
      expect(updated.dateAdded, DateTime.parse('2023-01-01T00:00:00.000Z'));
      expect(updated.symbol, 'ORG');
      expect(updated.returnRate, 2.0);
    });

    test('fromEntity should map entity fields into model correctly', () {
      final entity = InvestmentEntity(
        id: 'e1',
        name: 'Entity Asset',
        amount: 500.0,
        currentValue: 650.0,
        type: InvestmentType.stock,
        color: Colors.red,
        dateAdded: DateTime.parse('2022-06-15T10:00:00.000Z'),
        symbol: 'ENT',
        returnRate: 30.0,
      );

      final model = InvestmentModel.fromEntity(entity);

      expect(model.id, 'e1');
      expect(model.name, 'Entity Asset');
      expect(model.amount, 500.0);
      expect(model.currentValue, 650.0);
      expect(model.type, InvestmentType.stock);
      expect(model.color, Colors.red);
      expect(model.dateAdded, DateTime.parse('2022-06-15T10:00:00.000Z'));
      expect(model.symbol, 'ENT');
      expect(model.returnRate, 30.0);
    });
  });
}
