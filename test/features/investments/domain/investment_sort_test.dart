import 'dart:ui';

import 'package:cunehat/features/investments/data/investment_sort_store.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/investment_sort.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

InvestmentEntity inv(
  String id,
  String name, {
  double value = 100,
  DateTime? added,
}) =>
    InvestmentEntity(
      id: id,
      userId: 'u',
      walletId: 'w',
      name: name,
      amount: value,
      currentValue: value,
      type: InvestmentType.custom,
      color: const Color(0xFF000000),
      dateAdded: added ?? DateTime(2026, 1, 1),
    );

void main() {
  List<String> ids(Iterable<InvestmentEntity> items) =>
      [for (final i in items) i.id!];

  final items = [
    inv('a', 'Çeyrek', value: 300, added: DateTime(2026, 3, 1)),
    inv('b', 'Altın', value: 900, added: DateTime(2026, 1, 1)),
    inv('c', 'İş Bankası', value: 50, added: DateTime(2026, 9, 1)),
  ];

  group('sortInvestments', () {
    test('değer: büyükten küçüğe', () {
      expect(
          ids(sortInvestments(items, InvestmentSort.value)), ['b', 'a', 'c']);
    });

    test('tarih: yeniden eskiye', () {
      expect(ids(sortInvestments(items, InvestmentSort.date)), ['c', 'a', 'b']);
    });

    test('ad: Türk alfabesi sırası (ç, c ile d arasında; ı, i öncesinde)', () {
      // Kod noktası sırasında 'ç' (U+00E7) 'z'den sonra gelir: "Çeyrek",
      // "İş Bankası"nın ardına düşerdi.
      expect(ids(sortInvestments(items, InvestmentSort.name)), ['b', 'a', 'c']);

      final letters = [
        inv('1', 'Zeytin'),
        inv('2', 'çay'),
        inv('3', 'Irmak'),
        inv('4', 'İnci'),
        inv('5', 'Şeker'),
        inv('6', 'Su'),
        inv('7', 'Cam'),
      ];
      expect([
        for (final i in sortInvestments(letters, InvestmentSort.name)) i.name
      ], [
        'Cam',
        'çay',
        'Irmak',
        'İnci',
        'Su',
        'Şeker',
        'Zeytin'
      ]);
    });

    test('eşitlikte sıra belirlenimlidir (ad, sonra kimlik)', () {
      final tied = [
        inv('z', 'Aynı', value: 100),
        inv('y', 'Aynı', value: 100),
        inv('x', 'Başka', value: 100),
      ];
      expect(ids(sortInvestments(tied, InvestmentSort.value)), ['y', 'z', 'x']);
      expect(ids(sortInvestments(tied.reversed, InvestmentSort.value)),
          ['y', 'z', 'x']);
    });

    test('girdi listesi değişmez', () {
      final before = ids(items);
      sortInvestments(items, InvestmentSort.value);
      expect(ids(items), before);
    });
  });

  group('InvestmentSortStore', () {
    test('kayıt yokken varsayılan: değer', () async {
      SharedPreferences.setMockInitialValues({});
      final store = InvestmentSortStore(await SharedPreferences.getInstance());
      expect(store.read(), InvestmentSort.value);
    });

    test('yazılan tercih geri okunur', () async {
      SharedPreferences.setMockInitialValues({});
      final store = InvestmentSortStore(await SharedPreferences.getInstance());
      await store.write(InvestmentSort.date);
      expect(store.read(), InvestmentSort.date);
    });

    test('bilinmeyen değer varsayılana düşer', () async {
      SharedPreferences.setMockInitialValues(
          {InvestmentSortStore.key: 'artik-yok'});
      final store = InvestmentSortStore(await SharedPreferences.getInstance());
      expect(store.read(), InvestmentSort.value);
    });
  });
}
