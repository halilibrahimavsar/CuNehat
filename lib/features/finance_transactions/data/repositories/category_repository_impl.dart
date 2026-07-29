import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryService service;

  /// Kategori listesini DEĞİŞTİREN her yol buradan geçer; açık sayfaların
  /// ikon/ad indeksini tazeleyebilmesi için tek uyarı noktası burasıdır.
  final CategoriesChangedNotifier changedNotifier;

  CategoryRepositoryImpl(this.service, this.changedNotifier);

  @override
  Future<List<CategoryEntity>> getExpenseCategories() async =>
      (await service.getExpenseCategories()).map((m) => m.toEntity()).toList();

  @override
  Future<List<CategoryEntity>> getIncomeCategories() async =>
      (await service.getIncomeCategories()).map((m) => m.toEntity()).toList();

  @override
  Future<List<CategoryEntity>> getCategories(bool isExpense) async =>
      (await service.getCategories(isExpense))
          .map((m) => m.toEntity())
          .toList();

  @override
  Future<List<CategoryEntity>> getCategoriesWithDefaults(
          bool isExpense) async =>
      (await service.getCategoriesWithDefaults(isExpense))
          .map((m) => m.toEntity())
          .toList();

  @override
  Future<void> addCategory(
    CategoryEntity category, {
    Map<String, String> displayLabels = const {},
  }) async {
    await service.addCategory(CategoryModel.fromEntity(category),
        displayLabels: displayLabels);
    changedNotifier.notify();
  }

  @override
  Future<void> updateCategory(
    CategoryEntity category, {
    Map<String, String> displayLabels = const {},
  }) async {
    await service.updateCategory(CategoryModel.fromEntity(category),
        displayLabels: displayLabels);
    changedNotifier.notify();
  }

  @override
  Future<void> deleteCategory(String categoryId, bool isExpense) async {
    await service.deleteCategory(categoryId, isExpense);
    changedNotifier.notify();
  }
}
