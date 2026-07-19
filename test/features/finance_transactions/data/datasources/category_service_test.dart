import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CategoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = CategoryService();
  });

  group('CategoryService', () {
    const customExpense = CategoryModel(
      id: 'Custom Food',
      iconName: 'restaurant',
      isExpense: true,
      isDefault: false,
      sortOrder: 10,
    );

    test(
        'should return default categories when no custom categories are stored',
        () async {
      final expenses = await service.getExpenseCategories();
      final incomes = await service.getIncomeCategories();

      expect(
          expenses.length, CategoryModel.getDefaultExpenseCategories().length);
      expect(incomes.length, CategoryModel.getDefaultIncomeCategories().length);
      expect(expenses.first.isDefault, true);
    });

    test('should add custom category successfully', () async {
      await service.addCategory(customExpense);

      final expenses = await service.getExpenseCategories();

      expect(expenses.length,
          CategoryModel.getDefaultExpenseCategories().length + 1);
      expect(expenses.any((c) => c.id == 'Custom Food'), true);
    });

    test('should throw error when adding default category', () async {
      const defaultCat = CategoryModel(
        id: 'Yemek',
        iconName: 'restaurant',
        isExpense: true,
        isDefault: true,
      );

      expect(() => service.addCategory(defaultCat), throwsException);
    });

    test('should throw error when category name already exists', () async {
      await service.addCategory(customExpense);
      expect(() => service.addCategory(customExpense), throwsException);
    });

    test('sistem etiketiyle aynı adlı kategori reddedilir', () async {
      // Bütçe/rapor `tag == categoryId` ile eşleşir; "Borç Ödemesi" adlı
      // kategori sistem hareketlerini kendine sayardı.
      const reserved = CategoryModel(
        id: 'Borç Ödemesi',
        iconName: 'payment',
        isExpense: true,
        isDefault: false,
      );
      expect(() => service.addCategory(reserved), throwsException);

      // Büyük/küçük harf farkı da korumayı aşamaz.
      const reservedLower = CategoryModel(
        id: 'transfer',
        iconName: 'swap',
        isExpense: true,
        isDefault: false,
      );
      expect(() => service.addCategory(reservedLower), throwsException);
    });

    test('should update custom category successfully', () async {
      await service.addCategory(customExpense);

      final updated = customExpense.copyWith(iconName: 'updated_icon');
      await service.updateCategory(updated);

      final expenses = await service.getExpenseCategories();
      final category = expenses.firstWhere((c) => c.id == 'Custom Food');
      expect(category.iconName, 'updated_icon');
    });

    test('should update default category in updated defaults', () async {
      final defaultExpense = CategoryModel.getDefaultExpenseCategories().first;
      final updatedDefault = defaultExpense.copyWith(sortOrder: 100);

      await service.updateCategory(updatedDefault);

      final expenses = await service.getExpenseCategories();
      final category = expenses.firstWhere((c) => c.id == defaultExpense.id);
      expect(category.sortOrder, 100);
    });

    test('should delete custom category successfully', () async {
      await service.addCategory(customExpense);
      await service.deleteCategory('Custom Food', true);

      final expenses = await service.getExpenseCategories();
      expect(expenses.any((c) => c.id == 'Custom Food'), false);
    });

    test(
        'should throw error when updating default category that does not exist in defaults',
        () async {
      const nonExistentDefault = CategoryModel(
        id: 'NonExistentDefault',
        iconName: 'help',
        isExpense: true,
        isDefault: true,
      );
      expect(() => service.updateCategory(nonExistentDefault), throwsException);
    });

    test('should throw error when updating custom category that does not exist',
        () async {
      const nonExistentCustom = CategoryModel(
        id: 'NonExistentCustom',
        iconName: 'help',
        isExpense: true,
        isDefault: false,
      );
      expect(() => service.updateCategory(nonExistentCustom), throwsException);
    });

    test('should load existing updated defaults when updating again', () async {
      final defaultExpense = CategoryModel.getDefaultExpenseCategories().first;
      final updatedDefault1 = defaultExpense.copyWith(sortOrder: 100);
      await service.updateCategory(updatedDefault1);

      final updatedDefault2 = defaultExpense.copyWith(sortOrder: 200);
      await service.updateCategory(updatedDefault2);

      final expenses = await service.getExpenseCategories();
      final category = expenses.firstWhere((c) => c.id == defaultExpense.id);
      expect(category.sortOrder, 200);
    });

    test(
        'should update default income category successfully and hit default income fallback path',
        () async {
      final defaultIncome = CategoryModel.getDefaultIncomeCategories().first;
      final updatedIncome = defaultIncome.copyWith(sortOrder: 150);

      await service.updateCategory(updatedIncome);

      final incomes = await service.getIncomeCategories();
      final category = incomes.firstWhere((c) => c.id == defaultIncome.id);
      expect(category.sortOrder, 150);
    });
  });
}
