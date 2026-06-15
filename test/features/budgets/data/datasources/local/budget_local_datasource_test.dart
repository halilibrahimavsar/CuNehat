import 'dart:io';
import 'package:cunehat/features/budgets/data/datasources/local/budget_local_datasource.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late BudgetLocalDataSourceImpl dataSource;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_budgets');
    Hive.init(tempDir.path);
    Hive.registerAdapter(BudgetModelAdapter());
  });

  setUp(() {
    dataSource = BudgetLocalDataSourceImpl();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('budgets_box')) {
      final box = Hive.box<BudgetModel>('budgets_box');
      await box.clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BudgetLocalDataSourceImpl', () {
    final testModel1 = BudgetModel(categoryId: 'Food', limitAmount: 1000.0);
    final testModel2 = BudgetModel(categoryId: 'Drinks', limitAmount: 500.0);

    test('should save and get budgets successfully', () async {
      await dataSource.saveBudget(testModel1);
      await dataSource.saveBudget(testModel2);

      final result = await dataSource.getBudgets();

      expect(result.length, 2);
      expect(
          result.any((m) => m.categoryId == 'Food' && m.limitAmount == 1000.0),
          true);
      expect(
          result.any((m) => m.categoryId == 'Drinks' && m.limitAmount == 500.0),
          true);
    });

    test('should overwrite budget when saving with same categoryId', () async {
      await dataSource.saveBudget(testModel1);
      final updatedModel = BudgetModel(categoryId: 'Food', limitAmount: 1200.0);
      await dataSource.saveBudget(updatedModel);

      final result = await dataSource.getBudgets();

      expect(result.length, 1);
      expect(result.first.limitAmount, 1200.0);
    });

    test('should delete budget successfully', () async {
      await dataSource.saveBudget(testModel1);
      await dataSource.saveBudget(testModel2);

      await dataSource.deleteBudget('Food');

      final result = await dataSource.getBudgets();

      expect(result.length, 1);
      expect(result.first.categoryId, 'Drinks');
    });
  });
}
