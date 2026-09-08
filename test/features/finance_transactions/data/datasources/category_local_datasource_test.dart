import 'dart:io';

import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockHiveInterface extends Mock implements HiveInterface {}

/// Kategorilerin kalıcı deposu — bu dosyaya kadar KENDİ testi yoktu, yalnız
/// repo ve yedek servisi üzerinden dolaylı deneniyordu.
///
/// Katman ince ama iki şeyi garanti etmek zorunda: kimlik ANAHTARDIR (aynı
/// kimlikle yazmak kopya üretmemeli — kategori yeniden adlandırma tam olarak
/// bunu yapıyor) ve her hata yolu `CacheException`a çevrilmeli. İkincisi
/// çağıranlar için sözleşme: depo `Either` DEĞİL exception fırlatır ve
/// `GetBudgetsUsecase` bunu açıkça yakalamak zorunda kalmıştı.
void main() {
  late Directory dir;
  late CategoryLocalDataSource dataSource;

  CategoryModel category({
    String id = 'c1',
    String name = 'Market',
    String? parentId,
    bool isExpense = true,
    int sortOrder = 0,
  }) =>
      CategoryModel(
        id: id,
        name: name,
        iconName: 'shopping_cart',
        isExpense: isExpense,
        parentId: parentId,
        sortOrder: sortOrder,
      );

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('cunehat_category_ds');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
  });

  setUp(() async {
    dataSource = CategoryLocalDataSource(Hive);
    if (Hive.isBoxOpen(CategoryLocalDataSource.boxName)) {
      await Hive.box<CategoryModel>(CategoryLocalDataSource.boxName).clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('okuma', () {
    test('boş kutu BOŞ liste döner (hata değil)', () async {
      expect(await dataSource.getAll(), isEmpty);
    });

    test('getAll GELİR ve GİDER kategorilerinin İKİSİNİ de döner', () async {
      // Süzme çağıranın işi; depo tek gerçek kaynak olarak hepsini verir.
      await dataSource.put(category(id: 'c1'));
      await dataSource.put(category(id: 'c2', name: 'Maaş', isExpense: false));

      final all = await dataSource.getAll();

      expect(all.map((c) => c.id).toSet(), {'c1', 'c2'});
    });

    test('alt kategoriler de düz listede gelir (ağaç çağıranda kurulur)',
        () async {
      await dataSource.put(category(id: 'p'));
      await dataSource.put(category(id: 'ch', name: 'Süt', parentId: 'p'));

      final all = await dataSource.getAll();

      expect(all, hasLength(2));
      expect(all.firstWhere((c) => c.id == 'ch').parentId, 'p');
    });
  });

  group('yazma', () {
    test('put AYNI kimlikle üzerine yazar — yeniden adlandırma kopya üretmez',
        () async {
      // Kimlik sabit, ad değişir: `id` adın kendisi olduğu dönemde yeniden
      // adlandırma yeni bir kayıt üretiyordu.
      await dataSource.put(category(id: 'c1', name: 'Market'));
      await dataSource.put(category(id: 'c1', name: 'Alışveriş'));

      final all = await dataSource.getAll();

      expect(all, hasLength(1));
      expect(all.single.name, 'Alışveriş');
    });

    test('putAll TEK yazımda hepsini ekler (başlangıç paketi / geri yükleme)',
        () async {
      await dataSource.putAll([
        category(id: 'c1'),
        category(id: 'c2', name: 'Fatura'),
        category(id: 'c3', name: 'Ulaşım'),
      ]);

      expect((await dataSource.getAll()).map((c) => c.id).toSet(),
          {'c1', 'c2', 'c3'});
    });

    test('putAll aynı kimliklerle çağrılınca İDEMPOTENTTİR', () async {
      // Başlangıç paketi iki kez kurulursa kategoriler ikiye katlanmamalı.
      final pack = [category(id: 'c1'), category(id: 'c2', name: 'Fatura')];
      await dataSource.putAll(pack);
      await dataSource.putAll(pack);

      expect(await dataSource.getAll(), hasLength(2));
    });

    test('boş putAll hiçbir şey yapmaz', () async {
      await dataSource.putAll(const []);
      expect(await dataSource.getAll(), isEmpty);
    });
  });

  group('silme', () {
    test('deleteAll yalnız verilen kimlikleri siler', () async {
      await dataSource.putAll([
        category(id: 'c1'),
        category(id: 'c2', name: 'Fatura'),
        category(id: 'c3', name: 'Ulaşım'),
      ]);

      await dataSource.deleteAll(['c1', 'c3']);

      expect((await dataSource.getAll()).map((c) => c.id), ['c2']);
    });

    test('olmayan kimlikleri silmek sessizce geçer', () async {
      await dataSource.put(category(id: 'c1'));
      await dataSource.deleteAll(['yok', 'hic']);
      expect(await dataSource.getAll(), hasLength(1));
    });

    test('clear kutuyu tamamen boşaltır', () async {
      await dataSource.putAll([category(id: 'c1'), category(id: 'c2')]);

      await dataSource.clear();

      expect(await dataSource.getAll(), isEmpty);
    });
  });

  group('hata yolu CacheException e çevrilir', () {
    late CategoryLocalDataSource failing;

    setUp(() {
      final hive = MockHiveInterface();
      when(() => hive.isBoxOpen(any())).thenReturn(false);
      when(() => hive.openBox<CategoryModel>(any()))
          .thenThrow(Exception('disk yok'));
      failing = CategoryLocalDataSource(hive);
    });

    test('getAll', () {
      expect(failing.getAll, throwsA(isA<CacheException>()));
    });

    test('put', () {
      expect(() => failing.put(category()), throwsA(isA<CacheException>()));
    });

    test('putAll', () {
      expect(
          () => failing.putAll([category()]), throwsA(isA<CacheException>()));
    });

    test('deleteAll', () {
      expect(() => failing.deleteAll(['c1']), throwsA(isA<CacheException>()));
    });

    test('clear', () {
      expect(failing.clear, throwsA(isA<CacheException>()));
    });
  });
}
