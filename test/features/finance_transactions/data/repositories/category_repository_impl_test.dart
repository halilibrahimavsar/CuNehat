import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/data/repositories/category_repository_impl.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryService extends Mock implements CategoryService {}

void main() {
  late CategoryRepositoryImpl repository;
  late MockCategoryService mockService;

  setUpAll(() {
    registerFallbackValue(
      const CategoryModel(
        id: 'fallback',
        iconName: 'fallback',
        isExpense: true,
      ),
    );
  });

  setUp(() {
    mockService = MockCategoryService();
    repository = CategoryRepositoryImpl(mockService);
  });

  const testModel = CategoryModel(
    id: 'Food',
    iconName: 'restaurant',
    isExpense: true,
    isDefault: true,
    sortOrder: 1,
  );

  const testEntity = CategoryEntity(
    id: 'Food',
    iconName: 'restaurant',
    isExpense: true,
    isDefault: true,
    sortOrder: 1,
  );

  group('CategoryRepositoryImpl', () {
    test('getExpenseCategories should return categories from service',
        () async {
      when(() => mockService.getExpenseCategories())
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getExpenseCategories();

      expect(result, [testEntity]);
      verify(() => mockService.getExpenseCategories()).called(1);
    });

    test('getIncomeCategories should return categories from service', () async {
      when(() => mockService.getIncomeCategories())
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getIncomeCategories();

      expect(result, [testEntity]);
      verify(() => mockService.getIncomeCategories()).called(1);
    });

    test('getCategories should return categories from service', () async {
      when(() => mockService.getCategories(any()))
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getCategories(true);

      expect(result, [testEntity]);
      verify(() => mockService.getCategories(true)).called(1);
    });

    test('getCategoriesWithDefaults should return categories from service',
        () async {
      when(() => mockService.getCategoriesWithDefaults(any()))
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getCategoriesWithDefaults(true);

      expect(result, [testEntity]);
      verify(() => mockService.getCategoriesWithDefaults(true)).called(1);
    });

    test('addCategory delegates to service', () async {
      when(() => mockService.addCategory(any())).thenAnswer((_) async => {});

      await repository.addCategory(testEntity);

      verify(() => mockService.addCategory(any())).called(1);
    });

    test('updateCategory delegates to service', () async {
      when(() => mockService.updateCategory(any())).thenAnswer((_) async => {});

      await repository.updateCategory(testEntity);

      verify(() => mockService.updateCategory(any())).called(1);
    });

    test('deleteCategory delegates to service', () async {
      when(() => mockService.deleteCategory(any(), any()))
          .thenAnswer((_) async => {});

      await repository.deleteCategory('Food', true);

      verify(() => mockService.deleteCategory('Food', true)).called(1);
    });
  });
}
