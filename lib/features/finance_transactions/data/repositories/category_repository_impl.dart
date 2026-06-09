import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryService service;

  CategoryRepositoryImpl(this.service);

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
  Future<void> addCategory(CategoryEntity category) =>
      service.addCategory(CategoryModel.fromEntity(category));

  @override
  Future<void> updateCategory(CategoryEntity category) =>
      service.updateCategory(CategoryModel.fromEntity(category));

  @override
  Future<void> deleteCategory(String categoryId, bool isExpense) =>
      service.deleteCategory(categoryId, isExpense);
}
