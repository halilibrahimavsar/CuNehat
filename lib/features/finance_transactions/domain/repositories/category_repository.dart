import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Kategori kuralı ihlali. [error] tipli olduğu için sunum katmanı çeviriyi
/// kendi yapar — eskiden hazır Türkçe mesaj fırlatılıyor ve İngilizce arayüzde
/// olduğu gibi ekrana basılıyordu.
class CategoryException implements Exception {
  final CategoryValidationError error;

  CategoryException(this.error);

  @override
  String toString() => 'CategoryException(${error.name})';
}

abstract class CategoryRepository {
  /// Tek türün kategorileri, ağaç sırasında (ana kategori, hemen ardından
  /// kendi alt kategorileri).
  Future<List<CategoryEntity>> getCategories(bool isExpense);

  /// Gelir + gider tek turda. Kök/alt eşlemesi (`buildRootIndex`,
  /// `subtreeIds`) türden bağımsız olduğu için toplama yapan her yer bunu
  /// kullanır.
  Future<List<CategoryEntity>> getAllCategories();

  /// Yeni kategori oluşturur ve kaydedilen hâlini döner.
  ///
  /// `id` burada üretilir (UUID) — çağıran kimlik uydurmaz. [parentId] verilirse
  /// tür ondan miras alınır ve [isExpense] ile tutarlı olmalıdır.
  /// Kural ihlalinde [CategoryException] fırlatır.
  Future<CategoryEntity> addCategory({
    required String name,
    required String iconName,
    required bool isExpense,
    String? parentId,
  });

  /// Ad / ikon / ana kategori / sıra günceller. Kural ihlalinde
  /// [CategoryException] fırlatır.
  Future<void> updateCategory(CategoryEntity category);

  /// Kategorileri kutudan siler — başka hiçbir şeye dokunmaz.
  ///
  /// Doğrudan çağırma: silme işlemleri, düzenli şablonları ve bütçeleri de
  /// ilgilendirir, o orkestrasyon `DeleteCategoryUseCase`'te.
  Future<void> deleteCategories(Set<String> ids);

  /// Bir kardeş kümesinin sırasını yazar: [orderedSiblingIds] sırasıyla
  /// 1..n `sortOrder` alır (kökler kendi türü içinde, alt kategoriler kendi
  /// ana kategorisi içinde — `sortOrder` kardeş kapsamlıdır).
  ///
  /// Sıra KÜRESELDİR: kategoriler cüzdanlar arasında ortak olduğu için her
  /// cüzdanda aynı görünür. Artık var olmayan kimlikler atlanır; farklı
  /// kardeş kümelerinden kimlik karıştırılırsa [ArgumentError] fırlatır.
  Future<void> reorder(List<String> orderedSiblingIds);

  /// Verilen kategorileri TEK yazımda ekler (başlangıç paketi).
  Future<List<CategoryEntity>> addAll(Iterable<CategoryEntity> categories);
}
