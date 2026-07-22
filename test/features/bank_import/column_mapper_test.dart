import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mapper = ColumnMapper();

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
          dateCol: 0, descCol: 1, amountCol: 2, hasHeaderRow: true);
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
}
