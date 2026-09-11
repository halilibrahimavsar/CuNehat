import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mapper = ColumnMapper();

  /// Gerçek Akbank CSV'sinin yapısı: tablodan önce 5 satırlık hesap künyesi,
  /// başlık 6. satırda (indeks 5).
  RawTable realAkbankTable() => RawTable([
        ['Şube', '0817', ''],
        ['HesapNo', '0097812', ''],
        ['IBAN', 'TR320004600817888000097812', ''],
        ['Kullanılabilir Bakiye', '10.650,04', ''],
        ['Tarih Aralığı', '01.03.2026-21.07.2026', ''],
        ['Tarih', 'Tutar', 'Bakiye', 'Açıklama', ''],
        [
          '2026-07-16-10.53.10.816925',
          '2.000,00 TL',
          '2.000,04 TL',
          'Mirze Mehmet Avşar - Yapı Ve Kredi Ban',
          ''
        ],
        [
          '2026-07-13-02.11.57.188977',
          '-2.304,00 TL',
          '-2.299,96 TL',
          'Elekse/merveserin.co',
          ''
        ],
      ]);

  group('künyeli (preamble) gerçek ekstre', () {
    test('REGRESYON: başlık satırının indeksi korunur', () {
      final m = mapper.guess(realAkbankTable());
      expect(m.headerRowIndex, 5);
      expect(m.hasHeaderRow, isTrue);
      expect(m.firstDataRow, 6);
      expect(m.dateCol, 0);
      expect(m.amountCol, 1);
      expect(m.balanceCol, 2);
      expect(m.descCol, 3);
    });

    test('REGRESYON: künye satırları "atlandı" sayılmaz', () {
      final table = realAkbankTable();
      final r = mapper.apply(table, mapper.guess(table));
      expect(r.drafts.length, 2);
      // Eskiden Şube/HesapNo/IBAN/Bakiye/Tarih Aralığı satırlarındaki sayılar
      // tutar sanılıp 5 sahte "atlanan satır" raporlanıyordu.
      expect(r.skippedRows, 0);
    });

    test('REGRESYON: DB2 zaman damgalı tarihler doğru okunur', () {
      final table = realAkbankTable();
      final r = mapper.apply(table, mapper.guess(table));
      expect(r.drafts[0].date, DateTime(2026, 7, 16));
      expect(r.drafts[1].date, DateTime(2026, 7, 13));
    });

    test('başlık yoksa firstDataRow 0 (tüm satırlar taranır)', () {
      final table = RawTable([
        ['15.06.2026', 'MARKET', '-150,00'],
        ['16.06.2026', 'MAAŞ', '5.000,00'],
      ]);
      final m = mapper.guess(table);
      expect(m.headerRowIndex, -1);
      expect(m.firstDataRow, 0);
      expect(mapper.apply(table, m).drafts.length, 2);
    });
  });

  group('guess', () {
    test('tek tutar sütunlu TR başlığı', () {
      final table = RawTable([
        ['Tarih', 'Açıklama', 'Tutar'],
        ['15.06.2026', 'MARKET', '-150,00'],
        ['16.06.2026', 'MAAŞ', '+5.000,00'],
      ]);
      final m = mapper.guess(table);
      expect(m.dateCol, 0);
      expect(m.descCol, 1);
      expect(m.amountCol, 2);
      expect(m.signMode, SignMode.signedAmount);
      expect(m.isValid, isTrue);
    });

    test('ayrı Borç/Alacak sütunları', () {
      final table = RawTable([
        ['Tarih', 'Açıklama', 'Borç', 'Alacak'],
        ['10.01.2026', 'KİRA', '2.000,00', ''],
      ]);
      final m = mapper.guess(table);
      expect(m.signMode, SignMode.debitCreditColumns);
      expect(m.debitCol, 2);
      expect(m.creditCol, 3);
      expect(m.isValid, isTrue);
    });
  });

  group('apply', () {
    test('işaretli tutar → gider/gelir yönü', () {
      final table = RawTable([
        ['Tarih', 'Açıklama', 'Tutar'],
        ['15.06.2026', 'MARKET', '-150,00'],
        ['16.06.2026', 'MAAŞ', '5.000,00'],
      ]);
      final r = mapper.apply(table, mapper.guess(table));
      expect(r.drafts.length, 2);
      expect(r.drafts[0].type, TransactionTypeModel.expense);
      expect(r.drafts[0].amount, 150.0);
      expect(r.drafts[0].description, 'MARKET');
      expect(r.drafts[1].type, TransactionTypeModel.income);
      expect(r.drafts[1].amount, 5000.0);
    });

    test('borç/alacak sütunları', () {
      final table = RawTable([
        ['Tarih', 'Açıklama', 'Borç', 'Alacak'],
        ['10.01.2026', 'KİRA', '2.000,00', ''],
        ['11.01.2026', 'FAİZ', '', '35,50'],
      ]);
      final r = mapper.apply(table, mapper.guess(table));
      expect(r.drafts.length, 2);
      expect(r.drafts[0].type, TransactionTypeModel.expense);
      expect(r.drafts[0].amount, 2000.0);
      expect(r.drafts[1].type, TransactionTypeModel.income);
      expect(r.drafts[1].amount, 35.50);
    });

    test('preamble/başlık satırları sessizce elenir (skipped değil)', () {
      final table = RawTable([
        ['HESAP EKSTRESİ'],
        ['Hesap No: 123'],
        ['Tarih', 'Açıklama', 'Tutar'],
        ['01.03.2026', 'KAHVE', '-45,50'],
      ]);
      final r = mapper.apply(table, mapper.guess(table));
      expect(r.drafts.length, 1);
      expect(r.drafts[0].amount, 45.50);
      expect(r.skippedRows, 0);
    });

    test('tarihi geçerli ama tutarı bozuk satır atlanan sayılır', () {
      final m = const ColumnMapping(
          dateCol: 0, descCol: 1, amountCol: 2, headerRowIndex: 0);
      final table = RawTable([
        ['Tarih', 'Açıklama', 'Tutar'],
        ['20.03.2026', 'X', 'abc'],
        ['21.03.2026', 'Y', '-10,00'],
      ]);
      final r = mapper.apply(table, m);
      expect(r.drafts.length, 1);
      expect(r.skippedRows, 1);
    });
  });

  group('bakiye sütunu + mutabakat', () {
    test('guess normal Bakiye sütununu yakalar', () {
      final table = RawTable([
        ['Tarih', 'Açıklama', 'Tutar', 'Bakiye'],
        ['15.06.2026', 'MARKET', '100,00', '900,00'],
      ]);
      final m = mapper.guess(table);
      expect(m.amountCol, 2);
      expect(m.balanceCol, 3);
    });

    test('tek "Bakiye Tutarı" başlığı tutar sanılmaz (bakiye olarak alınır)',
        () {
      final table = RawTable([
        ['Tarih', 'Açıklama', 'Bakiye Tutarı'],
        ['01.01.2026', 'X', '900,00'],
        ['02.01.2026', 'Y', '850,00'],
      ]);
      final m = mapper.guess(table);
      expect(m.balanceCol, 2);
      expect(m.amountCol, isNull); // bakiye tutar sanılmadı
    });

    test('tek pozitif Tutar sütunu: gerçek gider bakiye deltasından türetilir',
        () {
      // Tüm Tutar değerleri POZİTİF (işaretsiz) → kolon hepsini gelir sanardı.
      // Bakiye deltaları gerçek yönü açığa çıkarır.
      final table = RawTable([
        ['Tarih', 'Açıklama', 'Tutar', 'Bakiye'],
        ['15.06.2026', 'DEVİR', '100,00', '900,00'], // çapa
        ['16.06.2026', 'MARKET', '50,00', '850,00'], // bakiye düştü → gider
        ['17.06.2026', 'MAAŞ', '200,00', '1.050,00'], // bakiye arttı → gelir
      ]);
      final r = mapper.apply(table, mapper.guess(table));
      expect(r.reconciliation.status, ReconcileStatus.matched);
      expect(r.drafts.length, 3);
      // Çapa satırı kolon işaretini korur (pozitif → gelir).
      expect(r.drafts[0].type, TransactionTypeModel.income);
      // Bunlar bakiyeden türetildi: kolon "gelir" derdi ama gerçek gider.
      expect(r.drafts[1].type, TransactionTypeModel.expense);
      expect(r.drafts[1].amount, 50.0);
      expect(r.drafts[2].type, TransactionTypeModel.income);
      expect(r.drafts[2].amount, 200.0);
    });

    test('bakiye tutmuyorsa mismatch döner, işaret kolondan korunur', () {
      final table = RawTable([
        ['Tarih', 'Açıklama', 'Tutar', 'Bakiye'],
        ['15.06.2026', 'A', '-100,00', '500,00'],
        ['16.06.2026', 'B', '-50,00', '700,00'], // delta +200 ≠ 50 → tutmaz
        ['17.06.2026', 'C', '-70,00', '640,00'], // delta -60 ≠ 70 → tutmaz
      ]);
      final r = mapper.apply(table, mapper.guess(table));
      expect(r.reconciliation.status, ReconcileStatus.mismatch);
      // Türetme yapılmadı: negatif kolon işaretleri korunur (hepsi gider).
      expect(r.drafts.every((d) => d.type == TransactionTypeModel.expense),
          isTrue);
    });
  });

  group('banka etiketi sütunu (Etiket/Kategori)', () {
    // Garanti .xls'inin gerçek başlığı. Eskiden "Etiket" hiç okunmuyordu:
    // aynı hesabın PDF'i etiketi taşırken en temiz kaynak olan .xls atıyordu.
    const garanti = RawTable([
      ['Tarih', 'Açıklama', 'Etiket', 'Tutar', 'Bakiye', 'Dekont No'],
      ['05.09.2025', 'MAAŞ ÖDEMESİ', 'Maaş', '24.279,26', '24.291,54', 'D1'],
      ['06.09.2025', 'SATIŞ-HAKMAR', 'Alışveriş', '-12,00', '24.279,54', 'D2'],
    ]);

    test('başlıktan bulunur, taslağa sourceTag olarak geçer', () {
      final m = mapper.guess(garanti);
      expect(m.tagCol, 2);
      expect(m.descCol, 1, reason: 'etiket açıklama sanılmamalı');
      final drafts = mapper.apply(garanti, m).drafts;
      expect(drafts.map((d) => d.sourceTag), ['Maaş', 'Alışveriş']);
    });

    test('eski (etiketsiz) kayıtlı eşleme okunabilir: tagCol null', () {
      final map = mapper.guess(garanti).toMap()..remove('tagCol');
      expect(ColumnMapping.fromMap(map).tagCol, isNull);
    });
  });

  group('assess — eşleme ekranı ne zaman atlanır', () {
    const good = RawTable([
      ['Tarih', 'Açıklama', 'Tutar', 'Bakiye'],
      ['01.07.2026', 'MARKET', '-100,00', '900,00'],
      ['02.07.2026', 'MAAS', '1.000,00', '1.900,00'],
      ['03.07.2026', 'KIRA', '-500,00', '1.400,00'],
    ]);

    test('başlıklar tanındı + satırlar okundu + bakiye tuttu → güvenilir', () {
      final a = mapper.assess(good, mapper.guess(good));
      expect(a.rolesFromHeader, isTrue);
      expect(a.balanceVerified, isTrue);
      expect(a.isConfident(), isTrue);
      expect(a.incomeCount, 1);
      expect(a.expenseCount, 2);
    });

    test('başlıksız dosya (içerik sezgisi) → sorulur', () {
      final headerless = RawTable(good.rows.skip(1).toList());
      final a = mapper.assess(headerless, mapper.guess(headerless));
      expect(a.mapping.hasHeaderRow, isFalse);
      expect(a.isConfident(), isFalse);
      // Kullanıcı daha önce aynı düzeni onayladıysa sorulmaz.
      expect(a.isConfident(userConfirmed: true), isTrue);
    });

    test('bakiye tutmuyorsa → sorulur', () {
      const broken = RawTable([
        ['Tarih', 'Açıklama', 'Tutar', 'Bakiye'],
        ['01.07.2026', 'A', '-100,00', '900,00'],
        ['02.07.2026', 'B', '-100,00', '500,00'],
        ['03.07.2026', 'C', '-100,00', '100,00'],
      ]);
      final a = mapper.assess(broken, mapper.guess(broken));
      expect(a.balanceMismatch, isTrue);
      expect(a.isConfident(), isFalse);
    });

    test('tarih sırası belirsizse (03/04/2026) → sorulur, örnekle', () {
      const us = RawTable([
        ['Date', 'Description', 'Amount'],
        ['03/04/2026', 'A', '-10.00'],
        ['05/04/2026', 'B', '-20.00'],
      ]);
      final a = mapper.assess(us, mapper.guess(us));
      expect(a.ambiguousDateSample, '03/04/2026');
      expect(a.isConfident(), isFalse);
      // Aynı düzeni daha önce onaylayan kullanıcı soruyu zaten cevapladı.
      expect(a.isConfident(userConfirmed: true), isTrue);
    });

    test(
        'altta tek "TOPLAM" satırı güveni bozmaz, çok sayıda okunamayan '
        'satır bozar', () {
      final withTotal = RawTable([
        ...good.rows,
        ['', 'TOPLAM', '400,00', ''],
      ]);
      expect(mapper.assess(withTotal, mapper.guess(withTotal)).isConfident(),
          isTrue);

      // Yanlış tarih sütunu: satırların çoğu okunamaz.
      final wrong = mapper.guess(good).withRole(3, ColumnRole.date);
      expect(mapper.assess(good, wrong).isConfident(), isFalse);
    });
  });
}
