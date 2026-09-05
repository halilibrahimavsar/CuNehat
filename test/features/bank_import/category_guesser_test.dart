import 'package:cunehat/core/l10n/category_seed_names.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kimlik artık UUID; eşleşme ADA göre yapılır. Test kimliği okunur tutmak
/// için `id-<ad>` biçiminde üretir.
CategoryEntity _cat(String name, {bool isExpense = true, String? parent}) =>
    CategoryEntity(
      id: 'id-$name',
      name: name,
      iconName: 'x',
      isExpense: isExpense,
      parentId: parent == null ? null : 'id-$parent',
    );

/// Paket anahtarının Türkçe adı. Testin beklentileri okunur kalsın diye:
/// kullanıcının kategorisi ADI taşır, anahtarı değil.
String _tr(String key) => categorySeedName(key, 'tr');

/// Aynısının İngilizcesi — dil değişiminin eşleşmeyi koparmadığını ölçer.
String _en(String key) => categorySeedName(key, 'en');

ImportDraft _draft(String desc, {bool income = false, String? sourceTag}) =>
    ImportDraft(
      date: DateTime(2026, 3, 25),
      description: desc,
      amount: 10,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      sourceTag: sourceTag,
    );

void main() {
  final guesser = CategoryGuesser();

  // Sabit liste yerine GERÇEK başlangıç paketi: tahmin hedefleri paketteki
  // adlarla eşleşmek zorunda, elle kopyalanan liste sessizce kayıyordu.
  // (Paket ↔ sözlük bağı ayrıca `category_starter_pack_test.dart`te kilitli.)
  //
  // Hiyerarşi de KURULUR (çocuklara `parentId` verilir): sözlük artık
  // "Fatura › Elektrik" gibi yollar hedefliyor ve düz bir liste bu ayrımı
  // ölçemez.
  final defaultExpenseCats = <CategoryEntity>[
    for (final g in CategoryStarterPack.expense) ...[
      _cat(_tr(g.key)),
      for (final c in g.children) _cat(_tr(c.key), parent: _tr(g.key)),
    ],
  ];
  final defaultIncomeCats = <CategoryEntity>[
    for (final g in CategoryStarterPack.income) ...[
      _cat(_tr(g.key), isExpense: false),
      for (final c in g.children)
        _cat(_tr(c.key), isExpense: false, parent: _tr(g.key)),
    ],
  ];

  test('jenerik ekstre karşılıkları da eşleşir (marka adı olmadan)', () {
    // Bankaların çoğu üye işyeri adı yerine jenerik karşılık basıyor.
    // Sözlük yalnız markadan ibaret kalırsa bu satırlar kategorisiz kalır.
    const expected = {
      'KIRTASIYE ODEMESI': 'id-Alışveriş',
      'KUAFOR ODEMESI': 'id-Kuaför',
      'BERBER ODEMESI': 'id-Kuaför',
    };
    expected.forEach((desc, id) {
      expect(
        guesser.guess(
          description: desc,
          isIncome: false,
          candidates: defaultExpenseCats,
        ),
        id,
        reason: desc,
      );
    });
  });

  test('bilinen market zinciri Market kategorisine eşlenir', () {
    // Market (gıda) ile Alışveriş (giyim/elektronik) bilerek ayrı gruplar.
    final result = guesser.guess(
      description: '5411 MIGROS TIC.A.S. ISTANBUL TR',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Market');
  });

  test('akaryakıt markası Ulaşım › Yakıt alt kategorisine eşlenir', () {
    final result = guesser.guess(
      description: 'SHELL PETROL ISTASYONU',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Yakıt');
  });

  test('yemek servisi markası Yemek › Paket Servis alt kategorisine eşlenir',
      () {
    final result = guesser.guess(
      description: 'YEMEKSEPETI*SIPARIS',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-Paket Servis');
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

  // --- Alt kategori (hiyerarşi) uyumu ---

  group('alt kategori hedefleri', () {
    test('elektrik faturası kökte değil Fatura › Elektrik altına düşer', () {
      final result = guesser.guess(
        description: 'ENERJISA ELEKTRIK FATURA ODEMESI',
        isIncome: false,
        candidates: defaultExpenseCats,
      );
      expect(result, 'id-Elektrik');
    });

    test('alt kategori kullanıcıda yoksa ANA kategoriye düşer', () {
      // Alt kategorilerini silmiş/hiç kurmamış kullanıcı, eskiden olduğu gibi
      // kök eşleşmesi almalı — davranış geriye dönük bozulmamalı.
      final rootsOnly = [
        for (final g in CategoryStarterPack.expense) _cat(_tr(g.key)),
      ];
      final result = guesser.guess(
        description: 'ENERJISA ELEKTRIK FATURA ODEMESI',
        isIncome: false,
        candidates: rootsOnly,
      );
      expect(result, 'id-Fatura');
    });

    test('kullanıcı alt kategoriyi köke taşımışsa yine ADA göre bulunur', () {
      final moved = [_cat('Fatura'), _cat('Elektrik')];
      final result = guesser.guess(
        description: 'ENERJISA ELEKTRIK',
        isIncome: false,
        candidates: moved,
      );
      expect(result, 'id-Elektrik');
    });

    test('ne alt ne ana kategori varsa null döner', () {
      final result = guesser.guess(
        description: 'ENERJISA ELEKTRIK',
        isIncome: false,
        candidates: [_cat('Market')],
      );
      expect(result, isNull);
    });

    test('aynı ad iki seviyede varsa doğru ANA altındaki seçilir', () {
      // Kullanıcı "Su"yu hem Market hem Fatura altında tutuyor: sözlüğün
      // hedefi "Fatura › Su" olduğu için Fatura'nınki seçilmeli.
      final candidates = [
        _cat('Market'),
        _cat('Su', parent: 'Market'),
        _cat('Fatura'),
        _cat('Su2'),
      ];
      // Aynı adı iki kez kurmak `validateCategory` ile mümkün (farklı ana
      // kategori), test kimliği ayırt edebilmek için ikincisini elle kurar.
      final faturaSu = CategoryEntity(
        id: 'id-FaturaSu',
        name: 'Su',
        iconName: 'x',
        isExpense: true,
        parentId: 'id-Fatura',
      );
      final result = guesser.guess(
        description: 'ISKI SU FATURASI',
        isIncome: false,
        candidates: [...candidates, faturaSu],
      );
      expect(result, 'id-FaturaSu');
    });

    test('en UZUN anahtar kelime kazanır (sözlük sırası değil)', () {
      // "trendyol" Alışveriş'te, "trendyol yemek" Paket Servis'te geçiyor.
      expect(
        guesser.guess(
          description: 'TRENDYOL YEMEK SIPARIS',
          isIncome: false,
          candidates: defaultExpenseCats,
        ),
        'id-Paket Servis',
      );
      expect(
        guesser.guess(
          description: 'TRENDYOL SIPARIS',
          isIncome: false,
          candidates: defaultExpenseCats,
        ),
        'id-Alışveriş',
      );
    });

    test('banka etiketi de hedef üzerinden çözülür', () {
      expect(
        guesser.guessFromSourceTag(
          sourceTag: 'Fatura Ödemesi',
          candidates: defaultExpenseCats,
        ),
        'id-Fatura',
      );
      expect(
        guesser.guessFromSourceTag(
          sourceTag: 'Para Çekme',
          candidates: defaultExpenseCats,
        ),
        isNull,
      );
    });
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
    expect(result, 'id-Yakıt');
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

  test('eczane açıklaması Sağlık › İlaç alt kategorisine düşer', () {
    final result = guesser.guess(
      description: 'ECZANESI ISTANBUL TR Pos satış.',
      isIncome: false,
      candidates: defaultExpenseCats,
    );
    expect(result, 'id-İlaç');
  });

  group('dil değişimi', () {
    // Bildirilen hata (3 Eylül 2026) düzeltilirken açılan risk: kategori ADI
    // kullanıcı verisidir ve kurulduğu dilde DONAR. Sözlük hedefleri artık
    // anahtar taşıyor; eşleşme yalnız seçili dile bakarsa Türkçe kurup
    // İngilizceye geçen kullanıcıda ekstre tahmini tamamen ölür.
    final englishCats = <CategoryEntity>[
      for (final g in CategoryStarterPack.expense) ...[
        _cat(_en(g.key)),
        for (final c in g.children) _cat(_en(c.key), parent: _en(g.key)),
      ],
    ];

    test('İngilizce kurulmuş kategoriler de eşleşir', () {
      expect(
        guesser.guess(
          description: 'ENERJISA ELEKTRIK FATURA ODEMESI',
          isIncome: false,
          candidates: englishCats,
        ),
        'id-${_en('bills.electricity')}',
      );
    });

    test('Türkçe kurulmuş kategoriler İngilizce arayüzde de eşleşir', () {
      // Aynı sözlük, aynı hedef; yalnız kullanıcının listesi Türkçe.
      expect(
        guesser.guess(
          description: 'MIGROS ALISVERIS',
          isIncome: false,
          candidates: defaultExpenseCats,
        ),
        'id-${_tr('groceries')}',
      );
    });

    test('öneri SEÇİLİ dilde ad üretir', () {
      final suggestions = guesser.suggestNewCategories(
        drafts: [_draft('ENERJISA ELEKTRIK FATURA')],
        expenseCategories: const [],
        incomeCategories: const [],
        languageCode: 'en',
      );
      expect(suggestions.single.name, 'Electricity');
      expect(suggestions.single.parentName, 'Bills');
      expect(suggestions.single.parentIconName, 'receipt_long');
    });
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
        languageCode: 'tr',
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
        languageCode: 'tr',
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
        languageCode: 'tr',
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
        languageCode: 'tr',
      );
      expect(suggestions.single.name, 'Maaş');
      expect(suggestions.single.isIncome, isTrue);
    });

    test('ANA kategorisi duran alt kategori hedefi öneri ÜRETMEZ', () {
      // "Fatura › Elektrik" hedefi, kullanıcıda yalnız "Fatura" varken zaten
      // köke düşerek çalışıyor; her ekstrede 10 alt kategori önerip kullanıcıyı
      // onaya boğmanın anlamı yok.
      final suggestions = guesser.suggestNewCategories(
        drafts: [_draft('ENERJISA ELEKTRIK FATURA')],
        expenseCategories: [_cat('Fatura')],
        incomeCategories: const [],
        languageCode: 'tr',
      );
      expect(suggestions, isEmpty);
    });

    test('hiç karşılığı olmayan alt kategori hedefi ANA KATEGORİSİYLE önerilir',
        () {
      final suggestions = guesser.suggestNewCategories(
        drafts: [_draft('ENERJISA ELEKTRIK FATURA')],
        expenseCategories: const [],
        incomeCategories: const [],
        languageCode: 'tr',
      );
      expect(suggestions.single.name, 'Elektrik');
      expect(suggestions.single.parentName, 'Fatura');
    });

    test('bankanın kendi etiketi de öneri üretir', () {
      // Açıklamada anahtar kelime yok; sinyal yalnız ekstrenin Etiket sütunu.
      // Eskiden bu satır sessizce kategorisiz kalıyordu.
      final suggestions = guesser.suggestNewCategories(
        drafts: [_draft('ACIKLAMA YOK', sourceTag: 'Fatura Ödemesi')],
        expenseCategories: const [],
        incomeCategories: const [],
        languageCode: 'tr',
      );
      expect(suggestions.single.name, 'Fatura');
    });
  });
}
