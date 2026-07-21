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
}
