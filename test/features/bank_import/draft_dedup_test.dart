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
}
