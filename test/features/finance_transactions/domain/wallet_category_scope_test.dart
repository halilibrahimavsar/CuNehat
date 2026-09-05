import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/wallet_category_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CategoryEntity cat(String id, {String? parentId, int sortOrder = 0}) =>
      CategoryEntity(
        id: id,
        name: id,
        iconName: 'category',
        isExpense: true,
        parentId: parentId,
        sortOrder: sortOrder,
      );

  // Fatura(Elektrik, Su) · Market(Manav)
  final all = [
    cat('fatura', sortOrder: 1),
    cat('elektrik', parentId: 'fatura', sortOrder: 1),
    cat('su', parentId: 'fatura', sortOrder: 2),
    cat('market', sortOrder: 2),
    cat('manav', parentId: 'market', sortOrder: 1),
  ];

  List<String> idsOf(Iterable<CategoryEntity> list) =>
      list.map((c) => c.id).toList();

  group('scopeCategoriesToWallet', () {
    test('küme null iken HEPSİ görünür (kürasyon yok)', () {
      // Güncelleme öncesi davranışın kendisi: alanı olmayan eski cüzdanlar
      // hiçbir şey kaybetmemeli.
      expect(
        idsOf(scopeCategoriesToWallet(all, null)),
        ['fatura', 'elektrik', 'su', 'market', 'manav'],
      );
    });

    test('boş küme GERÇEKTEN boştur (yeni doğmuş cüzdan)', () {
      // `null` ile `[]` ayrımı bu satırda yaşıyor: ikisi aynı sayılsaydı yeni
      // cüzdan yine ilk cüzdanın tüm kalemlerini devralırdı.
      expect(scopeCategoriesToWallet(all, const []), isEmpty);
    });

    test('yalnız kümedekiler, ağaç sırasında döner', () {
      expect(
        idsOf(scopeCategoriesToWallet(all, ['market', 'manav', 'fatura'])),
        ['fatura', 'market', 'manav'],
      );
    });

    test('kökü kümede olmayan ÇOCUK düşer (yetim bırakılmaz)', () {
      // `buildCategoryTree` kökü olmayan çocuğu hiçbir düğüme bağlayamaz;
      // eleme burada yapılmazsa satır listeden sessizce kaybolurdu.
      expect(idsOf(scopeCategoriesToWallet(all, ['elektrik'])), isEmpty);
    });

    test('alwaysInclude kümede olmasa da listeye girer', () {
      expect(
        idsOf(scopeCategoriesToWallet(all, ['fatura'], alwaysInclude: 'manav')),
        ['fatura', 'market', 'manav'],
      );
    });

    test('alwaysInclude bir ÇOCUKSA kökü de gelir', () {
      final result =
          scopeCategoriesToWallet(all, const [], alwaysInclude: 'elektrik');
      expect(idsOf(result), ['fatura', 'elektrik']);
    });

    test('alwaysInclude bilinmeyen kimlikse hiçbir şey eklemez', () {
      expect(
        scopeCategoriesToWallet(all, const [], alwaysInclude: 'silinmis'),
        isEmpty,
      );
    });

    test('kümedeki ölü kimlik sessizce düşer', () {
      // Silinen kategorinin kimliği kümede kalabilir; temizlik kancası
      // bilerek yok (aynı gerekçe: `RecentCategoriesService`).
      expect(
        idsOf(scopeCategoriesToWallet(all, ['fatura', 'artik-yok'])),
        ['fatura'],
      );
    });
  });

  group('isCuratedWallet', () {
    test('null → kürasyonsuz, boş liste → küratörlü', () {
      expect(isCuratedWallet(null), isFalse);
      expect(isCuratedWallet(const []), isTrue);
      expect(isCuratedWallet(['x']), isTrue);
    });
  });

  group('applyCategoryVisibility', () {
    test('kök AÇILIR: yalnız kök girer', () {
      expect(
        applyCategoryVisibility(const [], all,
            categoryId: 'fatura', visible: true),
        ['fatura'],
      );
    });

    test('çocuk AÇILIR: kökü de girer', () {
      expect(
        applyCategoryVisibility(const [], all,
            categoryId: 'elektrik', visible: true),
        ['fatura', 'elektrik'],
      );
    });

    test('kök KAPANIR: alt ağacın tamamı çıkar', () {
      // Yalnız kök çıkarılsaydı geride kökü olmayan çocuklar kalır ve ağaç
      // kurulamazdı.
      expect(
        applyCategoryVisibility(
          ['fatura', 'elektrik', 'su', 'market'],
          all,
          categoryId: 'fatura',
          visible: false,
        ),
        ['market'],
      );
    });

    test('çocuk KAPANIR: yalnız kendisi çıkar, kök kalır', () {
      expect(
        applyCategoryVisibility(
          ['fatura', 'elektrik', 'su'],
          all,
          categoryId: 'elektrik',
          visible: false,
        ),
        ['fatura', 'su'],
      );
    });

    test('zaten kümede olan kimlik İKİ KEZ eklenmez', () {
      expect(
        applyCategoryVisibility(['fatura'], all,
            categoryId: 'fatura', visible: true),
        ['fatura'],
      );
    });

    test('bilinmeyen kimlik kümeyi değiştirmez', () {
      expect(
        applyCategoryVisibility(['fatura'], all,
            categoryId: 'yok', visible: true),
        ['fatura'],
      );
    });

    test('girdi listesi DEĞİŞTİRİLMEZ', () {
      final current = ['fatura'];
      applyCategoryVisibility(current, all,
          categoryId: 'market', visible: true);
      expect(current, ['fatura']);
    });
  });

  group('includeCategories', () {
    test('çoklu ekleme köklerle birlikte, sırayı koruyarak birikir', () {
      expect(
        includeCategories(const [], all, ['manav', 'elektrik']),
        ['market', 'manav', 'fatura', 'elektrik'],
      );
    });

    test('var olanları tekrarlamaz', () {
      expect(
        includeCategories(['fatura'], all, ['fatura', 'elektrik']),
        ['fatura', 'elektrik'],
      );
    });
  });

  group('needsCategorySetup', () {
    test('küratörlü cüzdan: küme boşsa paket önerilir', () {
      expect(
        needsCategorySetup(visibleIds: const [], anyCategoryExists: true),
        isTrue,
      );
    });

    test('küratörlü cüzdan: kümede kalem varsa önerilmez', () {
      expect(
        needsCategorySetup(visibleIds: ['fatura'], anyCategoryExists: true),
        isFalse,
      );
    });

    test('kürasyonsuz cüzdan: ESKİ davranış — yalnız hiç kategori yoksa', () {
      // Güncelleme öncesinden kalan cüzdanlar zaten hepsini görüyor; onlara
      // paket önermek kurulu listeyi ikinci kez sormak olurdu.
      expect(
        needsCategorySetup(visibleIds: null, anyCategoryExists: true),
        isFalse,
      );
      expect(
        needsCategorySetup(visibleIds: null, anyCategoryExists: false),
        isTrue,
      );
    });

    test('İKİNCİ CÜZDAN senaryosu: kategoriler var ama küme boş → önerilir',
        () {
      // Bildirilen davranışın kendisi: eskiden küresel `isEmpty` kapısı
      // yüzünden burada paket HİÇ sorulmuyordu.
      expect(
        needsCategorySetup(visibleIds: const [], anyCategoryExists: true),
        isTrue,
      );
    });
  });
}
