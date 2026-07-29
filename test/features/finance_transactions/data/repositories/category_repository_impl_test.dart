import 'package:cunehat/core/services/categories_changed_notifier.dart';
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
  late CategoriesChangedNotifier changedNotifier;

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
    changedNotifier = CategoriesChangedNotifier();
    repository = CategoryRepositoryImpl(mockService, changedNotifier);
  });

  tearDown(() => changedNotifier.dispose());

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

    // ----------------------------------------------- değişim bildirimi
    //
    // Etiket/ikon haritaları sayfa seviyesinde initState'te kuruluyordu:
    // Rapor/Analiz/Bütçeler route yığınında dururken yapılan bir yeniden
    // adlandırma ancak sayfa yeniden kurulduğunda görünüyordu. Kategoriyi
    // DEĞİŞTİREN her yol bu kanaldan haber vermeli.

    test('add / update / delete kategori değişimini yayınlar', () async {
      when(() => mockService.addCategory(any(),
          displayLabels: any(named: 'displayLabels'))).thenAnswer((_) async {});
      when(() => mockService.updateCategory(any(),
          displayLabels: any(named: 'displayLabels'))).thenAnswer((_) async {});
      when(() => mockService.deleteCategory(any(), any()))
          .thenAnswer((_) async {});

      final seen = <void>[];
      final sub = changedNotifier.stream.listen(seen.add);

      await repository.addCategory(testEntity);
      await repository.updateCategory(testEntity);
      await repository.deleteCategory('Food', true);
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(3));
      await sub.cancel();
    });

    test('okuma yolları bildirim YAYMAZ', () async {
      when(() => mockService.getExpenseCategories())
          .thenAnswer((_) async => [testModel]);

      final seen = <void>[];
      final sub = changedNotifier.stream.listen(seen.add);

      await repository.getExpenseCategories();
      await Future<void>.delayed(Duration.zero);

      expect(seen, isEmpty);
      await sub.cancel();
    });
  });
}
