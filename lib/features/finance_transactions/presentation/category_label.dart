import 'package:cunehat/core/shared/widgets/icon_picker.dart' show AppIcons;
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:flutter/widgets.dart';

/// Kategori adlarının TEK gösterim yolu.
///
/// `CategoryEntity.id` opak bir anahtardır ve deftere `TransactionEntity.tag`
/// olarak bu hâliyle yazılır — ekrana asla doğrudan basılmamalıdır. Görünen ad
/// iki kaynaktan gelir:
///   1. Kullanıcı kategoriyi yeniden adlandırdıysa `displayName`,
///   2. aksi hâlde id'nin l10n karşılığı (`translateCategory`).
extension CategoryLabelX on BuildContext {
  /// [category] için kullanıcıya gösterilecek ad.
  String categoryLabel(CategoryEntity category) =>
      category.displayName ?? translateCategory(category.id);

  /// Elde yalnız ham `tag` / `categoryId` varken görünen ad.
  ///
  /// [labels] (bkz. [buildCategoryLabelMap]) kullanıcının yeniden
  /// adlandırmalarını taşır. Haritada olmayan tag'ler — sistem etiketleri
  /// ("Borç", "Transfer") ve silinmiş kategorilerden kalan tag'ler — l10n'a
  /// düşer, o da bilmiyorsa tag olduğu gibi gösterilir.
  String categoryLabelForTag(String tag, {Map<String, String>? labels}) =>
      labels?[tag] ?? translateCategory(tag);
}

/// `tag` → görünen ad haritası. Bir listenin her satırında kategori araması
/// yapmamak için sayfa seviyesinde bir kez kurulur ve aşağı geçirilir
/// (`categoryIcons` ile aynı kanal).
Map<String, String> buildCategoryLabelMap(
  BuildContext context,
  Iterable<CategoryEntity> categories,
) =>
    {for (final c in categories) c.id: context.categoryLabel(c)};

/// Kategori kimliğinden GÖRÜNÜME giden indeks: ikon ve ad tek bir şeyin iki
/// yarısıdır — aynı anahtarla (`c.id`) kurulur, birlikte yüklenir, birlikte
/// geçirilir.
typedef CategoryDisplayIndex = ({
  Map<String, IconData> icons,
  Map<String, String> labels,
});

/// Gider + gelir kategorilerini tek turda çeker.
///
/// Dört sayfa (işlemler, rapor, analiz, bütçeler) bu turu ayrı ayrı elle
/// yazıyordu; ikisi karakter karakter aynıydı, biri ikon yarısını atlıyordu,
/// biri de zaten yükleyen bir dosyada ikinci kez yüklüyordu. Kopyalar
/// sapmıştı: analiz sayfası indeksin yalnız yarısını kullanıyordu.
Future<List<CategoryEntity>> fetchAllCategories(CategoryRepository repo) async {
  final lists = await Future.wait([
    repo.getExpenseCategories(),
    repo.getIncomeCategories(),
  ]);
  return [for (final list in lists) ...list];
}

/// [categories]'ten görüntüleme indeksini kurar.
///
/// Ayrı adım olmasının nedeni [BuildContext]: l10n çözümü senkron yapılmalı,
/// `await`ten sonra context kullanmak zorunda kalınmamalı. Çağıran önce
/// [fetchAllCategories]'i bekler, `mounted` kontrolünü yapar, sonra bunu
/// çağırır.
CategoryDisplayIndex buildCategoryDisplayIndex(
  BuildContext context,
  Iterable<CategoryEntity> categories,
) =>
    (
      icons: {
        for (final c in categories) c.id: AppIcons.getIconData(c.iconName),
      },
      labels: buildCategoryLabelMap(context, categories),
    );
