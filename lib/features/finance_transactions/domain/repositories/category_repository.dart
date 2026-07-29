import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Kategori erişim sözleşmesi. Presentation yalnız bunu görür;
/// SharedPreferences detayı data katmanındaki CategoryService'te kalır.
abstract class CategoryRepository {
  Future<List<CategoryEntity>> getExpenseCategories();
  Future<List<CategoryEntity>> getIncomeCategories();
  Future<List<CategoryEntity>> getCategories(bool isExpense);

  /// Silinen varsayılanlar dahil tam liste (kategori yöneticisi için).
  Future<List<CategoryEntity>> getCategoriesWithDefaults(bool isExpense);

  /// [displayLabels]: id → kullanıcının GÖRDÜĞÜ ad. Çift-ad koruması bunun
  /// üzerinden çalışır; varsayılanların l10n karşılığı yalnız sunum
  /// katmanında bilindiği için oradan doldurulur.
  Future<void> addCategory(
    CategoryEntity category, {
    Map<String, String> displayLabels,
  });

  /// Bkz. [addCategory] — [displayLabels] aynı işi görür ve kullanıcının
  /// GİRDİĞİ yeni adı da kategorinin kendi id'si altında taşır.
  Future<void> updateCategory(
    CategoryEntity category, {
    Map<String, String> displayLabels,
  });
  Future<void> deleteCategory(String categoryId, bool isExpense);
}
