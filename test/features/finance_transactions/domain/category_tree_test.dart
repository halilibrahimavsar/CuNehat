import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CategoryEntity cat(
    String id,
    String name, {
    String? parentId,
    bool isExpense = true,
    int sortOrder = 0,
  }) =>
      CategoryEntity(
        id: id,
        name: name,
        iconName: 'category',
        isExpense: isExpense,
        parentId: parentId,
        sortOrder: sortOrder,
      );

  // Fatura(Elektrik, Doğalgaz) · Konut(Su) · Market
  final fatura = cat('f', 'Fatura', sortOrder: 1);
  final elektrik = cat('f-e', 'Elektrik', parentId: 'f', sortOrder: 1);
  final dogalgaz = cat('f-d', 'Doğalgaz', parentId: 'f', sortOrder: 2);
  final konut = cat('k', 'Konut', sortOrder: 2);
  final konutSu = cat('k-s', 'Su', parentId: 'k', sortOrder: 1);
  final market = cat('m', 'Market', sortOrder: 3);
  final all = [elektrik, konut, fatura, market, dogalgaz, konutSu];

  group('normalizeCategoryName', () {
    test('Türkçe büyük harfleri katlar', () {
      // toLowerCase() tek başına 'İ'yi 'i̇' (i + birleşen nokta) yapar ve
      // 'i' ile eşleşmez.
      expect(
          normalizeCategoryName('İNTERNET'), normalizeCategoryName('internet'));
      expect(normalizeCategoryName('IŞIK'), normalizeCategoryName('ışık'));
      expect(normalizeCategoryName('ÇÖĞÜŞ'), normalizeCategoryName('çöğüş'));
    });

    test('kırpar ve iç boşlukları tekler', () {
      expect(normalizeCategoryName('  Ev   Eşyası '), 'ev eşyası');
    });
  });

  group('buildCategoryTree', () {
    test('kökleri sortOrder sırasında, altlarında çocuklarıyla verir', () {
      final tree = buildCategoryTree(all);

      expect(tree.map((n) => n.category.name), ['Fatura', 'Konut', 'Market']);
      expect(tree[0].children.map((c) => c.name), ['Elektrik', 'Doğalgaz']);
      expect(tree[1].children.map((c) => c.name), ['Su']);
      expect(tree[2].children, isEmpty);
    });

    test('flattenTree ana kategoriden hemen sonra çocuklarını sıralar', () {
      expect(
        flattenTree(all).map((c) => c.name),
        ['Fatura', 'Elektrik', 'Doğalgaz', 'Konut', 'Su', 'Market'],
      );
    });
  });

  group('rootIdOf', () {
    final index = buildRootIndex(all);

    test('alt kategori kökünü, ana kategori kendini gösterir', () {
      expect(rootIdOf('f-e', index), 'f');
      expect(rootIdOf('f', index), 'f');
    });

    test('bilinmeyen tag KENDİNİ döner', () {
      // Otomatik hareketlerin sistem etiketleri ("Borç", "Transfer") hiçbir
      // kategoriye ait değildir ve raporda kendi kalemleri olarak durmalıdır.
      expect(rootIdOf('Borç', index), 'Borç');
      expect(rootIdOf('silinmiş-kimlik', index), 'silinmiş-kimlik');
    });
  });

  group('subtreeIds', () {
    test('ana kategori kendisini ve çocuklarını kapsar', () {
      expect(subtreeIds('f', all), {'f', 'f-e', 'f-d'});
    });

    test('alt kategori yalnız kendisidir', () {
      expect(subtreeIds('f-e', all), {'f-e'});
    });

    test('çocuksuz ana kategori yalnız kendisidir', () {
      expect(subtreeIds('m', all), {'m'});
    });
  });

  test('buildBreadcrumbs alt kategoriye ana kategorisini ekler', () {
    final crumbs = buildBreadcrumbs(all);
    expect(crumbs['f-e'], 'Fatura › Elektrik');
    expect(crumbs['f'], 'Fatura');
  });

  group('validateCategory', () {
    test('boş ad reddedilir', () {
      expect(
        validateCategory(cat('x', '   '), all),
        CategoryValidationError.emptyName,
      );
    });

    test('AYNI ana kategori altında aynı ad reddedilir', () {
      expect(
        validateCategory(cat('x', 'Elektrik', parentId: 'f'), all),
        CategoryValidationError.duplicateSiblingName,
      );
    });

    test('FARKLI ana kategoriler altında aynı ad kabul edilir', () {
      // Hiyerarşinin asıl gerekçesi: "Fatura › Su" ile "Konut › Su" birlikte
      // yaşayabilmeli. Ad kimlik olsaydı ikincisi çakışmadan reddedilirdi.
      expect(validateCategory(cat('x', 'Su', parentId: 'f'), all), isNull);
    });

    test('kökte aynı ad reddedilir, ad karşılaştırması Türkçe-duyarlı', () {
      expect(
        validateCategory(cat('x', 'market', sortOrder: 9), all),
        CategoryValidationError.duplicateSiblingName,
      );
    });

    test('kök ile alt kategori aynı adı taşıyabilir', () {
      // Farklı kardeş kümeleri: kökteki "Su" ile "Konut › Su" çakışmaz.
      expect(validateCategory(cat('x', 'Su', sortOrder: 9), all), isNull);
    });

    test('kendini düzenlerken kendi adıyla çakışmaz', () {
      expect(
          validateCategory(elektrik.copyWith(iconName: 'bolt'), all), isNull);
    });

    test('DERİNLİK 2: alt kategorinin altına kategori eklenemez', () {
      expect(
        validateCategory(cat('x', 'Sayaç', parentId: 'f-e'), all),
        CategoryValidationError.parentIsNotRoot,
      );
    });

    test('çocuğu olan kategori alt kategoriye taşınamaz', () {
      expect(
        validateCategory(fatura.copyWith(parentId: 'k'), all),
        CategoryValidationError.parentHasChildren,
      );
    });

    test('çocuksuz kök alt kategoriye taşınabilir', () {
      expect(validateCategory(market.copyWith(parentId: 'k'), all), isNull);
    });

    test('tür uyuşmazlığı reddedilir', () {
      final gelir = cat('g', 'Maaş', isExpense: false);
      expect(
        validateCategory(
            cat('x', 'Prim', parentId: 'f', isExpense: false), [...all, gelir]),
        CategoryValidationError.typeMismatch,
      );
    });

    test('gelir ve gider AYRI ad uzaylarıdır', () {
      expect(
        validateCategory(cat('x', 'Market', isExpense: false), all),
        isNull,
      );
    });

    test('kategori kendi üst kategorisi olamaz', () {
      expect(
        validateCategory(market.copyWith(parentId: 'm'), all),
        CategoryValidationError.selfParent,
      );
    });

    test('olmayan üst kategori reddedilir', () {
      expect(
        validateCategory(cat('x', 'Yeni', parentId: 'yok'), all),
        CategoryValidationError.parentNotFound,
      );
    });
  });
}
