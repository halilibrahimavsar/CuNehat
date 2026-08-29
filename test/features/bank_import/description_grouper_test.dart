import 'package:cunehat/features/bank_import/data/description_grouper.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

ImportDraft _d(String description,
        {bool income = false, double amount = 100}) =>
    ImportDraft(
      date: DateTime(2026, 3, 5),
      description: description,
      amount: amount,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );

void main() {
  test('şube/kod farkı olan aynı marka tek grupta toplanır', () {
    final drafts = [
      _d('SOK-10419-USKUDAR'),
      _d('SOK 22133 KADIKOY'),
      _d('BILINMEYEN ISLEM'),
    ];

    final groups = groupSimilarDrafts(drafts);

    expect(groups, hasLength(1));
    expect(groups.single.indexes, [0, 1]);
    expect(groups.single.key, 'sok');
    // Etiket ekstrenin kendi yazımıyla gösterilir.
    expect(groups.single.label, 'SOK');
  });

  test('aksanlı/aksansız aynı yazım tek anahtara iner', () {
    final groups = groupSimilarDrafts([
      _d('MİGROS ÜSKÜDAR'),
      _d('MIGROS USKUDAR'),
    ]);

    expect(groups.single.indexes, [0, 1]);
  });

  test('ayrışan dal daha derine inmez: THY, Türk Telekom grubuna GİRMEZ', () {
    final drafts = [
      _d('TURK TELEKOM FATURA'),
      _d('TURK TELEKOM FATURA'),
      _d('TURK TELEKOM FATURA'),
      _d('TURK HAVA YOLLARI BILET'),
    ];

    final groups = groupSimilarDrafts(drafts);

    expect(groups, hasLength(1));
    expect(groups.single.indexes, [0, 1, 2]);
    expect(groups.single.key, startsWith('turk telekom'));
  });

  test('gelir ve gider satırları aynı grupta birleşmez', () {
    // Aynı üye işyeri hem harcama hem iade üretebilir; tek kategori
    // atanamayacağı için gruplar tür bazında ayrılır.
    final groups = groupSimilarDrafts([
      _d('MIGROS ALISVERIS'),
      _d('MIGROS ALISVERIS'),
      _d('MIGROS IADE', income: true),
      _d('MIGROS IADE', income: true),
    ]);

    expect(groups, hasLength(2));
    expect(groups.map((g) => g.isIncome).toSet(), {true, false});
  });

  test('mağaza kodu ve dekont numarası anahtara girmez', () {
    final groups = groupSimilarDrafts([
      _d('A101 3421 ISTANBUL'),
      _d('A101 88910 ANKARA'),
    ]);

    // "A101" marka adıdır (3 rakam) — elenmez; 4+ rakamlı kodlar elenir.
    expect(groups.single.key, 'a101');
  });

  test(
      'jenerik kelimeler anahtarın başına geçip ilgisiz satırları birleştirmez',
      () {
    final groups = groupSimilarDrafts([
      _d('ODEME - MIGROS TICARET AS'),
      _d('ODEME - MIGROS TICARET AS'),
      _d('ODEME - SHELL PETROL'),
      _d('ODEME - SHELL PETROL'),
    ]);

    expect(groups, hasLength(2));
    expect(groups.map((g) => g.key).toSet(), {'migros', 'shell petrol'});
  });

  test('tamamen jenerik satırlar ham kelimelerine düşer', () {
    // Eleme sonrası hiçbir kelime kalmayan satırlar boş anahtarda toplanıp
    // birbirine karışmamalı.
    final groups = groupSimilarDrafts([
      _d('ODEME ISLEMI'),
      _d('ODEME ISLEMI'),
      _d('KOMISYON TAHSILAT'),
      _d('KOMISYON TAHSILAT'),
    ]);

    expect(groups, hasLength(2));
    expect(groups.every((g) => g.key.isNotEmpty), isTrue);
  });

  test('tek satırlık küme grup sayılmaz', () {
    expect(groupSimilarDrafts([_d('TEK SATIR'), _d('BASKA SATIR')]), isEmpty);
  });

  test('scope verilince yalnız o indeksler kümelenir', () {
    final drafts = [
      _d('MIGROS 1'),
      _d('MIGROS 2'),
      _d('MIGROS 3'),
    ];

    final groups = groupSimilarDrafts(drafts, scope: [1, 2]);

    expect(groups.single.indexes, [1, 2]);
  });

  test('gruplar satır sayısına, eşitlikte tutara göre sıralanır', () {
    final groups = groupSimilarDrafts([
      _d('SHELL A', amount: 500),
      _d('SHELL B', amount: 500),
      _d('MIGROS A'),
      _d('MIGROS B'),
      _d('MIGROS C'),
      _d('OPET A', amount: 10),
      _d('OPET B', amount: 10),
    ]);

    expect(groups.map((g) => g.key).toList(), ['migros', 'shell', 'opet']);
    expect(groups.first.totalAmount, 300);
  });

  test('similarDraftIndexes satırın kendisini dışarıda bırakır', () {
    final drafts = [_d('MIGROS A'), _d('MIGROS B'), _d('SHELL')];

    expect(similarDraftIndexes(drafts, 0), [1]);
    expect(similarDraftIndexes(drafts, 2), isEmpty);
  });
  // BİLİNEN SINIR — ölçülmüş davranışı sabitler, "düzeltilmiş" sanılmasın.
  //
  // Ortak ön ek marka olmadığında ilgisiz satırlar birleşiyor. Aşağıdaki iki
  // vaka yapısal olarak AYNI; ilki istenen sonuç, ikincisi istenmeyen. Aynı
  // kod yolundan geçtikleri için biri kesilirse diğeri de kesilir — bu yüzden
  // güvenlik ağı kümelemede değil arayüzde (örnek açıklama gösterimi).
  group('bilinen sınır: ortak ön ek marka olmayabilir', () {
    test('ŞOK şubeleri DOĞRU biçimde tek grupta', () {
      final groups = groupSimilarDrafts([
        _d('SOK-10419-USKUDAR'),
        _d('SOK 22133 KADIKOY'),
      ]);

      expect(groups.single.key, 'sok');
      expect(groups.single.indexes, [0, 1]);
    });

    test('farklı markalar da aynı ilk kelimede birleşir (istenmeyen)', () {
      final groups = groupSimilarDrafts([
        _d('TURK HAVA YOLLARI BILET'),
        _d('TURK EKONOMI BANKASI KREDI'),
      ]);

      expect(groups.single.key, 'turk');
      expect(groups.single.indexes, [0, 1]);
    });

    test('ayrışan dalın artıkları da birleşir', () {
      final groups = groupSimilarDrafts([
        _d('TURK TELEKOM FATURA'),
        _d('TURK TELEKOM FATURA'),
        _d('TURK TELEKOM FATURA'),
        _d('TURK HAVA YOLLARI BILET'),
        _d('TURK EKONOMI BANKASI KREDI'),
      ]);

      expect(groups.map((g) => g.key), containsAll(['turk']));
      expect(
        groups.firstWhere((g) => g.key == 'turk').indexes,
        [3, 4],
      );
    });
  });
}
