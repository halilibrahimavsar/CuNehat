import 'package:cunehat/features/bank_import/data/statement_date_parser.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseStatementDate', () {
    test('auto: gg.aa.yyyy (TR)', () {
      expect(parseStatementDate('15.06.2026', StatementDateFormat.auto),
          DateTime(2026, 6, 15));
    });

    test('ISO yyyy-MM-dd', () {
      expect(parseStatementDate('2026-06-15', StatementDateFormat.auto),
          DateTime(2026, 6, 15));
    });

    test('auto: ilk grup >12 ise gün kabul edilir', () {
      expect(parseStatementDate('28/02/2026', StatementDateFormat.auto),
          DateTime(2026, 2, 28));
    });

    test('auto: ikinci grup >12 ise ay-önce', () {
      expect(parseStatementDate('05/13/2026', StatementDateFormat.auto),
          DateTime(2026, 5, 13));
    });

    test('monthFirst zorlanır', () {
      expect(parseStatementDate('02/03/2026', StatementDateFormat.monthFirst),
          DateTime(2026, 2, 3));
    });

    test('dayFirst zorlanır', () {
      expect(parseStatementDate('02/03/2026', StatementDateFormat.dayFirst),
          DateTime(2026, 3, 2));
    });

    test('2 haneli yıl 2000+ olur', () {
      expect(parseStatementDate('15.06.26', StatementDateFormat.auto),
          DateTime(2026, 6, 15));
    });

    test('taşan tarih reddedilir', () {
      expect(
          parseStatementDate('31.02.2026', StatementDateFormat.auto), isNull);
    });

    test('başlık/boş null', () {
      expect(parseStatementDate('Tarih', StatementDateFormat.auto), isNull);
      expect(parseStatementDate('', StatementDateFormat.auto), isNull);
    });
  });
}
