import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/l10n/category_seed_names.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:injectable/injectable.dart';

/// Kullanıcının başlangıç paketinden seçtiği gruplar.
typedef StarterPackSelection = ({StarterPackGroup group, bool isExpense});

/// Seçilen öneri gruplarını gerçek kategoriye çevirir.
///
/// Kurulan kayıtlar hiçbir "varsayılan" bayrağı taşımaz — kullanıcının kendi
/// kategorileridir, düzenlenebilir ve silinebilirler. Tek yazımda eklenir ki
/// yarım kurulmuş bir ağaç kalmasın.
@injectable
class InstallStarterPackUseCase {
  final CategoryRepository repository;

  InstallStarterPackUseCase(this.repository);

  /// EKSİK olanları kurar; kurulan kategori sayısını (ana + alt) döner.
  ///
  /// [languageCode] paketteki anahtarların hangi dilde ADA çevrileceğini
  /// belirler. Kurulan ad kullanıcı verisidir: sonradan dil değişse de
  /// değişmez — kullanıcının kendi yazdığı bir ad neyse o.
  ///
  /// Zaten var olan adlar atlanır — paket yarı dolu bir kurulumdan yeniden
  /// çalıştırılabilmeli. Tek bir çakışma tüm partiyi düşürseydi ("Maaş" duran
  /// bir cüzdanda öneri setine dönmek) hiçbir şey kurulmazdı, çünkü
  /// `addAll` partiyi bütün olarak doğrular.
  Future<int> call(
    Iterable<StarterPackSelection> selections, {
    required String languageCode,
  }) async {
    final existing = await repository.getAllCategories();
    final entities = <CategoryEntity>[];

    bool taken(String name, {required bool isExpense, String? parentId}) {
      final target = normalizeCategoryName(name);
      bool matches(CategoryEntity c) =>
          c.isExpense == isExpense &&
          c.parentId == parentId &&
          normalizeCategoryName(c.name) == target;
      return existing.any(matches) || entities.any(matches);
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
      final existingRoot = existing
          .where((c) =>
              c.isRoot &&
              c.isExpense == isExpense &&
              normalizeCategoryName(c.name) == normalizeCategoryName(groupName))
          .firstOrNull;

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

      var childOrder = 0;
      for (final child in group.children) {
        childOrder++;
        final childName = categorySeedName(child.key, languageCode);
        if (taken(childName, isExpense: isExpense, parentId: rootId)) continue;
        entities.add(CategoryEntity(
          id: UidGenerator.generateV7(),
          name: childName,
          iconName: child.iconName,
          isExpense: isExpense,
          parentId: rootId,
          sortOrder: childOrder,
        ));
      }
    }

    if (entities.isEmpty) return 0;
    await repository.addAll(entities);
    return entities.length;
  }
}
