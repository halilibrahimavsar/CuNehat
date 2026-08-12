import 'package:cunehat/core/shared/widgets/icon_picker.dart' show AppIcons;
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:flutter/widgets.dart';

/// Kategori adlarının TEK gösterim yolu.
///
/// `CategoryEntity.id` opak bir UUID'dir ve deftere `TransactionEntity.tag`
/// olarak bu hâliyle yazılır — ekrana asla doğrudan basılmamalıdır.
extension CategoryLabelX on BuildContext {
  /// Elde yalnız ham `tag` varken görünen ad.
  ///
  /// [labels] (bkz. [buildCategoryLabelMap]) kullanıcının kategori adlarını
  /// taşır. Haritada olmayan tag'ler — otomatik hareketlerin sistem etiketleri
  /// ("Borç", "Transfer") — çevrilir, o da bilmiyorsa tag olduğu gibi gösterilir.
  String categoryLabelForTag(String tag, {Map<String, String>? labels}) =>
      labels?[tag] ?? translateSystemTag(tag);
}

/// `id → ad` haritası. Bir listenin her satırında kategori araması yapmamak
/// için sayfa seviyesinde bir kez kurulur ve aşağı geçirilir.
Map<String, String> buildCategoryLabelMap(
        Iterable<CategoryEntity> categories) =>
    {for (final c in categories) c.id: c.name};

/// Kategori kimliğinden GÖRÜNÜME giden indeks: ikon, ad ve hiyerarşi tek bir
/// şeyin parçalarıdır — aynı anahtarla (`c.id`) kurulur, birlikte yüklenir,
/// birlikte geçirilir.
typedef CategoryDisplayIndex = ({
  Map<String, IconData> icons,
  Map<String, String> labels,

  /// `id → kök id`. Toplama yapan her yüzey ("ana kategori çocuklarını kapsar")
  /// bunu kullanır; bkz. [rootIdOf].
  Map<String, String> roots,

  /// `id → "Fatura › Elektrik"`. Bağlamın ada eklenmesi gereken yerler
  /// (bildirim, CSV, seçici alt yazısı) için.
  Map<String, String> breadcrumbs,
});

/// Gider + gelir kategorilerini tek turda çeker.
///
/// Dört sayfa (işlemler, rapor, analiz, bütçeler) bu turu ayrı ayrı elle
/// yazıyordu; ikisi karakter karakter aynıydı, biri ikon yarısını atlıyordu.
Future<List<CategoryEntity>> fetchAllCategories(CategoryRepository repo) =>
    repo.getAllCategories();

/// [categories]'ten görüntüleme indeksini kurar.
CategoryDisplayIndex buildCategoryDisplayIndex(
  Iterable<CategoryEntity> categories,
) =>
    (
      icons: {
        for (final c in categories) c.id: AppIcons.getIconData(c.iconName),
      },
      labels: buildCategoryLabelMap(categories),
      roots: buildRootIndex(categories),
      breadcrumbs: buildBreadcrumbs(categories),
    );
