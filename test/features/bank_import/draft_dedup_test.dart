import 'package:cunehat/features/bank_import/data/draft_dedup.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx(DateTime d, double a, String title,
        {bool expense = true, String? reference}) =>
    TransactionEntity(
      id: 'x',
      userId: 'u',
      walletId: 'w',
      title: title,
      tag: 'Food',
      amount: a,
      date: d,
      type:
          expense ? TransactionTypeModel.expense : TransactionTypeModel.income,
      reference: reference,
    );

ImportDraft _draft(DateTime d, double a, String desc,
        {bool expense = true, String? reference}) =>
    ImportDraft(
      date: d,
      description: desc,
      amount: a,
      type:
          expense ? TransactionTypeModel.expense : TransactionTypeModel.income,
      reference: reference,
    );

void main() {
  test('mevcut cüzdan işlemiyle eşleşen taslak işaretlenir ve seçilmez', () {
    final existing = [_tx(DateTime(2026, 6, 15), 150, 'MARKET')];
    final drafts = [
      _draft(DateTime(2026, 6, 15), 150, 'Market'), // eşleşir (normalize)
      _draft(DateTime(2026, 6, 16), 50, 'Faiz', expense: false),
    ];
    final marked = markDuplicateDrafts(drafts, existing);
    expect(marked[0].isDuplicate, isTrue);
    expect(marked[0].selected, isFalse);
    expect(marked[1].isDuplicate, isFalse);
    expect(marked[1].selected, isTrue);
  });

  test('dosya içi tekrar ikinci kaydı işaretler', () {
    final drafts = [
      _draft(DateTime(2026, 6, 16), 50, 'Faiz', expense: false),
      _draft(DateTime(2026, 6, 16), 50, 'Faiz', expense: false),
    ];
    final marked = markDuplicateDrafts(drafts, const []);
    expect(marked[0].isDuplicate, isFalse);
    expect(marked[1].isDuplicate, isTrue);
  });

  test('aynı tutar farklı yön (gider/gelir) tekrar sayılmaz', () {
    final existing = [_tx(DateTime(2026, 6, 15), 100, 'İADE', expense: true)];
    final drafts = [
      _draft(DateTime(2026, 6, 15), 100, 'İADE', expense: false),
    ];
    final marked = markDuplicateDrafts(drafts, existing);
    expect(marked[0].isDuplicate, isFalse);
  });

  group('banka referansı (Dekont No) varsa', () {
    test(
        'REGRESYON: aynı gün/tutar/açıklamalı GERÇEK iki hareket tekrar '
        'sayılmaz', () {
      // Gerçek Garanti ekstresinde "KARACA OTOMAT GIDA" aynı gün aynı tutarla
      // iki kez geçiyor; sezgisel anahtar bunu yanlışlıkla tekrar sayıyordu.
      final drafts = [
        _draft(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT GIDA',
            reference: 'REF-1'),
        _draft(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT GIDA',
            reference: 'REF-2'),
      ];
      final marked = markDuplicateDrafts(drafts, const []);
      expect(marked[0].isDuplicate, isFalse);
      expect(marked[1].isDuplicate, isFalse);
      expect(marked[1].selected, isTrue);
    });

    test(
        'REGRESYON: aynı dekontu paylaşan havale + masraf satırı tekrar '
        'SAYILMAZ', () {
      // Gerçek Garanti ekstresinde dekont no işlem başına değil OPERASYON
      // başına: havalenin masraf satırı ana havaleyle aynı numarayı taşıyor.
      // Referansı tek başına anahtar yapan ilk tasarım bu 3 satırı seçimden
      // düşürüyordu — sessiz veri kaybı.
      final drafts = [
        _draft(DateTime(2025, 7, 7), 9000, 'MOBIL-FAST-578000367',
            reference: '2025-07-07-16.45.14.329462'),
        _draft(DateTime(2025, 7, 7), 12.80, 'KESİNTİ VE EKLERİ-',
            reference: '2025-07-07-16.45.14.329462'),
      ];
      final marked = markDuplicateDrafts(drafts, const []);
      expect(marked[0].isDuplicate, isFalse);
      expect(marked[1].isDuplicate, isFalse);
      expect(marked[1].selected, isTrue);
    });

    test(
        'gerçekten aynı satır iki kez geçerse (aynı anahtar + aynı referans) '
        'tekrardır', () {
      final drafts = [
        _draft(DateTime(2026, 6, 25), 40, 'A', reference: 'REF-1'),
        _draft(DateTime(2026, 6, 25), 40, 'A', reference: 'REF-1'),
      ];
      final marked = markDuplicateDrafts(drafts, const []);
      expect(marked[0].isDuplicate, isFalse);
      expect(marked[1].isDuplicate, isTrue);
      expect(marked[1].selected, isFalse);
    });

    test('referans boşsa/yoksa eski sezgi aynen çalışır', () {
      final drafts = [
        _draft(DateTime(2026, 6, 16), 50, 'Faiz', reference: '  '),
        _draft(DateTime(2026, 6, 16), 50, 'Faiz'),
      ];
      final marked = markDuplicateDrafts(drafts, const []);
      expect(marked[1].isDuplicate, isTrue);
    });

    test('referanssız defter kaydı zayıf anahtarla yine eşleşir', () {
      // Elle girilmiş işlem ya da referans sütunu olmayan bir ekstreden
      // (ör. Garanti'nin PDF'i) gelmiş kayıt: referans yoksa gün+tutar+başlık
      // sezgisi devrede kalmalı.
      final existing = [_tx(DateTime(2026, 6, 15), 150, 'MARKET')];
      final drafts = [
        _draft(DateTime(2026, 6, 15), 150, 'Market', reference: 'REF-9'),
      ];
      final marked = markDuplicateDrafts(drafts, existing);
      expect(marked[0].isDuplicate, isTrue);
    });
  });

  group('içe aktarımlar ARASI kimlik (şema v5 referans alanı)', () {
    /// ASIL KAZANÇ: başlık kullanıcı tarafından düzenlenebilir (inceleme
    /// ekranı bunu zaten yaptırıyor). Kimlik başlığa dayandığı sürece,
    /// düzenlenmiş bir işlem aynı dönemin yeniden aktarımında İKİNCİ KEZ
    /// yazılıyordu.
    test('başlığı düzenlenmiş işlem yeniden aktarımda tekrar sayılır', () {
      final existing = [
        _tx(DateTime(2026, 6, 25), 40, 'Karaca büfe alışverişi',
            reference: 'REF-1'),
      ];
      final drafts = [
        _draft(DateTime(2026, 6, 25), 40, 'SATIŞ-517040*4626-KARACA OTOMAT',
            reference: 'REF-1'),
      ];
      final marked = markDuplicateDrafts(drafts, existing);
      expect(marked[0].isDuplicate, isTrue,
          reason: 'referans başlıktan bağımsız olarak eşleşmeli');
    });

    /// Eşleşme TÜKETİMLİ olmalı: defterdeki tek kayıt iki taslağı birden
    /// tekrar işaretleyemez, yoksa gerçek hareket sessizce düşer.
    test('defterde 1, dosyada 2 gerçek hareket varsa yalnız biri tekrardır',
        () {
      final existing = [
        _tx(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT', reference: 'REF-1'),
      ];
      final drafts = [
        _draft(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT', reference: 'REF-1'),
        _draft(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT', reference: 'REF-2'),
      ];
      final marked = markDuplicateDrafts(drafts, existing);
      expect(marked[0].isDuplicate, isTrue);
      expect(marked[1].isDuplicate, isFalse);
      expect(marked[1].selected, isTrue);
    });

    test('referanssız defterde de tüketim geçerli (aynı anahtardan 2 taslak)',
        () {
      final existing = [_tx(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT')];
      final drafts = [
        _draft(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT'),
        _draft(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT'),
      ];
      final marked = markDuplicateDrafts(drafts, existing);
      expect(marked[0].isDuplicate, isTrue);
      // İkincisi dosya içi tekrar olarak işaretlenir (aynı anahtar+referans),
      // defterdeki kayıt zaten tüketildi.
      expect(marked[1].isDuplicate, isTrue);
    });

    test('banka AYRI numara verdiyse zayıf anahtardan eşleşilmez', () {
      final existing = [
        _tx(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT', reference: 'REF-1'),
      ];
      final drafts = [
        _draft(DateTime(2026, 6, 25), 40, 'KARACA OTOMAT', reference: 'REF-9'),
      ];
      final marked = markDuplicateDrafts(drafts, existing);
      expect(marked[0].isDuplicate, isFalse);
    });

    test('dekontu paylaşan havale + masraf geçmişe karşı da ayrışır', () {
      const ref = '2025-07-07-16.45.14.329462';
      final existing = [
        _tx(DateTime(2025, 7, 7), 9000, 'MOBIL-FAST', reference: ref),
        _tx(DateTime(2025, 7, 7), 12.80, 'KESİNTİ VE EKLERİ', reference: ref),
      ];
      final drafts = [
        _draft(DateTime(2025, 7, 7), 9000, 'MOBIL-FAST', reference: ref),
        _draft(DateTime(2025, 7, 7), 12.80, 'KESİNTİ VE EKLERİ',
            reference: ref),
      ];
      final marked = markDuplicateDrafts(drafts, existing);
      // İkisi de zaten defterde: tutar anahtara dahil olduğu için doğru
      // eşleşirler (referans tek başına anahtar olsaydı ikincisi kaçardı).
      expect(marked[0].isDuplicate, isTrue);
      expect(marked[1].isDuplicate, isTrue);
    });

    test('aynı hesabın PDF ve .xls biçimleri birbirini bulur', () {
      // Garanti'nin PDF'i Dekont No taşımaz, .xls'i taşır. Hangi sırayla
      // aktarılırsa aktarılsın ikinci aktarım tekrar sayılmalı.
      final fromPdf = [_tx(DateTime(2025, 9, 5), 4400, 'ATM PARA ÇEKME')];
      final fromXls = [
        _draft(DateTime(2025, 9, 5), 4400, 'ATM PARA ÇEKME',
            reference: 'DEKONT-7'),
      ];
      expect(markDuplicateDrafts(fromXls, fromPdf)[0].isDuplicate, isTrue);

      final xlsFirst = [
        _tx(DateTime(2025, 9, 5), 4400, 'ATM PARA ÇEKME',
            reference: 'DEKONT-7'),
      ];
      final pdfSecond = [_draft(DateTime(2025, 9, 5), 4400, 'ATM PARA ÇEKME')];
      expect(markDuplicateDrafts(pdfSecond, xlsFirst)[0].isDuplicate, isTrue);
    });
  });

  test('Türkçe noktasız I zayıf anahtarı bozmaz (IŞIK ↔ Işık)', () {
    // Dart `'IŞIK'.toLowerCase()` → `işik` verir (`ışık` değil). Ekstre büyük
    // harf, kullanıcının elle girdiği kayıt normal yazım: eski `toLowerCase()`
    // yolunda iki taraf hiç eşleşmiyor, aynı hareket ikinci kez yazılıyordu.
    final existing = [_tx(DateTime(2026, 6, 15), 90, 'Işık Elektrik')];
    final marked = markDuplicateDrafts(
      [_draft(DateTime(2026, 6, 15), 90, 'IŞIK ELEKTRİK')],
      existing,
    );
    expect(marked.single.isDuplicate, isTrue);
  });

  group('kesin eşleşme neyle eşleştiğini taşır', () {
    test('defter kaydının kimliği, başlığı ve tutarı eşleşmede', () {
      final existing = [
        _manual('m1', DateTime(2026, 6, 15, 9), 150, 'MARKET'),
      ];
      final marked = markDuplicateDrafts(
          [_bank(DateTime(2026, 6, 15), 150, 'Market')], existing);
      final match = marked.single.duplicateOf!;
      expect(match.kind, DuplicateKind.exact);
      expect(match.existingId, 'm1');
      expect(match.existingTitle, 'MARKET');
      expect(match.existingAmount, 150);
    });

    test('dosya içi eş, ilk satırı gösterir', () {
      final marked = markDuplicateDrafts([
        _bank(DateTime(2026, 6, 16), 50, 'FAIZ'),
        _bank(DateTime(2026, 6, 16), 50, 'FAIZ'),
      ], const []);
      expect(marked[1].duplicateOf!.kind, DuplicateKind.withinFile);
      expect(marked[1].duplicateOf!.existingId, isNull);
    });
  });

  group('REGRESYON: bakiye zinciri tutan ekstrede dosya içi tekrar YOK', () {
    // Aritmetik olarak doğrulanmış gerçek Garanti PDF'inde "MACGAL GIDA"
    // 30,00 ve "KARACA OTOMAT" 40,00 aynı gün ikişer kez geçiyor; ikinciler
    // "tekrar" sayılıp seçimsiz geliyordu (70 TL gerçek harcama).
    final pair = [
      _bank(
          DateTime(2025, 7, 21), 30, 'SATIŞ-517040*4626-MACGAL GIDA INS. TEK'),
      _bank(
          DateTime(2025, 7, 21), 30, 'SATIŞ-517040*4626-MACGAL GIDA INS. TEK'),
    ];

    test('kanıt varsa ikisi de eklenir', () {
      final marked =
          markDuplicateDrafts(pair, const [], rowsProvenDistinct: true);
      expect(marked.every((d) => !d.isDuplicate && d.selected), isTrue);
    });

    test('kanıt yoksa (ör. OCR) kontrol sürer', () {
      final marked = markDuplicateDrafts(pair, const []);
      expect(marked[1].duplicateOf?.kind, DuplicateKind.withinFile);
    });

    test('kanıt olsa da DEFTERE karşı kesin eşleşme çalışır', () {
      final marked = markDuplicateDrafts(
        pair,
        [
          _manual('m1', DateTime(2025, 7, 21), 30,
              'SATIŞ-517040*4626-MACGAL GIDA INS. TEK')
        ],
        rowsProvenDistinct: true,
      );
      expect(marked[0].duplicateOf?.kind, DuplicateKind.exact);
      expect(marked[1].isDuplicate, isFalse, reason: 'tüketim: tek kayıt');
    });
  });

  group('amountPatternOf — yalnız YUVARLAMA benzerlik sayılır', () {
    AmountPattern? p(double bank, double typed) =>
        amountPatternOf(bank: bank, typed: typed);

    test('kullanıcının örneği: 913,15 → 913 / 910 / 915 / 900', () {
      expect(p(913.15, 913.15), AmountPattern.exact);
      expect(p(913.15, 913), AmountPattern.centsDropped);
      expect(p(913.15, 914), AmountPattern.centsDropped);
      expect(p(913.15, 910), AmountPattern.roundedSmall);
      expect(p(913.15, 915), AmountPattern.roundedSmall);
      expect(p(913.15, 900), AmountPattern.roundedLarge);
    });

    test('rastgele fark eşleşme değildir', () {
      expect(p(913.15, 931), isNull,
          reason: 'basamak karışması yuvarlama değil');
      expect(p(913.15, 912.50), isNull, reason: 'tam sayı değil, 5/10 değil');
      expect(p(913.15, 850), isNull);
    });

    test('küçük tutarda göreli sınır: 45,90 → 50 olur, 7,50 → 10 olmaz', () {
      expect(p(45.90, 50), AmountPattern.roundedSmall);
      expect(p(7.50, 10), isNull);
    });

    test('100\'e yuvarlama yalnız büyük tutarda', () {
      expect(p(1478.90, 1500), AmountPattern.roundedLarge);
      expect(p(460, 500), isNull, reason: '%8,7 ve küçük tutar');
    });
  });

  group('yaklaşık eşleşme — aynı harcama elle girilmiş', () {
    // Kullanıcının tarif ettiği senaryo: BİM'de alışveriş, bankada 913,15.
    // Elle "bim" ya da boş not (başlık kategori adına düşer), 913 ya da 910,
    // saati dikkate alınmadan girilmiş.
    final bim = _bank(
        DateTime(2026, 9, 5), 913.15, 'SATIŞ-517040*4626-BİM L508 YUNUS EMRE');

    test('"bim" · 913 · aynı gün (saat farklı) → güçlü eşleşme, eklenmez', () {
      final marked = markDuplicateDrafts(
          [bim], [_manual('m1', DateTime(2026, 9, 5, 21, 40), 913, 'bim')]);
      final d = marked.single;
      expect(d.selected, isFalse);
      final m = d.duplicateOf!;
      expect(m.kind, DuplicateKind.approximate);
      expect(m.strong, isTrue);
      expect(m.existingId, 'm1');
      expect(m.amountPattern, AmountPattern.centsDropped);
      expect(m.amountDelta, 0.15);
      expect(m.dayDistance, 0);
      expect(m.sharedWord, 'bim');
      expect(m.categoryMatches, isTrue);
      expect(m.canCorrectAmount, isTrue);
    });

    test('not boş (başlık "Market") · 910 · aynı gün → olası eşleşme', () {
      final marked = markDuplicateDrafts(
          [bim], [_manual('m1', DateTime(2026, 9, 5, 12), 910, 'Market')]);
      final m = marked.single.duplicateOf!;
      expect(m.kind, DuplicateKind.approximate);
      expect(m.strong, isFalse);
      expect(m.sharedWord, isNull);
      expect(m.amountPattern, AmountPattern.roundedSmall);
    });

    test('ertesi gün girilmiş (tarih "şimdi"ye ayarlı kalmış) → yine bulunur',
        () {
      final marked = markDuplicateDrafts(
          [bim], [_manual('m1', DateTime(2026, 9, 6, 9, 5), 913, 'bim')]);
      expect(marked.single.duplicateOf?.dayDistance, 1);
    });

    test('Türkçe ekli kelime de ortak sayılır ("bimden")', () {
      final marked = markDuplicateDrafts(
          [bim], [_manual('m1', DateTime(2026, 9, 5), 913, "bim'den ekmek")]);
      expect(marked.single.duplicateOf?.sharedWord, 'bim');
      final marked2 = markDuplicateDrafts(
          [bim], [_manual('m1', DateTime(2026, 9, 5), 913, 'bimden')]);
      expect(marked2.single.duplicateOf?.sharedWord, 'bimden');
    });

    test('kanıt zayıfsa eşleşme YOK: 910 · 2 gün sonra · ortak kelime yok', () {
      final marked = markDuplicateDrafts(
          [bim], [_manual('m1', DateTime(2026, 9, 7), 910, 'Market')]);
      expect(marked.single.isDuplicate, isFalse);
      expect(marked.single.selected, isTrue);
    });

    test('4+ gün uzaktaki kayıt aday bile değildir', () {
      final marked = markDuplicateDrafts(
          [bim], [_manual('m1', DateTime(2026, 9, 9), 913.15, 'bim')]);
      expect(marked.single.isDuplicate, isFalse);
    });

    test('yön farklıysa (gelir ↔ gider) eşleşmez', () {
      final marked = markDuplicateDrafts([
        bim
      ], [
        _manual('m1', DateTime(2026, 9, 5), 913, 'bim', expense: false),
      ]);
      expect(marked.single.isDuplicate, isFalse);
    });

    test('birebir: tek elle kayıt, iki banka satırından yalnız BİRİNİ alır',
        () {
      final marked = markDuplicateDrafts([
        bim,
        _bank(DateTime(2026, 9, 6), 905.40, 'SATIŞ-517040*4626-BİM L508'),
      ], [
        _manual('m1', DateTime(2026, 9, 5), 913, 'bim'),
      ]);
      expect(marked[0].isDuplicate, isTrue);
      expect(marked[1].isDuplicate, isFalse);
      expect(marked[1].selected, isTrue);
    });

    test('en iyi açıklanan çift kazanır (sıra değil)', () {
      // Elle 910 (6 Eyl). Aday banka satırları: 913,15 (5 Eyl) ve
      // 908,60 (6 Eyl). İkincisi hem aynı gün hem daha yakın.
      final marked = markDuplicateDrafts([
        bim,
        _bank(DateTime(2026, 9, 6), 908.60, 'SATIŞ-517040*4626-BİM L508'),
      ], [
        _manual('m1', DateTime(2026, 9, 6, 18), 910, 'Market'),
      ]);
      expect(marked[0].isDuplicate, isFalse);
      expect(marked[1].duplicateOf?.existingId, 'm1');
    });

    test(
        'kesin eşleşmenin tükettiği kayıt yaklaşık eşleşmede tekrar '
        'kullanılmaz', () {
      final marked = markDuplicateDrafts([
        _bank(DateTime(2026, 9, 5), 913, 'bim'),
        _bank(DateTime(2026, 9, 5), 913.15, 'BIM MAGAZALAR'),
      ], [
        _manual('m1', DateTime(2026, 9, 5), 913, 'bim'),
      ]);
      expect(marked[0].duplicateOf?.kind, DuplicateKind.exact);
      expect(marked[1].isDuplicate, isFalse);
    });

    test('banka numaraları farklıysa eşleşmez', () {
      final marked = markDuplicateDrafts([
        _bank(DateTime(2026, 9, 5), 913.15, 'BIM', reference: 'R2'),
      ], [
        _manual('m1', DateTime(2026, 9, 5), 913, 'bim', reference: 'R1'),
      ]);
      expect(marked.single.isDuplicate, isFalse);
    });

    test('borç modülünün kaydıyla eşleşir ama tutarı düzeltilemez', () {
      final marked = markDuplicateDrafts([
        _bank(DateTime(2026, 9, 5), 2500, 'KREDI TAKSIT TAHSILATI',
            category: null),
      ], [
        _manual('sys1', DateTime(2026, 9, 5), 2500, 'Borç Ödemesi',
            tag: 'Borç Ödemesi', isSystem: true),
      ]);
      final m = marked.single.duplicateOf!;
      expect(m.kind, DuplicateKind.approximate);
      expect(m.existingIsSystem, isTrue);
      expect(m.canCorrectAmount, isFalse);
    });

    group('ekstreden gelmiş kayıtlar', () {
      test('ardışık ekstrelerin sınırında her gün aynı büfe → TEKRAR DEĞİL',
          () {
        // Önceki ekstre 9 Eyl'de bitti; yeni ekstrede 11 Eyl'de aynı yerden
        // aynı tutar. İkisi de bankanın satırı: farklı gün = farklı alışveriş.
        final marked = markDuplicateDrafts([
          _bank(
              DateTime(2026, 9, 11),
              450,
              'POS Kart İşlemleri - 983100419640000-ODE AL/DEMIRHAN BUFE '
              'ISTANBUL TR Pos satış.'),
        ], [
          _manual(
              'old',
              DateTime(2026, 9, 9),
              450,
              'POS Kart İşlemleri - 983100419640000-ODE AL/DEMIRHAN BUFE '
                  'ISTANBUL TR Pos satış.'),
        ]);
        expect(marked.single.isDuplicate, isFalse);
      });

      test(
          'aynı hareket başka biçimde geri gelirse (aynı gün, aynı tutar, '
          'farklı yazım) bulunur', () {
        final marked = markDuplicateDrafts([
          _bank(DateTime(2025, 9, 3), 134.75,
              'SATIŞ-517040*4626-BİM L508 YUNUS EMRE-SUL'),
        ], [
          _manual('old', DateTime(2025, 9, 3), 134.75,
              'BIM L508 YUNUS EMRE SULTANBEYLI TR'),
        ]);
        expect(marked.single.duplicateOf?.kind, DuplicateKind.approximate);
      });
    });
  });
}

// ===================================================== yaklaşık eşleşme

/// Elle girilmiş bir kayıt: form tarihi SAATİYLE yazar, not boşsa başlık
/// kategori adına düşer.
TransactionEntity _manual(
  String id,
  DateTime at,
  double amount,
  String title, {
  String tag = 'cat-market',
  bool expense = true,
  bool isSystem = false,
  String? reference,
}) =>
    TransactionEntity(
      id: id,
      userId: 'u',
      walletId: 'w',
      title: title,
      tag: tag,
      amount: amount,
      date: at,
      type:
          expense ? TransactionTypeModel.expense : TransactionTypeModel.income,
      isSystem: isSystem,
      reference: reference,
    );

ImportDraft _bank(
  DateTime d,
  double amount,
  String desc, {
  String? category = 'cat-market',
  bool expense = true,
  String? reference,
}) =>
    ImportDraft(
      date: d,
      description: desc,
      amount: amount,
      type:
          expense ? TransactionTypeModel.expense : TransactionTypeModel.income,
      categoryId: category,
      reference: reference,
    );
