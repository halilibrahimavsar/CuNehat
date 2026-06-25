import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryEntity', () {
    const entity = CategoryEntity(
      id: 'Food',
      iconName: 'fastfood',
      isExpense: true,
      isDefault: true,
      sortOrder: 1,
    );

    test('supports value comparisons (Equatable)', () {
      expect(
        const CategoryEntity(
          id: 'Food',
          iconName: 'fastfood',
          isExpense: true,
          isDefault: true,
          sortOrder: 1,
        ),
        const CategoryEntity(
          id: 'Food',
          iconName: 'fastfood',
          isExpense: true,
          isDefault: true,
          sortOrder: 1,
        ),
      );
    });

    test('copyWith returns updated object', () {
      final updated = entity.copyWith(
        id: 'Drinks',
        iconName: 'local_drink',
        isExpense: false,
        isDefault: false,
        sortOrder: 2,
      );

      expect(updated.id, 'Drinks');
      expect(updated.iconName, 'local_drink');
      expect(updated.isExpense, false);
      expect(updated.isDefault, false);
      expect(updated.sortOrder, 2);
    });

    test('copyWith returns same object when no arguments are provided', () {
      expect(entity.copyWith(), entity);
    });
  });
}
