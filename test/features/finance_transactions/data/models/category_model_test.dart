import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryModel', () {
    const testEntity = CategoryEntity(
      id: 'Food',
      iconName: 'restaurant',
      isExpense: true,
      isDefault: true,
      sortOrder: 1,
    );

    test('toEntity should return a valid CategoryEntity', () {
      const model = CategoryModel(
        id: 'Food',
        iconName: 'restaurant',
        isExpense: true,
        isDefault: true,
        sortOrder: 1,
      );
      final entity = model.toEntity();
      expect(entity, testEntity);
    });

    test('fromEntity should return a valid CategoryModel', () {
      final model = CategoryModel.fromEntity(testEntity);
      expect(model.id, testEntity.id);
      expect(model.iconName, testEntity.iconName);
      expect(model.isExpense, testEntity.isExpense);
      expect(model.isDefault, testEntity.isDefault);
      expect(model.sortOrder, testEntity.sortOrder);
    });

    test('toJson returns correct map', () {
      const model = CategoryModel(
        id: 'Food',
        iconName: 'restaurant',
        isExpense: true,
        isDefault: true,
        sortOrder: 1,
      );
      final json = model.toJson();
      expect(json, {
        'id': 'Food',
        'iconName': 'restaurant',
        'isExpense': true,
        'isDefault': true,
        'sortOrder': 1,
      });
    });

    test('fromJson returns correct object', () {
      final json = {
        'id': 'Food',
        'iconName': 'restaurant',
        'isExpense': true,
        'isDefault': true,
        'sortOrder': 1,
      };
      final model = CategoryModel.fromJson(json);
      expect(model.id, 'Food');
      expect(model.iconName, 'restaurant');
      expect(model.isExpense, true);
      expect(model.isDefault, true);
      expect(model.sortOrder, 1);
    });

    test('copyWith returns updated object', () {
      const model = CategoryModel(
        id: 'Food',
        iconName: 'restaurant',
        isExpense: true,
      );
      final updated = model.copyWith(id: 'Drinks', iconName: 'local_drink');
      expect(updated.id, 'Drinks');
      expect(updated.iconName, 'local_drink');
    });

    test(
        'getDefaultExpenseCategories and getDefaultIncomeCategories return valid defaults',
        () {
      final expenses = CategoryModel.getDefaultExpenseCategories();
      final incomes = CategoryModel.getDefaultIncomeCategories();

      expect(expenses.isNotEmpty, true);
      expect(expenses.every((c) => c.isExpense), true);

      expect(incomes.isNotEmpty, true);
      expect(incomes.every((c) => !c.isExpense), true);
    });

    test('equality checks by id', () {
      const model1 =
          CategoryModel(id: 'Food', iconName: 'restaurant', isExpense: true);
      const model2 =
          CategoryModel(id: 'Food', iconName: 'other', isExpense: false);
      const model3 =
          CategoryModel(id: 'Drinks', iconName: 'restaurant', isExpense: true);

      expect(model1 == model2, true);
      expect(model1 == model3, false);
      expect(model1.hashCode == model2.hashCode, true);
    });

    test('toString formats correctly', () {
      const model =
          CategoryModel(id: 'Food', iconName: 'restaurant', isExpense: true);
      expect(
          model.toString(), 'CategoryModel(id(name): Food, isExpense: true)');
    });
  });
}
