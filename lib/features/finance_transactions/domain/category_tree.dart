import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Kategori hiyerarşisinin TEK kaynağı — saf fonksiyonlar, I/O yok.
///
/// Rapor, bütçe, filtre, seçici ve veri katmanı hepsi buradan okur. Toplama
/// kuralı ("ana kategori çocuklarını kapsar") birden çok yerde elle yazılırsa
/// er ya da geç sapar; o yüzden `rootIdOf` / `subtreeIds` dışında hiçbir yerde
/// `parentId` üzerinde manuel gezinme yapılmamalıdır.

/// Bir ana kategori ve (varsa) alt kategorileri.
typedef CategoryNode = ({
  CategoryEntity category,
  List<CategoryEntity> children
});

/// [validateCategory]'nin reddetme sebepleri.
///
/// Enum döner, hazır metin değil: veri katmanı l10n bilmez, sunum katmanı
/// çeviriyi kendi yapar (projenin "BLoC'ta l10n string yok" konvansiyonu).
enum CategoryValidationError {
  /// Ad boş ya da yalnız boşluk.
  emptyName,

  /// Aynı ana kategori altında (veya aynı türün kökünde) bu ad zaten var.
  duplicateSiblingName,

  /// Verilen [CategoryEntity.parentId] hiçbir kayda karşılık gelmiyor.
  parentNotFound,

  /// Seçilen ana kategori kendisi bir alt kategori — üçüncü seviye olurdu.
  parentIsNotRoot,

  /// Alt kategori, ana kategorisinden farklı türde (gelir/gider) olamaz.
  typeMismatch,

  /// Kategori kendi ana kategorisi olamaz.
  selfParent,

  /// Çocuğu olan bir kategori alt kategoriye taşınamaz — çocukları üçüncü
  /// seviyeye düşerdi.
  parentHasChildren,
}

/// Ad karşılaştırma anahtarı: Türkçe-duyarlı katlama ([foldTr]).
///
/// (`CategoryGuesser._normalizeTr` ile bilerek ayrı: orada amaç işlem
/// AÇIKLAMASINDA anahtar kelime aramak, ayraçlar da sadeleşiyor; burada amaç
/// kullanıcının yazdığı iki adı karşılaştırmak.)
String normalizeCategoryName(String name) => foldTr(name);

/// [all] içindeki kökleri, altlarında çocuklarıyla döner.
///
/// Kökler ve çocuklar ayrı ayrı `sortOrder`'a, eşitlikte ada göre sıralanır —
/// `sortOrder` kardeş kapsamlıdır, listenin tamamında tekil değildir.
List<CategoryNode> buildCategoryTree(Iterable<CategoryEntity> all) {
  final childrenByParent = <String, List<CategoryEntity>>{};
  final roots = <CategoryEntity>[];

  for (final c in all) {
    final parentId = c.parentId;
    if (parentId == null) {
      roots.add(c);
    } else {
      childrenByParent.putIfAbsent(parentId, () => []).add(c);
    }
  }

  roots.sort(_bySortOrderThenName);
  for (final list in childrenByParent.values) {
    list.sort(_bySortOrderThenName);
  }

  return [
    for (final root in roots)
      (category: root, children: childrenByParent[root.id] ?? const []),
  ];
}

/// Ağacı düz listeye açar: ana kategori, hemen ardından kendi çocukları.
///
/// Yönetim listesi ve seçicilerin gösterim sırası budur.
List<CategoryEntity> flattenTree(Iterable<CategoryEntity> all) => [
      for (final node in buildCategoryTree(all)) ...[
        node.category,
        ...node.children,
      ],
    ];

/// `id → kök id` haritası. Ana kategoriler kendilerini gösterir.
Map<String, String> buildRootIndex(Iterable<CategoryEntity> all) =>
    {for (final c in all) c.id: c.parentId ?? c.id};

/// [tag]'in toplanacağı kök kategori.
///
/// Haritada olmayan tag'ler KENDİLERİNİ döner. Bu bilinçli: `TransactionEntity.tag`
/// sistem hareketlerinde bir `CashMovementTags` sabiti taşır ("Borç", "Transfer")
/// ve o satırlar kendi başlarına ayrı bir kalem olarak görünmelidir.
String rootIdOf(String tag, Map<String, String> rootIndex) =>
    rootIndex[tag] ?? tag;

/// [id] ve (ana kategoriyse) tüm çocukları.
///
/// Bütçe ve filtre "ana kategori çocuklarını kapsar" kuralını bununla uygular.
Set<String> subtreeIds(String id, Iterable<CategoryEntity> all) => {
      id,
      for (final c in all)
        if (c.parentId == id) c.id,
    };

/// [id]'nin doğrudan çocukları, `sortOrder` sırasında.
List<CategoryEntity> childrenOf(String id, Iterable<CategoryEntity> all) {
  final children = [
    for (final c in all)
      if (c.parentId == id) c,
  ]..sort(_bySortOrderThenName);
  return children;
}

/// `id → "Fatura › Elektrik"` haritası. Kökler yalnız kendi adlarını taşır.
///
/// Bildirim gövdesi, CSV dışa aktarımı ve seçici alt yazısı gibi bağlamın ada
/// eklenmesi gereken yerler için.
Map<String, String> buildBreadcrumbs(Iterable<CategoryEntity> all) {
  final byId = {for (final c in all) c.id: c};
  return {
    for (final c in all)
      c.id: switch (byId[c.parentId]) {
        final parent? => '${parent.name} › ${c.name}',
        null => c.name,
      },
  };
}

/// [candidate] kaydedilebilir mi? Sorun varsa sebebini, yoksa `null` döner.
///
/// [existing] mevcut TÜM kategorileri (gelir + gider) içermelidir; düzenlemede
/// [candidate] listede kendi eski hâliyle bulunabilir, kendisiyle çakışma
/// aranmaz.
CategoryValidationError? validateCategory(
  CategoryEntity candidate,
  Iterable<CategoryEntity> existing,
) {
  if (candidate.name.trim().isEmpty) return CategoryValidationError.emptyName;

  final parentId = candidate.parentId;
  if (parentId != null) {
    if (parentId == candidate.id) return CategoryValidationError.selfParent;

    CategoryEntity? parent;
    for (final c in existing) {
      if (c.id == parentId) {
        parent = c;
        break;
      }
    }
    if (parent == null) return CategoryValidationError.parentNotFound;
    if (!parent.isRoot) return CategoryValidationError.parentIsNotRoot;
    if (parent.isExpense != candidate.isExpense) {
      return CategoryValidationError.typeMismatch;
    }

    // Çocuğu olan bir kategori alt kategoriye taşınırsa çocukları üçüncü
    // seviyeye düşer.
    final hasChildren = existing.any((c) => c.parentId == candidate.id);
    if (hasChildren) return CategoryValidationError.parentHasChildren;
  }

  final target = normalizeCategoryName(candidate.name);
  final clash = existing.any(
    (c) =>
        c.id != candidate.id &&
        c.isExpense == candidate.isExpense &&
        c.parentId == candidate.parentId &&
        normalizeCategoryName(c.name) == target,
  );
  if (clash) return CategoryValidationError.duplicateSiblingName;

  return null;
}

int _bySortOrderThenName(CategoryEntity a, CategoryEntity b) {
  final bySort = a.sortOrder.compareTo(b.sortOrder);
  return bySort != 0 ? bySort : a.name.compareTo(b.name);
}
