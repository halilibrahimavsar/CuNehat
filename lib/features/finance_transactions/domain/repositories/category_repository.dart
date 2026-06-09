import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Kategori erişim sözleşmesi. Presentation yalnız bunu görür;
/// SharedPreferences detayı data katmanındaki CategoryService'te kalır.
abstract class CategoryRepository {
  Future<List<CategoryEntity>> getExpenseCategories();
  Future<List<CategoryEntity>> getIncomeCategories();
  Future<List<CategoryEntity>> getCategories(bool isExpense);

  /// Silinen varsayılanlar dahil tam liste (kategori yöneticisi için).
  Future<List<CategoryEntity>> getCategoriesWithDefaults(bool isExpense);

  Future<void> addCategory(CategoryEntity category);
  Future<void> updateCategory(CategoryEntity category);
  Future<void> deleteCategory(String categoryId, bool isExpense);
}
