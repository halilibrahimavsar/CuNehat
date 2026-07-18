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
    final testModel1 = BudgetModel(
        categoryId: 'Food', limitAmount: 1000.0, walletId: 'wallet-1');
    final testModel2 = BudgetModel(
        categoryId: 'Drinks', limitAmount: 500.0, walletId: 'wallet-1');

    test('should save and get budgets successfully', () async {
      await dataSource.saveBudget(testModel1);
      await dataSource.saveBudget(testModel2);

      final result = await dataSource.getBudgets('wallet-1');

      expect(result.length, 2);
      expect(
          result.any((m) => m.categoryId == 'Food' && m.limitAmount == 1000.0),
          true);
      expect(
          result.any((m) => m.categoryId == 'Drinks' && m.limitAmount == 500.0),
          true);
    });

    test('should not return budgets of other wallets', () async {
      await dataSource.saveBudget(testModel1);

      final result = await dataSource.getBudgets('wallet-2');

      expect(result, isEmpty);
    });

    test('should keep same category as separate budgets per wallet', () async {
      await dataSource.saveBudget(testModel1);
      await dataSource.saveBudget(BudgetModel(
          categoryId: 'Food', limitAmount: 250.0, walletId: 'wallet-2'));

      final wallet1 = await dataSource.getBudgets('wallet-1');
      final wallet2 = await dataSource.getBudgets('wallet-2');

      expect(wallet1.single.limitAmount, 1000.0);
      expect(wallet2.single.limitAmount, 250.0);
    });

    test('should overwrite budget when saving with same wallet+categoryId',
        () async {
      await dataSource.saveBudget(testModel1);
      final updatedModel = BudgetModel(
          categoryId: 'Food', limitAmount: 1200.0, walletId: 'wallet-1');
      await dataSource.saveBudget(updatedModel);

      final result = await dataSource.getBudgets('wallet-1');

      expect(result.length, 1);
      expect(result.first.limitAmount, 1200.0);
    });

    test('should delete budget successfully', () async {
      await dataSource.saveBudget(testModel1);
      await dataSource.saveBudget(testModel2);

      await dataSource.deleteBudget('wallet-1', 'Food');

      final result = await dataSource.getBudgets('wallet-1');

      expect(result.length, 1);
      expect(result.first.categoryId, 'Drinks');
    });

    test('deleteBudgetsForCategory should clear category on all wallets',
        () async {
      await dataSource.saveBudget(testModel1);
      await dataSource.saveBudget(BudgetModel(
          categoryId: 'Food', limitAmount: 250.0, walletId: 'wallet-2'));
      await dataSource.saveBudget(testModel2);

      await dataSource.deleteBudgetsForCategory('Food');

      expect(await dataSource.getBudgets('wallet-1'), hasLength(1));
      expect(await dataSource.getBudgets('wallet-2'), isEmpty);
    });

    test('should migrate legacy (walletId-less) budgets to requesting wallet',
        () async {
      // Eski kayıt: çıplak categoryId anahtarı, walletId null.
      final box = await Hive.openBox<BudgetModel>('budgets_box');
      await box.put(
          'Food', BudgetModel(categoryId: 'Food', limitAmount: 750.0));

      final migrated = await dataSource.getBudgets('wallet-1');

      expect(migrated.single.walletId, 'wallet-1');
      expect(migrated.single.limitAmount, 750.0);
      // Anahtar bileşik forma taşındı; eski anahtar kalmadı.
      expect(box.get('Food'), isNull);
      expect(box.get('wallet-1::Food'), isNotNull);
      // Başka cüzdan artık bu bütçeyi devralamaz.
      expect(await dataSource.getBudgets('wallet-2'), isEmpty);
    });
  });
}
