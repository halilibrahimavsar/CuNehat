import 'package:cunehat/features/bank_import/data/layout/layout_word.dart';
import 'package:cunehat/features/bank_import/data/layout/statement_layout_engine.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testlerdeki koordinatlar GERÇEK ekstre ölçülerinden alındı (syncfusion
/// `extractTextLines` çıktısı, QNB/Garanti): satır yüksekliği 8, tarih
/// sütunu x≈16, tutar sağ kenarı x≈504, bakiye sağ kenarı x≈579.
const _h = 8.0;
const _charWidth = 4.2;

LayoutWord _w(String text, double left, double top, {int page = 0}) =>
    LayoutWord(
      text: text,
      left: left,
      right: left + text.length * _charWidth,
      top: top,
      bottom: top + _h,
      page: page,
    );

/// Sayısal sütunlar SAĞA dayalıdır; hücre sol kenarı rakam sayısına göre oynar.
LayoutWord _right(String text, double right, double top, {int page = 0}) =>
    _w(text, right - text.length * _charWidth, top, page: page);

const _dateX = 16.0;
const _descX = 96.0;
const _amountRight = 504.0;
const _balanceRight = 579.0;

void main() {
  group('sütun kimliği (gerçek hatalardan regresyon)', () {
    /// GERÇEK HATA: QNB açıklamaları referansla biter
    /// ("… Sorgu No: 2076317 - 999/4888152-") ve düz metinde tutarla yan yana
    /// düşer. Metin tabanlı ayrıştırıcının para regex'i o tireyi işaret
    /// sanıyor, `- 2,000.00` okuyordu: 7 satırda 38.420 TL'lik GELİR, gider
    /// olarak yazılıyordu. Sütun kimliği korunduğunda açıklamadaki hiçbir
    /// karakter tutara karışamaz.
    test('açıklamanın sonundaki tire tutarın işaretini ÇALAMAZ', () {
      final words = <LayoutWord>[
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _right('Tutar', _amountRight, 60),
        _right('Bakiye', _balanceRight, 60),
        for (var i = 0; i < 4; i++) ...[
          _w('0${i + 1}/03/2026', _dateX, 100 + i * 20),
          _w('Gönderen:HALİL Sorgu No:2076317-999/4888152-', _descX,
              100 + i * 20),
          _right('2,000.00', _amountRight, 100 + i * 20),
          _right('${2000 * (i + 1)}.00', _balanceRight, 100 + i * 20),
        ],
      ];

      final r = analyzeStatementLayout(words);
      expect(r.usable, isTrue);
      expect(r.records, hasLength(4));
      for (final rec in r.records) {
        expect(rec.amount, 2000.0, reason: 'işaret açıklamadan sızmamalı');
        expect(rec.description, contains('999/4888152-'));
      }
    });

    /// GERÇEK HATA: dekont no tutara bitişik geliyordu
    /// ("… PARA YATIRMA, 55636820,000.00"); regex ortadan `820,000.00` gibi
    /// var olmayan bir sayı çıkarıp gerçek tutarı 0'a düşürüyor, satır
    /// sessizce ATLANIYORDU (2 satır / 25.000 TL).
    test('açıklamadaki referans numarası tutara karışmaz', () {
      final words = <LayoutWord>[
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _right('Tutar', _amountRight, 60),
        _right('Bakiye', _balanceRight, 60),
        _w('01/05/2026', _dateX, 100),
        _w('ATM DEN VADESIZ HESABA PARA YATIRMA, 556368', _descX, 100),
        _right('20,000.00', _amountRight, 100),
        _right('20,037.41', _balanceRight, 100),
        _w('01/05/2026', _dateX, 120),
        _w('ATM DEN VADESIZ HESABA PARA YATIRMA, 558025', _descX, 120),
        _right('5,000.00', _amountRight, 120),
        _right('25,037.41', _balanceRight, 120),
        _w('02/05/2026', _dateX, 140),
        _w('Kart ödemesi', _descX, 140),
        _right('-14,930.00', _amountRight, 140),
        _right('10,107.41', _balanceRight, 140),
      ];

      final r = analyzeStatementLayout(words);
      expect(r.usable, isTrue);
      expect(r.records.map((e) => e.amount), [20000.0, 5000.0, -14930.0]);
    });

    /// GERÇEK DÜZEN: QNB'de uzun açıklama tarih satırının HEM ÜSTÜNE hem
    /// altına sarar. Metin yolundaki "tarihsiz satır bir ÖNCEKİ kaydın
    /// devamıdır" kuralı üstteki parçayı yanlış kayda yapıştırıyordu.
    test('tarih satırının ÜSTÜNDEKİ açıklama doğru kayda bağlanır', () {
      final words = <LayoutWord>[
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _right('Tutar', _amountRight, 60),
        _right('Bakiye', _balanceRight, 60),
        // 1. kayıt
        _w('28/01/2026', _dateX, 100),
        _w('BIRINCI', _descX, 100),
        _right('-100.00', _amountRight, 100),
        _right('900.00', _balanceRight, 100),
        // 2. kayıt: açıklamanın ilk parçası ÜSTTE, ikincisi ALTTA
        _w('USTTEKI-PARCA', _descX, 121),
        _w('04/03/2026', _dateX, 130),
        _right('2,000.00', _amountRight, 130),
        _right('2,900.00', _balanceRight, 130),
        _w('ALTTAKI-PARCA', _descX, 139),
        // 3. kayıt
        _w('05/03/2026', _dateX, 160),
        _w('UCUNCU', _descX, 160),
        _right('-272.23', _amountRight, 160),
        _right('2,627.77', _balanceRight, 160),
      ];

      final r = analyzeStatementLayout(words);
      expect(r.usable, isTrue);
      expect(r.records, hasLength(3));
      expect(r.records[0].description, 'BIRINCI');
      expect(r.records[1].amount, 2000.0);
      expect(r.records[1].description, contains('USTTEKI-PARCA'));
      expect(r.records[1].description, contains('ALTTAKI-PARCA'));
      expect(r.records[2].description, 'UCUNCU');
    });

    /// GERÇEK DÜZEN: Garanti'de tutar hücresi kelime kutularına bölünmüş
    /// gelir (`-4.400` + `,00` + `TL`). Kelimeler tek tek bakıldığında
    /// hiçbiri para değildir; yatay olarak bitişik oldukları için TEK hücreye
    /// birleşmeleri şart.
    test('bölünmüş para kelimeleri tek hücrede birleşir', () {
      final words = <LayoutWord>[
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _right('Tutar', _amountRight, 60),
        for (var i = 0; i < 3; i++) ...[
          _w('0${i + 1}.09.2025', _dateX, 100 + i * 20),
          _w('SATIŞ-BİM', _descX, 100 + i * 20),
          // "-4.400" [440..463] + ",00" [463..476] + " TL" [477..486]
          _w('-4.400', 440, 100 + i * 20),
          _w(',00', 463, 100 + i * 20),
          _w('TL', 477.5, 100 + i * 20),
        ],
      ];

      final r = analyzeStatementLayout(words);
      expect(r.usable, isTrue);
      expect(r.records.map((e) => e.amount), [-4400.0, -4400.0, -4400.0]);
      expect(r.records.first.description, 'SATIŞ-BİM');
    });

    test('bankanın kendi "Etiket" sütunu ayrı okunur, açıklamaya karışmaz', () {
      final words = <LayoutWord>[
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _w('Etiket', 315, 60),
        _right('Tutar', _amountRight, 60),
        _right('Bakiye', _balanceRight, 60),
        for (var i = 0; i < 3; i++) ...[
          _w('0${i + 1}.09.2025', _dateX, 100 + i * 20),
          _w('SATIŞ-517040*4626-BİM', _descX, 100 + i * 20),
          _w('Alışveriş', 315, 100 + i * 20),
          _right('-134,75', _amountRight, 100 + i * 20),
          _right('${1000 - i * 200},00', _balanceRight, 100 + i * 20),
        ],
      ];

      final r = analyzeStatementLayout(words);
      expect(r.usable, isTrue);
      for (final rec in r.records) {
        expect(rec.sourceTag, 'Alışveriş');
        expect(rec.description, 'SATIŞ-517040*4626-BİM');
      }
    });

    test('ayrı Borç/Alacak sütunlarında işaret sütundan gelir', () {
      const debitRight = 420.0;
      const creditRight = 504.0;
      final words = <LayoutWord>[
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _right('Borç', debitRight, 60),
        _right('Alacak', creditRight, 60),
        _right('Bakiye', _balanceRight, 60),
        for (var i = 0; i < 8; i++) ...[
          _w('0${i + 1}.09.2025', _dateX, 100 + i * 20),
          _w('HAREKET', _descX, 100 + i * 20),
          if (i.isEven)
            _right('100,00', debitRight, 100 + i * 20)
          else
            _right('250,00', creditRight, 100 + i * 20),
          _right('${5000 + i},00', _balanceRight, 100 + i * 20),
        ],
      ];

      final r = analyzeStatementLayout(words);
      expect(r.usable, isTrue);
      expect(r.records, hasLength(8));
      for (var i = 0; i < 8; i++) {
        expect(r.records[i].amount, i.isEven ? -100.0 : 250.0,
            reason: 'borç sütunu gider, alacak sütunu gelirdir');
      }
    });

    test('başlık ve sayfa altbilgisi bir kaydın açıklamasına yapışmaz', () {
      final words = <LayoutWord>[
        _w('BANKA-KUNYE-USTBILGI', _descX, 20),
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _right('Tutar', _amountRight, 60),
        for (var i = 0; i < 3; i++) ...[
          _w('0${i + 1}.09.2025', _dateX, 100 + i * 20),
          _w('HAREKET$i', _descX, 100 + i * 20),
          _right('-10,00', _amountRight, 100 + i * 20),
        ],
        _w('www.banka.com.tr-ALTBILGI', _descX, 300),
      ];

      final r = analyzeStatementLayout(words);
      expect(r.usable, isTrue);
      expect(r.records, hasLength(3));
      for (final rec in r.records) {
        expect(rec.description, isNot(contains('KUNYE')));
        expect(rec.description, isNot(contains('ALTBILGI')));
      }
    });

    /// Para sütunları SAĞ KENAR hizasından bulunur; sütunun ayırt edici
    /// özelliği budur. Sola dayalı açıklama metninin içindeki bir tutar,
    /// kendinden önceki metnin uzunluğuna göre kaydığı için hiçbir zaman
    /// hizalı bir küme oluşturmaz — bu yüzden sütun sanılamaz.
    test('açıklamanın içindeki tutar sütun sanılmaz', () {
      const offsets = [0.0, 42.0, -18.0, 64.0];
      final words = <LayoutWord>[
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _right('Tutar', _amountRight, 60),
        for (var i = 0; i < 4; i++) ...[
          _w('0${i + 1}.09.2025', _dateX, 100 + i * 20),
          _w('TAKSIT', _descX, 100 + i * 20),
          _w('1.234,56', 200 + offsets[i], 100 + i * 20),
          _right('-99,00', _amountRight, 100 + i * 20),
        ],
      ];

      final r = analyzeStatementLayout(words);
      expect(r.usable, isTrue);
      expect(r.records.map((e) => e.amount), [-99.0, -99.0, -99.0, -99.0]);
      expect(r.records.first.description, contains('1.234,56'));
    });

    test('sütun düzeni bulunamazsa usable=false (eski yola düşülür)', () {
      final words = [
        for (var i = 0; i < 20; i++) _w('serbest metin $i', 10, 20.0 + i * 20),
      ];
      expect(analyzeStatementLayout(words).usable, isFalse);
    });

    test('sayfa sınırı satır kümelemesini aşmaz', () {
      final words = <LayoutWord>[
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _right('Tutar', _amountRight, 60),
        for (var page = 0; page < 2; page++)
          for (var i = 0; i < 2; i++) ...[
            _w('0${i + 1}.0${page + 1}.2025', _dateX, 100 + i * 20, page: page),
            _w('SAYFA$page-SATIR$i', _descX, 100 + i * 20, page: page),
            _right('-1${i}0,00', _amountRight, 100 + i * 20, page: page),
          ],
      ];

      final r = analyzeStatementLayout(words);
      expect(r.usable, isTrue);
      expect(r.records, hasLength(4));
      expect(r.records[0].description, 'SAYFA0-SATIR0');
      expect(r.records[2].description, 'SAYFA1-SATIR0');
    });
  });

  group('parseLayoutMoney', () {
    test('belge biçimine göre ayraç yorumlanır', () {
      expect(parseLayoutMoney('1.234,56', englishGrouping: false), 1234.56);
      expect(parseLayoutMoney('1,234.56', englishGrouping: true), 1234.56);
      // Yanlış biçimde okumaya ÇALIŞMAZ: karışık yorum 1000 kat hataya yol açar.
      expect(parseLayoutMoney('1,234.56', englishGrouping: false), isNull);
    });

    test('işaret ve muhasebe parantezi', () {
      expect(parseLayoutMoney('-90,00', englishGrouping: false), -90.0);
      expect(parseLayoutMoney('(90,00)', englishGrouping: false), -90.0);
      expect(parseLayoutMoney('90,00-', englishGrouping: false), -90.0);
      expect(parseLayoutMoney('+90,00', englishGrouping: false), 90.0);
    });

    test('para birimi eki temizlenir', () {
      expect(parseLayoutMoney('-4.400,00 TL', englishGrouping: false), -4400.0);
      expect(parseLayoutMoney('₺1.234,56', englishGrouping: false), 1234.56);
    });

    test('hücrenin TAMAMI sayı değilse null', () {
      // Metin tabanlı yolun aksine burada "içinden sayı çıkarma" yapılmaz.
      expect(parseLayoutMoney('Sorgu No: 2076317', englishGrouping: false),
          isNull);
      expect(
          parseLayoutMoney('TR320004600817', englishGrouping: false), isNull);
      expect(parseLayoutMoney('', englishGrouping: false), isNull);
    });
  });

  group('layoutTextFromWords', () {
    test('aynı yükseklikteki parçalar TEK satırda soldan sağa birleşir', () {
      // OCR blokları okuma sırasını korumaz; bilerek karışık sırada veriliyor.
      final text = layoutTextFromWords([
        _right('-4.400,00', 700, 100),
        _w('05.09.2025', 20, 100),
        _w('ATM PARA ÇEKME', 200, 100),
      ]);
      expect(text, '05.09.2025 ATM PARA ÇEKME -4.400,00');
    });

    test('farklı satırlar yukarıdan aşağıya sıralanır', () {
      final text = layoutTextFromWords([
        _w('B', 20, 140),
        _w('C', 20, 180),
        _w('A', 20, 100),
      ]);
      expect(text, 'A\nB\nC');
    });

    test('hafif dikey kayma aynı satır sayılır', () {
      final text = layoutTextFromWords([
        _w('05.09.2025', 20, 100),
        _right('-134,75', 700, 102),
      ]);
      expect(text, '05.09.2025 -134,75');
    });

    test('boş girdi boş string', () {
      expect(layoutTextFromWords(const []), '');
    });
  });

  group('uçtan uca: kelime → taslak', () {
    test('geometri yolu taslak üretir ve işaretler doğrudur', () {
      final words = <LayoutWord>[
        _w('Tarih', _dateX, 60),
        _w('Açıklama', _descX, 60),
        _right('Tutar', _amountRight, 60),
        _right('Bakiye', _balanceRight, 60),
        _w('05.09.2025', _dateX, 100),
        _w('SATIŞ-BİM', _descX, 100),
        _right('-134,75', _amountRight, 100),
        _right('865,25', _balanceRight, 100),
        _w('06.09.2025', _dateX, 120),
        _w('MAAŞ ÖDEMESİ', _descX, 120),
        _right('2.000,00', _amountRight, 120),
        _right('2.865,25', _balanceRight, 120),
        _w('07.09.2025', _dateX, 140),
        _w('KİRA', _descX, 140),
        _right('-1.000,00', _amountRight, 140),
        _right('1.865,25', _balanceRight, 140),
      ];

      final result = PdfStatementParser().parseWords(words);
      expect(result.fromLayout, isTrue);
      expect(result.drafts, hasLength(3));
      expect(result.drafts[0].date, DateTime(2025, 9, 5));
      expect(result.drafts[0].amount, 134.75);
      expect(result.drafts[0].type, TransactionTypeModel.expense);
      expect(result.drafts[1].amount, 2000.0);
      expect(result.drafts[1].type, TransactionTypeModel.income);
      expect(result.drafts[2].amount, 1000.0);
      // Bakiye zinciri her satırı doğruladı.
      expect(result.reconciliation?.matched, 2);
    });

    test('düzen çözülemezse eski satır-sezgisel yola düşülür', () {
      // Tek sütun, konum bilgisi ayırt edici değil → geometri kullanılamaz,
      // ama düz metin yolu yine de taslak çıkarabilir.
      final words = <LayoutWord>[
        _w('05.09.2025 SATIŞ-BİM -134,75', 20, 100),
        _w('06.09.2025 KİRA -1.000,00', 20, 120),
      ];
      final result = PdfStatementParser().parseWords(words);
      expect(result.fromLayout, isFalse);
      expect(result.drafts, hasLength(2));
    });
  });
}
