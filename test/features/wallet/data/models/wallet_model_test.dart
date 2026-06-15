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
      'save': 200.0,
      'colorHex': '0xFF4CAF50',
      'iconName': 'money',
      'createdAt': createdDate.toIso8601String(),
      'isActive': true,
      'sortOrder': 1,
      'openingBalance': 800.0,
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

    test('fromJson defaults null createdAt to now', () {
      final jsonWithNullDate = Map<String, dynamic>.from(json)
        ..remove('createdAt');
      final model = WalletModel.fromJson('wallet_1', jsonWithNullDate);
      expect(model.createdAt, isA<DateTime>());
      // should be close to now
      expect(DateTime.now().difference(model.createdAt).inSeconds < 5, true);
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

      verify(() => writer.writeByte(13)).called(1);

      // Verify that write was called for each generic type
      verify(() => writer.write<String?>(any(),
          writeTypeId: any(named: 'writeTypeId'))).called(1);
      verify(() => writer.write<String>(any(),
          writeTypeId: any(named: 'writeTypeId'))).called(4);
      verify(() => writer.write<double>(any(),
          writeTypeId: any(named: 'writeTypeId'))).called(4);
      verify(() => writer.write<DateTime>(any(),
          writeTypeId: any(named: 'writeTypeId'))).called(1);
      verify(() =>
              writer.write<bool>(any(), writeTypeId: any(named: 'writeTypeId')))
          .called(1);
      verify(() =>
              writer.write<int>(any(), writeTypeId: any(named: 'writeTypeId')))
          .called(1);
      verify(() => writer.write<double?>(any(),
          writeTypeId: any(named: 'writeTypeId'))).called(1);

      // Verify all writeBytes are called sequentially
      for (int i = 0; i <= 12; i++) {
        verify(() => writer.writeByte(i)).called(1);
      }
    });

    test('read parses new schema format correctly', () {
      final adapter = WalletModelAdapter();
      final reader = MockBinaryReader();

      final byteAnswers = [13, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      when(() => reader.readByte()).thenAnswer((_) => byteAnswers.removeAt(0));

      final readAnswers = [
        'wallet_1', // id
        'user_1', // userId
        'Cash', // name
        1000.0, // balance
        100.0, // debt
        50.0, // credit
        200.0, // investment
        '0xFF4CAF50', // colorHex
        'money', // iconName
        createdDate, // createdAt
        true, // isActive
        1, // sortOrder
        800.0 // openingBalance
      ];
      when(() => reader.read()).thenAnswer((_) => readAnswers.removeAt(0));

      final result = adapter.read(reader);

      expect(result.id, 'wallet_1');
      expect(result.userId, 'user_1');
      expect(result.name, 'Cash');
      expect(result.balance, 1000.0);
      expect(result.debt, 100.0);
      expect(result.credit, 50.0);
      expect(result.investment, 200.0);
      expect(result.colorHex, '0xFF4CAF50');
      expect(result.iconName, 'money');
      expect(result.createdAt, createdDate);
      expect(result.isActive, true);
      expect(result.sortOrder, 1);
      expect(result.openingBalance, 800.0);
    });

    test('read parses old schema format correctly', () {
      final adapter = WalletModelAdapter();
      final reader = MockBinaryReader();

      final byteAnswers = [9, 0, 1, 2, 3, 4, 5, 6, 7, 8];
      when(() => reader.readByte()).thenAnswer((_) => byteAnswers.removeAt(0));

      final readAnswers = [
        'wallet_1', // id
        'user_1', // userId
        'Cash', // name
        1000.0, // balance
        '0xFF4CAF50', // colorHex
        'money', // iconName
        createdDate, // createdAt
        true, // isActive
        1, // sortOrder
      ];
      when(() => reader.read()).thenAnswer((_) => readAnswers.removeAt(0));

      final result = adapter.read(reader);

      expect(result.id, 'wallet_1');
      expect(result.userId, 'user_1');
      expect(result.name, 'Cash');
      expect(result.balance, 1000.0);
      expect(result.debt, 0.0); // fallback
      expect(result.credit, 0.0); // fallback
      expect(result.investment, 0.0); // fallback
      expect(result.colorHex, '0xFF4CAF50');
      expect(result.iconName, 'money');
      expect(result.createdAt, createdDate);
      expect(result.isActive, true);
      expect(result.sortOrder, 1);
      expect(result.openingBalance, isNull);
    });

    test('read parses null values safely and defaults them', () {
      final adapter = WalletModelAdapter();
      final reader = MockBinaryReader();

      final byteAnswers = [13, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      when(() => reader.readByte()).thenAnswer((_) => byteAnswers.removeAt(0));

      final readAnswers = [
        null, // id
        null, // userId -> 'local_user'
        null, // name -> ''
        null, // balance -> 0.0
        null, // debt -> 0.0
        null, // credit -> 0.0
        null, // investment -> 0.0
        null, // colorHex -> '0xFF2196F3'
        null, // iconName -> 'wallet'
        null, // createdAt -> now
        null, // isActive -> false
        null, // sortOrder -> 0
        null // openingBalance -> null
      ];
      when(() => reader.read()).thenAnswer((_) => readAnswers.removeAt(0));

      final result = adapter.read(reader);

      expect(result.id, isNull);
      expect(result.userId, 'local_user');
      expect(result.name, '');
      expect(result.balance, 0.0);
      expect(result.debt, 0.0);
      expect(result.credit, 0.0);
      expect(result.investment, 0.0);
      expect(result.colorHex, '0xFF2196F3');
      expect(result.iconName, 'wallet');
      expect(result.createdAt, isA<DateTime>());
      expect(result.isActive, false);
      expect(result.sortOrder, 0);
    });

    test('read parses String values as doubles safely', () {
      final adapter = WalletModelAdapter();
      final reader = MockBinaryReader();

      final byteAnswers = [13, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      when(() => reader.readByte()).thenAnswer((_) => byteAnswers.removeAt(0));

      final readAnswers = [
        'wallet_1', // id
        'user_1', // userId
        'Cash', // name
        '1000.50', // balance as String
        '100.25', // debt as String
        '50.75', // credit as String
        '200.00', // investment as String
        '0xFF4CAF50', // colorHex
        'money', // iconName
        createdDate, // createdAt
        true, // isActive
        1, // sortOrder
        '800.00' // openingBalance as String
      ];
      when(() => reader.read()).thenAnswer((_) => readAnswers.removeAt(0));

      final result = adapter.read(reader);

      expect(result.balance, 1000.50);
      expect(result.debt, 100.25);
      expect(result.credit, 50.75);
      expect(result.investment, 200.00);
      expect(result.openingBalance, 800.00);
    });

    test('read returns 0.0 when double value is of unhandled type', () {
      final adapter = WalletModelAdapter();
      final reader = MockBinaryReader();

      final byteAnswers = [13, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
      when(() => reader.readByte()).thenAnswer((_) => byteAnswers.removeAt(0));

      final readAnswers = [
        'wallet_1', // id
        'user_1', // userId
        'Cash', // name
        const [], // balance as unhandled list type
        const {}, // debt as unhandled map type
        const [], // credit as unhandled list type
        const {}, // investment as unhandled map type
        '0xFF4CAF50', // colorHex
        'money', // iconName
        createdDate, // createdAt
        true, // isActive
        1, // sortOrder
        const [] // openingBalance as unhandled list type
      ];
      when(() => reader.read()).thenAnswer((_) => readAnswers.removeAt(0));

      final result = adapter.read(reader);

      expect(result.balance, 0.0);
      expect(result.debt, 0.0);
      expect(result.credit, 0.0);
      expect(result.investment, 0.0);
      expect(result.openingBalance, 0.0);
    });
  });
}

class MockBinaryReader extends Mock implements BinaryReader {}

class MockBinaryWriter extends Mock implements BinaryWriter {}
