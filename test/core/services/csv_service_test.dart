import 'package:cunehat/core/services/csv_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvService.parseDate', () {
    test('parses ISO 8601 date', () {
      expect(CsvService.parseDate('2024-03-15'),
          equals(DateTime(2024, 3, 15)));
    });

    test('parses ISO 8601 with time', () {
      expect(CsvService.parseDate('2024-03-15T10:30:00.000'),
          equals(DateTime(2024, 3, 15, 10, 30)));
    });

    test('parses Turkish dot format (dd.MM.yyyy)', () {
      expect(CsvService.parseDate('31.01.2024'),
          equals(DateTime(2024, 1, 31)));
    });

    test('parses European slash format (dd/MM/yyyy)', () {
      expect(CsvService.parseDate('15/03/2024'),
          equals(DateTime(2024, 3, 15)));
    });

    test('parses dash format (dd-MM-yyyy)', () {
      expect(CsvService.parseDate('15-03-2024'),
          equals(DateTime(2024, 3, 15)));
    });

    test('returns null for invalid date string', () {
      expect(CsvService.parseDate('not-a-date'), isNull);
    });

    test('returns null for impossible date (31.02.2024)', () {
      expect(CsvService.parseDate('31.02.2024'), isNull);
    });

    test('returns null for empty string', () {
      expect(CsvService.parseDate(''), isNull);
    });

    test('returns null for invalid month', () {
      expect(CsvService.parseDate('01.13.2024'), isNull);
    });

    test('trims whitespace before parsing', () {
      expect(CsvService.parseDate('  15.03.2024  '),
          equals(DateTime(2024, 3, 15)));
    });

    test('parses single-digit day and month', () {
      expect(CsvService.parseDate('1.1.2024'),
          equals(DateTime(2024, 1, 1)));
    });

    test('parses single-digit day, leading-zero month', () {
      expect(CsvService.parseDate('1.01.2024'),
          equals(DateTime(2024, 1, 1)));
    });
  });

  group('CsvImportResult', () {
    test('creates result with transactions and skipped rows', () {
      final result = CsvImportResult([], 5);
      expect(result.transactions, isEmpty);
      expect(result.skippedRows, 5);
    });

    test('stores provided transactions', () {
      const result = CsvImportResult([], 0);
      expect(result.transactions, isEmpty);
      expect(result.skippedRows, 0);
    });
  });
}
