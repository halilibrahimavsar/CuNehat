import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetEntity', () {
    test('supports value comparisons (Equatable)', () {
      expect(
        const BudgetEntity(
            categoryId: 'Food', limitAmount: 1000.0, spentAmount: 100.0),
        const BudgetEntity(
            categoryId: 'Food', limitAmount: 1000.0, spentAmount: 100.0),
      );
    });

    test('copyWith returns object with updated values', () {
      const entity = BudgetEntity(
          categoryId: 'Food', limitAmount: 1000.0, spentAmount: 100.0);
      final updated = entity.copyWith(
        categoryId: 'Drinks',
        limitAmount: 500.0,
        spentAmount: 50.0,
      );

      expect(updated.categoryId, 'Drinks');
      expect(updated.limitAmount, 500.0);
      expect(updated.spentAmount, 50.0);
    });

    test('copyWith returns same values if no parameters are passed', () {
      const entity = BudgetEntity(
          categoryId: 'Food', limitAmount: 1000.0, spentAmount: 100.0);
      final updated = entity.copyWith();

      expect(updated, entity);
    });

    group('progress', () {
      test('calculates correct progress ratio', () {
        const entity = BudgetEntity(
            categoryId: 'Food', limitAmount: 1000.0, spentAmount: 400.0);
        expect(entity.progress, 0.4);
      });

      test('returns 0.0 when limitAmount is 0', () {
        const entity = BudgetEntity(
            categoryId: 'Food', limitAmount: 0.0, spentAmount: 100.0);
        expect(entity.progress, 0.0);
      });

      test('clamps progress ratio to 1.0 when spentAmount exceeds limitAmount',
          () {
        const entity = BudgetEntity(
            categoryId: 'Food', limitAmount: 1000.0, spentAmount: 1200.0);
        expect(entity.progress, 1.0);
      });

      test('clamps progress ratio to 0.0 when spentAmount is negative', () {
        const entity = BudgetEntity(
            categoryId: 'Food', limitAmount: 1000.0, spentAmount: -50.0);
        expect(entity.progress, 0.0);
      });
    });

    group('isExceeded', () {
      test('returns true when spentAmount is greater than limitAmount', () {
        const entity = BudgetEntity(
            categoryId: 'Food', limitAmount: 1000.0, spentAmount: 1001.0);
        expect(entity.isExceeded, true);
      });

      test('returns false when spentAmount is equal to limitAmount', () {
        const entity = BudgetEntity(
            categoryId: 'Food', limitAmount: 1000.0, spentAmount: 1000.0);
        expect(entity.isExceeded, false);
      });

      test('returns false when spentAmount is less than limitAmount', () {
        const entity = BudgetEntity(
            categoryId: 'Food', limitAmount: 1000.0, spentAmount: 999.0);
        expect(entity.isExceeded, false);
      });
    });
  });
}
