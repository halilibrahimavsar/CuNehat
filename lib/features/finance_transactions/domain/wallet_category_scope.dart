/// Cüzdan × kategori görünürlük kuralı — saf fonksiyonlar, I/O yok.
///
/// Kategoriler küresel kayıtlardır: `TransactionEntity.tag`, bütçenin
/// `walletId::categoryId` anahtarı ve CSV'deki okunaklı ad cüzdandan
/// bağımsızdır. Cüzdan yalnız **hangilerini kullandığını** söyler
/// ([WalletEntity.categoryIds]).
///
/// Kural tek yerde duruyor çünkü aynı soruyu ("bu cüzdanda hangi kategoriler
/// var?") altı ayrı yüzey soruyor — işlem formu, ekstre inceleme seçicisi,
/// kategori formunun ana kategori listesi, filtre ağacı, bütçe seçici ve
/// kategori sayfası. Her biri kendi `where`'ini yazsaydı sapma kaçınılmazdı
/// (aynı hata rapor tarafında ölçüldü: kırılım iki yerde hesaplanıyordu ve
/// alt sayfa kuplaj anahtarını yok sayıyordu).
library;

import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// [visibleIds] `null` iken hepsi görünür.
///
/// Bu, alanı hiç olmayan eski cüzdanların anlamıdır: kürasyon yapılmamış bir
/// cüzdan bugünkü davranışı sürdürür. Boş liste ise **gerçekten boş**: yeni
/// doğmuş, henüz kategori seçilmemiş cüzdan.
bool isCuratedWallet(List<String>? visibleIds) => visibleIds != null;

/// Bu cüzdana başlangıç paketi ÖNERİLMELİ mi?
///
/// Kural cüzdan bazlıdır. Eskiden küresel `categories.isEmpty` idi ve ikinci
/// cüzdanını kuran kullanıcıya paket hiç sorulmuyordu: birinci cüzdanın tüm
/// kalemleri sessizce devrediyordu.
///
/// - Küratörlü cüzdan ([visibleIds] non-null): kümesi boşsa önerilir.
/// - Kürasyonsuz cüzdan (`null`, yani güncelleme öncesinden kalan): eski
///   davranış korunur — yalnız SİSTEMDE hiç kategori yoksa önerilir.
bool needsCategorySetup({
  required List<String>? visibleIds,
  required bool anyCategoryExists,
}) =>
    visibleIds == null ? !anyCategoryExists : visibleIds.isEmpty;

/// [all] içinden bu cüzdanda görünür olanları, ağaç sırasında döner.
///
/// [alwaysInclude] kümede olmasa bile listeye katılır ve (alt kategoriyse) kökü
/// de katılır. Düzenlenen bir işlemin mevcut kategorisi için ŞART: form
/// listede olmayan seçimi temizliyor (`TransactionFormController.loadCategories`),
/// yani gizlenmiş bir kategorideki işlemi açıp kaydetmek kategoriyi sessizce
/// düşürürdü.
List<CategoryEntity> scopeCategoriesToWallet(
  Iterable<CategoryEntity> all,
  List<String>? visibleIds, {
  String? alwaysInclude,
}) {
  if (visibleIds == null) return flattenTree(all);

  final keep = <String>{...visibleIds};
  if (alwaysInclude != null) {
    final extra = all.where((c) => c.id == alwaysInclude).firstOrNull;
    if (extra != null) {
      keep.add(extra.id);
      final parentId = extra.parentId;
      if (parentId != null) keep.add(parentId);
    }
  }

  // Yetim çocuk bırakma: kökü elenen bir alt kategori `buildCategoryTree`'de
  // hiçbir düğüme bağlanamaz ve listeden sessizce düşerdi. Yazma tarafı
  // ([applyCategoryVisibility]) bunu zaten garanti eder; burada okuma tarafı
  // da kendini savunuyor çünkü küme yedekten/eski sürümden de gelebilir.
  return flattenTree(all.where((c) {
    if (!keep.contains(c.id)) return false;
    final parentId = c.parentId;
    return parentId == null || keep.contains(parentId);
  }));
}

/// Görünürlük kümesine tek bir kategoriyi ekler/çıkarır ve **basamak
/// değişmezini** korur: bir alt kategori kümedeyse kökü de kümededir.
///
/// - Kök AÇILIR: yalnız kök girer (çocuklar tek tek seçilir).
/// - Kök KAPANIR: alt ağacın tamamı çıkar — aksi halde geride kökü olmayan
///   çocuklar kalır ve ağaç kurulamaz.
/// - Çocuk AÇILIR: kökü de girer.
/// - Çocuk KAPANIR: yalnız kendisi çıkar.
///
/// Küme sırası korunur (ekleme sırası = kullanıcının seçim sırası), yeni
/// kimlikler sona eklenir.
List<String> applyCategoryVisibility(
  List<String> current,
  Iterable<CategoryEntity> all, {
  required String categoryId,
  required bool visible,
}) {
  final category = all.where((c) => c.id == categoryId).firstOrNull;
  if (category == null) return List<String>.from(current);

  final result = List<String>.from(current);

  void add(String id) {
    if (!result.contains(id)) result.add(id);
  }

  if (visible) {
    final parentId = category.parentId;
    if (parentId != null) add(parentId);
    add(categoryId);
    return result;
  }

  final doomed = category.isRoot ? subtreeIds(categoryId, all) : {categoryId};
  result.removeWhere(doomed.contains);
  return result;
}

/// [ids] ve (alt kategoriyse) kökleri kümeye katılır.
///
/// Başlangıç paketi kurulumu ve "yeni kategori oluştur" akışı bunu kullanır:
/// kullanıcının az önce yarattığı kategori, yarattığı cüzdanda görünmezse
/// özelliğin tamamı kırık görünür.
List<String> includeCategories(
  List<String> current,
  Iterable<CategoryEntity> all,
  Iterable<String> ids,
) {
  var result = List<String>.from(current);
  for (final id in ids) {
    result = applyCategoryVisibility(
      result,
      all,
      categoryId: id,
      visible: true,
    );
  }
  return result;
}
