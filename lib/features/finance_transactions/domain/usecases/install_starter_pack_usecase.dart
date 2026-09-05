import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/l10n/category_seed_names.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:injectable/injectable.dart';

/// Kullanıcının başlangıç paketinden seçtiği gruplar.
typedef StarterPackSelection = ({StarterPackGroup group, bool isExpense});

/// Kurulumun sonucu.
///
/// İki sayı AYRI çünkü iki farklı şey oldu: [created] yeni kategori KAYDI
/// yazıldı, [attached] var olan bir kategori bu cüzdanda görünür oldu. İkinci
/// cüzdanını kuran kullanıcı çoğunlukla `created: 0, attached: 41` alır —
/// "0 kategori oluşturuldu" demek doğru ama işe yaramaz bir cevap olurdu.
typedef StarterPackInstallResult = ({int created, int attached});

/// Seçilen öneri gruplarını gerçek kategoriye çevirir ve [walletId] cüzdanında
/// görünür yapar.
///
/// Kurulan kayıtlar hiçbir "varsayılan" bayrağı taşımaz — kullanıcının kendi
/// kategorileridir, düzenlenebilir ve silinebilirler. Tek yazımda eklenir ki
/// yarım kurulmuş bir ağaç kalmasın.
@injectable
class InstallStarterPackUseCase {
  final CategoryRepository repository;
  final WalletCategoryService walletCategories;

  InstallStarterPackUseCase(this.repository, this.walletCategories);

  /// EKSİK olanları kurar, seçimin tamamını [walletId] cüzdanına bağlar.
  ///
  /// [languageCode] paketteki anahtarların hangi dilde ADA çevrileceğini
  /// belirler. Kurulan ad kullanıcı verisidir: sonradan dil değişse de
  /// değişmez — kullanıcının kendi yazdığı bir ad neyse o.
  ///
  /// Zaten var olan adlar YENİDEN OLUŞTURULMAZ, cüzdana BAĞLANIR. Kategoriler
  /// küresel kayıtlar olduğu için ikinci cüzdanda "Fatura"yı seçmek yeni bir
  /// Fatura yaratmaz; aynı kimliği o cüzdanda da görünür yapar. Aksi halde
  /// aynı ada sahip iki ayrı kimlik çıkar ve rapor/CSV ikiye bölünürdü.
  Future<StarterPackInstallResult> call(
    Iterable<StarterPackSelection> selections, {
    required String languageCode,
    required String walletId,
  }) async {
    final existing = await repository.getAllCategories();
    final entities = <CategoryEntity>[];

    /// Seçimin çözüldüğü kimlikler — yeni yaratılan da, zaten var olan da.
    /// Cüzdanın görünürlük kümesine girecek liste budur.
    final touched = <String>[];

    CategoryEntity? find(String name,
        {required bool isExpense, String? parentId}) {
      final target = normalizeCategoryName(name);
      bool matches(CategoryEntity c) =>
          c.isExpense == isExpense &&
          c.parentId == parentId &&
          normalizeCategoryName(c.name) == target;
      return existing.where(matches).firstOrNull ??
          entities.where(matches).firstOrNull;
    }

    // Sıra numarası tür başına ayrı ilerler: sortOrder kardeş kapsamlıdır,
    // gelir ve gider ayrı ad uzaylarıdır. Mevcut kayıtların ardından devam
    // edilir ki eklenenler listenin sonuna insin.
    final rootOrder = <bool, int>{
      for (final isExpense in [true, false])
        isExpense: existing
            .where((c) => c.isExpense == isExpense && c.isRoot)
            .fold<int>(0, (max, c) => c.sortOrder > max ? c.sortOrder : max),
    };

    for (final selection in selections) {
      final group = selection.group;
      final isExpense = selection.isExpense;

      // Kök zaten varsa çocuklar ONUN altına eklenir; yeni bir ikiz kök
      // yaratmak "Fatura" adlı iki ana kategori demek olurdu.
      final groupName = categorySeedName(group.key, languageCode);
      final existingRoot = find(groupName, isExpense: isExpense);

      final String rootId;
      if (existingRoot != null) {
        rootId = existingRoot.id;
      } else {
        rootId = UidGenerator.generateV7();
        entities.add(CategoryEntity(
          id: rootId,
          name: groupName,
          iconName: group.iconName,
          isExpense: isExpense,
          sortOrder: rootOrder[isExpense] = rootOrder[isExpense]! + 1,
        ));
      }
      touched.add(rootId);

      var childOrder = 0;
      for (final child in group.children) {
        childOrder++;
        final childName = categorySeedName(child.key, languageCode);
        final existingChild =
            find(childName, isExpense: isExpense, parentId: rootId);
        if (existingChild != null) {
          touched.add(existingChild.id);
          continue;
        }
        final childId = UidGenerator.generateV7();
        entities.add(CategoryEntity(
          id: childId,
          name: childName,
          iconName: child.iconName,
          isExpense: isExpense,
          parentId: rootId,
          sortOrder: childOrder,
        ));
        touched.add(childId);
      }
    }

    // Kayıt önce yazılır: görünürlük kümesi var olmayan bir kimliği
    // gösteremez ve `includeCategories` kökü kümeye katmak için kaydı okur.
    if (entities.isNotEmpty) await repository.addAll(entities);
    if (touched.isEmpty) return (created: 0, attached: 0);

    final attached = await walletCategories.include(
      walletId: walletId,
      categoryIds: touched,
    );
    return (created: entities.length, attached: attached);
  }
}
