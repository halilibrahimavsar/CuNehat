import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kimlik artık UUID; eşleşme ADA göre yapılır. Test kimliği okunur tutmak
/// için `id-<ad>` biçiminde üretir.
CategoryEntity _cat(String name, {bool isExpense = true}) => CategoryEntity(
      id: 'id-$name',
      name: name,
      iconName: 'x',
      isExpense: isExpense,
    );

ImportDraft _draft(String desc, {bool income = false}) => ImportDraft(
      date: DateTime(2026, 3, 25),
      description: desc,
      amount: 10,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );

void main() {
  final guesser = CategoryGuesser();

  // Sabit liste yerine GERÇEK başlangıç paketi: tahmin grupları paketteki
  // adlarla eşleşmek zorunda, elle kopyalanan liste sessizce kayıyordu.
  // (Paket ↔ sözlük bağı ayrıca `category_starter_pack_test.dart`te kilitli.)
  final defaultExpenseCats = <CategoryEntity>[
    for (final g in CategoryStarterPack.expense) ...[
      _cat(g.name),
      for (final c in g.children) _cat(c.name),
    ],
  ];
  final defaultIncomeCats = <CategoryEntity>[
    for (final g in CategoryStarterPack.income) ...[
      _cat(g.name, isExpense: false),
      for (final c in g.children) _cat(c.name, isExpense: false),
    ],
  ];

  test('bilinen market zinciri Market kategorisine eşlenir', () {
    // Market (gıda) ile Alışveriş (giyim/elektronik) bilerek ayrı gruplar.
    final result = guesser.guess(
      description: '5411 MIGROS TIC.A.S. ISTANBUL TR',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Market');
  });

  test('akaryakıt markası Ulaşım kategorisine eşlenir', () {
    final result = guesser.guess(
      description: 'SHELL PETROL ISTASYONU',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Ulaşım');
  });

  test('yemek servisi markası Yemek kategorisine eşlenir', () {
    final result = guesser.guess(
      description: 'YEMEKSEPETI*SIPARIS',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Yemek');
  });

  test('maaş açıklaması gelir tarafında Maaş kategorisine eşlenir', () {
    final result = guesser.guess(
      description: 'TEMMUZ MAAS ODEMESI',
      isIncome: true,
      candidates: defaultIncomeCats,
    );
    expect(result, 'id-Maaş');
  });

  test(
      'tahmin edilen kategori kullanıcı listesinde yoksa null döner (fuzzy düşme yok)',
      () {
    final withoutAlisveris = [_cat('Yemek'), _cat('Fatura')];
    final result = guesser.guess(
      description: 'MIGROS TIC.A.S.',
      isIncome: false,
      candidates: withoutAlisveris,
    );
    expect(result, isNull);
  });

  test('bilinmeyen açıklama null döner', () {
    final result = guesser.guess(
      description: 'HAVALE GELEN EFT REF 123456',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, isNull);
  });

  test('gelir anahtar kelimesi gider tarafında eşleşmez (gruplar ayrı)', () {
    final result = guesser.guess(
      description: 'MAAS ODEMESI',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, isNull);
  });

  test('gider anahtar kelimesi gelir tarafında eşleşmez (gruplar ayrı)', () {
    final result = guesser.guess(
      description: 'MIGROS TIC.A.S.',
      isIncome: true,
      candidates: defaultIncomeCats,
    );
    expect(result, isNull);
  });

  test('Türkçe karakter ve büyük/küçük harf duyarsız eşleşir', () {
    final result = guesser.guess(
      description: 'BİM MARKET ŞUBESİ',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Market');
  });

  test('kısa anahtar kelime kelime-sınırı olmadan yanlışlıkla eşleşmez', () {
    // "kabimli" içinde "bim" geçiyor ama kelime sınırında değil.
    final result = guesser.guess(
      description: 'Kabimli ödeme yapıldı',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, isNull);
  });

  test('boş açıklama null döner', () {
    final result = guesser.guess(
      description: '',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, isNull);
  });

  // --- Gerçek Akbank ekstre örneği (bkz. akbank_pdf_parser_test.dart) ---
  // REGRESYON: kullanıcının canlı testinde bu satırların çoğu eşleşmiyordu.

  test('REGRESYON: POS satışında bitişik marka adı (jenerik "market") eşleşir',
      () {
    final result = guesser.guess(
      description: '000000003598401-DEMIR MARKET ISTANBUL TR Pos satış.',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Market');
  });

  test(
      'REGRESYON: jenerik "petrol" akaryakıt zinciri olmayan istasyonu da yakalar',
      () {
    final result = guesser.guess(
      description: '000000000269480-DEMKAR PETROL ISTANBUL TR Pos satış.',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Ulaşım');
  });

  test(
      'REGRESYON: mağaza koduna tire ile bitişik marka adı (SOK-10419) eşleşir',
      () {
    final result = guesser.guess(
      description:
          '0000000002419511-SOK-10419-USKUDAR YU ISTANBUL TR Pos satış.',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Market');
  });

  test('Midas Menkul Değerler transferi Yatırım grubuna düşer (kategori varsa)',
      () {
    final result = guesser.guess(
      description:
          'MB Transfer İşlemleri - Alıcı:Midas Menkul Değerler Anonim Şirketi-KA44QAPE4U',
      isIncome: false,
      candidates: [...defaultExpenseCats, _cat('Yatırım')],
    );
    expect(result, 'id-Yatırım');
  });

  test('grubun karşılığı kullanıcının listesinde yoksa null döner', () {
    // Tahmin ancak açıklamada anahtar kelime VE kullanıcıda o adda bir
    // kategori varken döner; kullanıcı kategoriyi silmişse sessizce boş kalır.
    final result = guesser.guess(
      description:
          'MB Transfer İşlemleri - Alıcı:Midas Menkul Değerler Anonim Şirketi-KA44QAPE4U',
      isIncome: false,
      candidates: defaultExpenseCats.where((c) => c.name != 'Yatırım').toList(),
    );
    expect(result, isNull);
  });

  test('eczane açıklaması Sağlık grubuna düşer (kategori varsa)', () {
    final result = guesser.guess(
      description: 'ECZANESI ISTANBUL TR Pos satış.',
      isIncome: false,
      candidates: [...defaultExpenseCats, _cat('Sağlık')],
    );
    expect(result, 'id-Sağlık');
  });

  group('suggestNewCategories', () {
    test('yalnız kullanıcının listesinde OLMAYAN gruplar önerilir', () {
      final drafts = [
        _draft('5411 MIGROS TIC.A.S.'), // Market zaten var → önerilmez
        _draft(
            'MB Transfer İşlemleri - Alıcı:Midas Menkul Değerler Anonim Şirketi'),
      ];
      final suggestions = guesser.suggestNewCategories(
        drafts: drafts,
        // Kullanıcı 'Yatırım'ı silmiş, 'Market' duruyor.
        expenseCategories:
            defaultExpenseCats.where((c) => c.name != 'Yatırım').toList(),
        incomeCategories: defaultIncomeCats,
      );
      expect(suggestions.map((s) => s.name), ['Yatırım']);
      expect(suggestions.single.isIncome, isFalse);
    });

    test('eşleşen grup yoksa boş liste döner', () {
      final drafts = [_draft('HAVALE GELEN EFT REF 123456')];
      final suggestions = guesser.suggestNewCategories(
        drafts: drafts,
        expenseCategories: defaultExpenseCats,
        incomeCategories: defaultIncomeCats,
      );
      expect(suggestions, isEmpty);
    });

    test(
        'aynı grup birden çok taslakta eşleşse de tek öneri döner (tekilleştirme)',
        () {
      final drafts = [
        _draft('MIDAS MENKUL DEGERLER'),
        _draft('BORSA ISTANBUL ODEMESI'),
      ];
      final suggestions = guesser.suggestNewCategories(
        drafts: drafts,
        // Kullanıcı 'Yatırım'ı silmiş: iki taslak da aynı gruba düşer ama
        // tek öneri üretilmeli.
        expenseCategories:
            defaultExpenseCats.where((c) => c.name != 'Yatırım').toList(),
        incomeCategories: defaultIncomeCats,
      );
      expect(suggestions.length, 1);
      expect(suggestions.single.name, 'Yatırım');
    });

    test('gelir tarafında karşılığı olmayan grup isIncome:true olarak önerilir',
        () {
      // Varsayılan gelir listesinde zaten "Maaş" var; karşılığı olmayan bir
      // gelir grubu senaryosu için doğrudan boş gelir listesiyle test edilir.
      final suggestions = guesser.suggestNewCategories(
        drafts: [_draft('TEMMUZ MAAS ODEMESI', income: true)],
        expenseCategories: defaultExpenseCats,
        incomeCategories: const [],
      );
      expect(suggestions.single.name, 'Maaş');
      expect(suggestions.single.isIncome, isTrue);
    });
  });
}
