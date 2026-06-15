import 'dart:io';
import 'package:cunehat/features/investments/data/datasource/investment_local_datasource.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/data/models/investment_type_adapter.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/color_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late InvestmentLocalDatasource dataSource;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_investments');
    Hive.init(tempDir.path);
    Hive.registerAdapter(ColorAdapter());
    Hive.registerAdapter(InvestmentTypeAdapter());
    Hive.registerAdapter(InvestmentModelAdapter());
  });

  setUp(() {
    dataSource = InvestmentLocalDatasource();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('investments_box')) {
      final box = Hive.box<InvestmentModel>('investments_box');
      await box.clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('InvestmentLocalDatasource', () {
    final t1 = InvestmentModel(
      id: 'inv_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      name: 'Bitcoin',
      amount: 1000.0,
      currentValue: 1200.0,
      type: InvestmentType.custom,
      color: Colors.orange,
      dateAdded: DateTime(2026, 6, 1),
    );

    final t2 = InvestmentModel(
      id: 'inv_2',
      userId: 'user_1',
      walletId: 'wallet_2',
      name: 'Gold',
      amount: 500.0,
      currentValue: 550.0,
      type: InvestmentType.gold,
      color: Colors.yellow,
      dateAdded: DateTime(2026, 6, 1),
    );

    test('should add and get investments successfully by walletId', () async {
      await dataSource.addInvestment(t1);
      await dataSource.addInvestment(t2);

      final resultWallet1 = await dataSource.getInvestments(
          userId: 'user_1', walletId: 'wallet_1');
      final resultWallet2 = await dataSource.getInvestments(
          userId: 'user_1', walletId: 'wallet_2');

      expect(resultWallet1.length, 1);
      expect(resultWallet1.first.name, 'Bitcoin');

      expect(resultWallet2.length, 1);
      expect(resultWallet2.first.name, 'Gold');
    });

    test('should update investment successfully', () async {
      await dataSource.addInvestment(t1);
      final updated =
          t1.copyWith(name: 'Bitcoin Updated', currentValue: 1300.0);
      await dataSource.updateInvestment(updated);

      final result = await dataSource.getInvestments(
          userId: 'user_1', walletId: 'wallet_1');
      expect(result.first.name, 'Bitcoin Updated');
      expect(result.first.currentValue, 1300.0);
    });

    test('should delete investment successfully', () async {
      await dataSource.addInvestment(t1);
      await dataSource.deleteInvestment(id: 'inv_1');

      final result = await dataSource.getInvestments(
          userId: 'user_1', walletId: 'wallet_1');
      expect(result.isEmpty, true);
    });
  });
}
