import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';

/// Kategori adlarının içe aktarım ekranlarında GÖSTERİM biçimi:
/// `id → gösterilecek ad`.
///
/// Dosya adı `import_category_labels`: `category_label.dart` adı
/// `finance_transactions/presentation/` altında ZATEN var ve o dosya
/// kırıntıyı KOŞULSUZ kuran genel yolu ([buildBreadcrumbs]) taşıyor. İki
/// ayrı politika, iki ayrı ad.
///
/// Alt kategori adları tür içinde tekil DEĞİLDİR — tekillik yalnız KARDEŞLER
/// arasında aranır (bkz. `validateCategory`), yani "Su" hem `Fatura` hem
/// `Market` altında durabilir. Satırda çıplak yaprak adını basmak bu iki
/// kategoriyi ayırt edilemez kılar; kullanıcı hangisine baktığını bilemeden
/// toplu atama yapar. (Kategori seçici arama sonuçlarında aynı sebeple ana
/// kategoriyi alt yazı olarak gösteriyor.)
///
/// Kırıntı YALNIZ gerektiğinde eklenir: adı tür içinde tekil olan kategori
/// kısa hâliyle kalır, çünkü inceleme satırı dar ve her ada "Fatura › " eklemek
/// asıl bilgiyi kırpardı.
Map<String, String> buildImportCategoryLabels(
  List<CategoryEntity> categories,
) {
  final byId = {for (final c in categories) c.id: c};
  final counts = <String, int>{};
  for (final c in categories) {
    counts.update(normalizeCategoryName(c.name), (v) => v + 1,
        ifAbsent: () => 1);
  }

  return {
    for (final c in categories)
      c.id: switch ((counts[normalizeCategoryName(c.name)] ?? 1) > 1
          ? byId[c.parentId]
          : null) {
        final parent? => '${parent.name} $kCategorySeparator ${c.name}',
        null => c.name,
      },
  };
}
