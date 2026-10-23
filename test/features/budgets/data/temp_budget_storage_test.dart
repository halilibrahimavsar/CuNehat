import 'dart:io';

import 'package:cunehat/features/budgets/data/datasources/local/temp_budget_local_datasource.dart';
import 'package:cunehat/features/budgets/data/models/temp_budget_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory dir;
  late TempBudgetLocalDataSource source;

  TempBudgetModel model(String id,
          {String walletId = 'w', List<String> cats = const ['a', 'b']}) =>
      TempBudgetModel(
        id: id,
        walletId: walletId,
        name: 'Tatil $id',
        limitAmount: 1500.5,
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 20),
        categoryIds: cats,
      );

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('cunehat_temp_budget_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(TempBudgetModelAdapter());
    }
  });

  setUp(() async {
    source = TempBudgetLocalDataSource(Hive);
    if (Hive.isBoxOpen(TempBudgetLocalDataSource.boxName)) {
      await Hive.box<TempBudgetModel>(TempBudgetLocalDataSource.boxName)
          .clear();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('typeId 19 — CLAUDE.md kaydıyla aynı', () {
    expect(TempBudgetModelAdapter().typeId, 19);
  });

  test('Hive gidiş-dönüşü tüm alanları korur', () async {
    await source.put(model('x'));
    await Hive.box<TempBudgetModel>(TempBudgetLocalDataSource.boxName).close();

    final back = (await source.getById('x'))!;
    expect(back.name, 'Tatil x');
    expect(back.limitAmount, 1500.5);
    expect(back.startDate, DateTime(2026, 11, 10));
    expect(back.endDate, DateTime(2026, 11, 20));
    expect(back.categoryIds, ['a', 'b']);
  });

  test('JSON gidiş-dönüşü; eksik alan GÜRÜLTÜYLE düşer', () {
    final json = model('x').toJson();
    final back = TempBudgetModel.fromJson(json);
    expect(back.toJson(), json);

    expect(() => TempBudgetModel.fromJson({...json}..remove('categoryIds')),
        throwsA(isA<TypeError>()));
    expect(() => TempBudgetModel.fromJson({...json, 'limitAmount': '10'}),
        throwsA(isA<TypeError>()));
  });

  test('cüzdan silinince yalnız o cüzdanın bütçeleri gider', () async {
    await source.put(model('a', walletId: 'w1'));
    await source.put(model('b', walletId: 'w2'));

    await source.deleteForWallet('w1');

    expect((await source.getAll()).map((m) => m.id), ['b']);
  });

  test('kategori silinince listeden düşer; boşalan bütçe silinir', () async {
    await source.put(model('two', cats: ['a', 'b']));
    await source.put(model('one', cats: ['a']));
    await source.put(model('other', cats: ['c']));

    await source.removeCategory('a');

    final all = {for (final m in await source.getAll()) m.id: m};
    expect(all.keys, unorderedEquals(['two', 'other']));
    expect(all['two']!.categoryIds, ['b']);
    expect(all['two']!.name, 'Tatil two');
    expect(all['other']!.categoryIds, ['c']);
  });
  // QA O2: kategorinin işlemleri başka kategoriye taşınınca tek seferlik
  // bütçe o kategoriyi saymaya devam eder — sessizce silinmez, biten
  // bütçenin sonucu geriye dönük değişmez.
  test(
      'işlemler taşınarak silinince yerini hedef alır; tek kategorili bütçe '
      'silinmez; hedef zaten varsa ikinci kez eklenmez', () async {
    await source.put(model('trip', cats: ['seyahat', 'yeme']));
    await source.put(model('one', cats: ['seyahat']));
    await source.put(model('dup', cats: ['seyahat', 'diger']));

    await source.removeCategory('seyahat', replacementId: 'diger');

    final all = {for (final m in await source.getAll()) m.id: m};
    expect(all.keys, unorderedEquals(['trip', 'one', 'dup']));
    expect(all['trip']!.categoryIds, ['diger', 'yeme']);
    expect(all['one']!.categoryIds, ['diger']);
    expect(all['dup']!.categoryIds, ['diger']);
    expect(all['trip']!.limitAmount, 1500.5);
  });
}
