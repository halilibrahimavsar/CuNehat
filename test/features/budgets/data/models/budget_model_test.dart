import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetModel', () {
    const testEntity = BudgetEntity(
      categoryId: 'Food',
      limitAmount: 1000.0,
      spentAmount: 0.0, // spentAmount is not saved in local model
    );

    test('fromEntity should return a valid BudgetModel', () {
      final model = BudgetModel.fromEntity(testEntity);

      expect(model.categoryId, testEntity.categoryId);
      expect(model.limitAmount, testEntity.limitAmount);
    });

    test('toEntity should return a valid BudgetEntity', () {
      final model = BudgetModel(
        categoryId: 'Drinks',
        limitAmount: 500.0,
        walletId: 'wallet_123',
      );

      final entity = model.toEntity();

      expect(entity.categoryId, 'Drinks');
      expect(entity.limitAmount, 500.0);
      expect(entity.spentAmount, 0.0); // Default value
    });
  });
}
