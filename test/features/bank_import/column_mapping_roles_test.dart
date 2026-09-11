import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

/// Eşleme ekranı artık "bu sütun ne?" diye sütun başına soruyor; bu testler
/// o sorunun cevabının eşlemeye nasıl yansıdığını kilitler.
void main() {
  const signed = ColumnMapping(
    dateCol: 0,
    descCol: 1,
    amountCol: 2,
    balanceCol: 3,
    headerRowIndex: 4,
    dateFormat: StatementDateFormat.dayFirst,
  );

  group('roleOf', () {
    test('her sütunun anlamı', () {
      expect(signed.roleOf(0), ColumnRole.date);
      expect(signed.roleOf(1), ColumnRole.description);
      expect(signed.roleOf(2), ColumnRole.amount);
      expect(signed.roleOf(3), ColumnRole.balance);
      expect(signed.roleOf(4), ColumnRole.ignore);
    });

    test('işaret kipine uymayan artık değer rol sayılmaz', () {
      const stale = ColumnMapping(
          dateCol: 0, descCol: 1, amountCol: 2, debitCol: 3); // tek sütun kipi
      expect(stale.roleOf(3), ColumnRole.ignore);
    });
  });

  group('withRole', () {
    test('anlam tekildir: tarihi başka sütuna vermek eskisini düşürür', () {
      final m = signed.withRole(4, ColumnRole.date);
      expect(m.dateCol, 4);
      expect(m.roleOf(0), ColumnRole.ignore);
    });

    test('sütunun tek anlamı vardır: tutar sütununu açıklama yapmak', () {
      final m = signed.withRole(2, ColumnRole.description);
      expect(m.descCol, 2);
      expect(m.amountCol, isNull);
      expect(m.roleOf(1), ColumnRole.ignore, reason: 'eski açıklama düşer');
      expect(m.isValid, isFalse, reason: 'tutar artık yok');
    });

    test('"Giden para" seçmek ayrı sütun kipine geçirir, tutarı düşürür', () {
      final m = signed.withRole(4, ColumnRole.debit);
      expect(m.signMode, SignMode.debitCreditColumns);
      expect(m.debitCol, 4);
      expect(m.amountCol, isNull);
      expect(m.isValid, isTrue);
      final both = m.withRole(2, ColumnRole.credit);
      expect(both.creditCol, 2);
      expect(both.debitCol, 4);
    });

    test('"Tutar" seçmek tek sütun kipine döndürür, Giden/Gelen düşer', () {
      final dc = signed
          .withRole(2, ColumnRole.debit)
          .withRole(4, ColumnRole.credit)
          .withRole(3, ColumnRole.amount);
      expect(dc.signMode, SignMode.signedAmount);
      expect(dc.amountCol, 3);
      expect(dc.debitCol, isNull);
      expect(dc.creditCol, isNull);
      expect(dc.balanceCol, isNull, reason: 'bakiye sütunu tutar oldu');
    });

    test('etiket ve işlem numarası da seçilebilir; "Kullanma" temizler', () {
      final m =
          signed.withRole(4, ColumnRole.tag).withRole(3, ColumnRole.reference);
      expect(m.tagCol, 4);
      expect(m.referenceCol, 3);
      expect(m.balanceCol, isNull);
      expect(m.withRole(4, ColumnRole.ignore).tagCol, isNull);
    });

    test('başlık satırı ve tarih biçimi korunur', () {
      final m = signed.withRole(4, ColumnRole.tag);
      expect(m.headerRowIndex, 4);
      expect(m.dateFormat, StatementDateFormat.dayFirst);
    });
  });
}
