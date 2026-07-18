import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('WalletModel', () {
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

    final json = {
      'id': 'wallet_1',
      'userId': 'user_1',
      'name': 'Cash',
      'balance': 1000.0,
      'debt': 100.0,
      'credit': 50.0,
      'investment': 200.0,
      'colorHex': '0xFF4CAF50',
      'iconName': 'money',
      'createdAt': createdDate.toIso8601String(),
      'isActive': true,
      'sortOrder': 1,
      'openingBalance': 800.0,
      'currency': 'TRY',
    };

    test('fromEntity and toEntity should match correctly', () {
      final model = WalletModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.name, entity.name);
      expect(model.balance, entity.balance);
      expect(model.debt, entity.debt);
      expect(model.credit, entity.credit);
      expect(model.investment, entity.investment);
      expect(model.colorHex, entity.colorHex);
      expect(model.iconName, entity.iconName);
      expect(model.createdAt, entity.createdAt);
      expect(model.isActive, entity.isActive);
      expect(model.sortOrder, entity.sortOrder);
      expect(model.openingBalance, entity.openingBalance);
      expect(model.currency, entity.currency);

      final mappedEntity = model.toEntity();
      expect(mappedEntity, entity);
    });

    test('fromJson returns correct object', () {
      final model = WalletModel.fromJson('wallet_1', json);
      expect(model.id, 'wallet_1');
      expect(model.userId, 'user_1');
      expect(model.name, 'Cash');
      expect(model.balance, 1000.0);
      expect(model.debt, 100.0);
      expect(model.credit, 50.0);
      expect(model.investment, 200.0);
      expect(model.colorHex, '0xFF4CAF50');
      expect(model.iconName, 'money');
      expect(model.createdAt, createdDate);
      expect(model.isActive, true);
      expect(model.sortOrder, 1);
      expect(model.openingBalance, 800.0);
    });

    test('fromJson currency anahtarını okur', () {
      final usdJson = Map<String, dynamic>.from(json)..['currency'] = 'USD';
      final model = WalletModel.fromJson('wallet_1', usdJson);
      expect(model.currency, 'USD');
    });

    test('toJson returns correct map', () {
      final model = WalletModel.fromEntity(entity);
      final modelJson = model.toJson();
      expect(modelJson, json);
    });

    test('copyWith returns updated object with partial parameters', () {
      final model = WalletModel.fromEntity(entity);
      final updated = model.copyWith(
        id: 'wallet_2',
        name: 'Bank',
        balance: 1500.0,
      );

      expect(updated.id, 'wallet_2');
      expect(updated.name, 'Bank');
      expect(updated.balance, 1500.0);
      expect(updated.userId, model.userId);
      expect(updated.debt, model.debt);
      expect(updated.credit, model.credit);
      expect(updated.investment, model.investment);
      expect(updated.colorHex, model.colorHex);
      expect(updated.iconName, model.iconName);
      expect(updated.createdAt, model.createdAt);
      expect(updated.isActive, model.isActive);
      expect(updated.sortOrder, model.sortOrder);
      expect(updated.openingBalance, model.openingBalance);
    });

    test('copyWith returns identical object when no parameters provided', () {
      final model = WalletModel.fromEntity(entity);
      final updated = model.copyWith();
      expect(updated.id, model.id);
      expect(updated.name, model.name);
    });

    test('toString returns expected string format', () {
      final model = WalletModel.fromEntity(entity);
      expect(model.toString(),
          'WalletModel(id: wallet_1, name: Cash, balance: 1000.0)');
    });
  });

  group('WalletModelAdapter', () {
    final createdDate = DateTime(2026, 6, 1);
    final model = WalletModel(
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

    test('write writes all fields to BinaryWriter', () {
      final adapter = WalletModelAdapter();
      final writer = MockBinaryWriter();

      adapter.write(writer, model);

      // Alan sayısı: 14 (0-13, 13 = currency)
      verify(() => writer.writeByte(14)).called(1);

      // Verify that write was called for each generic type
      verify(() => writer.write<String?>(any(),
          writeTypeId: any(named: 'writeTypeId'))).called(1);
      // name, colorHex, iconName, userId + currency
      verify(() => writer.write<String>(any(),
          writeTypeId: any(named: 'writeTypeId'))).called(5);
      // balance, debt, credit, investment, openingBalance
      verify(() => writer.write<double>(any(),
          writeTypeId: any(named: 'writeTypeId'))).called(5);
      verify(() => writer.write<DateTime>(any(),
          writeTypeId: any(named: 'writeTypeId'))).called(1);
      verify(() =>
              writer.write<bool>(any(), writeTypeId: any(named: 'writeTypeId')))
          .called(1);
      verify(() =>
              writer.write<int>(any(), writeTypeId: any(named: 'writeTypeId')))
          .called(1);

      // Verify all writeBytes are called sequentially
      for (int i = 0; i <= 13; i++) {
        verify(() => writer.writeByte(i)).called(1);
      }
    });

    test('read parses currency field (14 alanlı yeni kayıt)', () {
      final adapter = WalletModelAdapter();
      final reader = MockBinaryReader();

      final byteAnswers = [14, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
      when(() => reader.readByte()).thenAnswer((_) => byteAnswers.removeAt(0));

      final readAnswers = [
        'wallet_1', // id
        'user_1', // userId
        'Dolar Hesabı', // name
        1000.0, // balance
        0.0, // debt
        0.0, // credit
        0.0, // investment
        '0xFF4CAF50', // colorHex
        'money', // iconName
        createdDate, // createdAt
        true, // isActive
        1, // sortOrder
        800.0, // openingBalance
        'USD', // currency
      ];
      when(() => reader.read()).thenAnswer((_) => readAnswers.removeAt(0));

      final result = adapter.read(reader);

      expect(result.currency, 'USD');
      expect(result.balance, 1000.0);
    });

  });
}

class MockBinaryReader extends Mock implements BinaryReader {}

class MockBinaryWriter extends Mock implements BinaryWriter {}
