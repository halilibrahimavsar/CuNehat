import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/bank_import/presentation/import_batch_labels.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));
  // Saat ENJEKTE edilir: "bugün/dün" ve "bu yıl" dalları duvar saatine
  // bağlı kalırsa test takvim ilerledikçe kendiliğinden kırılır.
  final now = DateTime(2026, 10, 12, 14, 30);

  setUpAll(() async {
    Intl.defaultLocale = 'tr';
    await initializeDateFormatting('tr');
  });

  group('importBatchRangeLabel', () {
    test('aynı yıl, farklı ay: ay adlarıyla, yılsız', () {
      expect(
          importBatchRangeLabel(
              DateTime(2026, 9, 16, 8), DateTime(2026, 10, 15, 23),
              now: now),
          '16 Eyl – 15 Eki');
    });

    test('aynı ay: gün aralığı + ay', () {
      expect(
          importBatchRangeLabel(DateTime(2026, 8, 10), DateTime(2026, 8, 16),
              now: now),
          '10 – 16 Ağu');
    });

    test('tek gün: yalnız o gün', () {
      expect(
          importBatchRangeLabel(
              DateTime(2026, 8, 10, 9), DateTime(2026, 8, 10, 18),
              now: now),
          '10 Ağu');
    });

    test('geçen yılın partisi: yıl eklenir', () {
      expect(
          importBatchRangeLabel(DateTime(2025, 9, 16), DateTime(2025, 10, 15),
              now: now),
          '16 Eyl – 15 Eki 2025');
      expect(
          importBatchRangeLabel(DateTime(2025, 8, 10), DateTime(2025, 8, 10),
              now: now),
          '10 Ağu 2025');
    });

    test('yıl değişen aralık: iki uçta da yıl, tekrar eklenmez', () {
      expect(
          importBatchRangeLabel(DateTime(2025, 12, 20), DateTime(2026, 1, 19),
              now: now),
          '20 Ara 2025 – 19 Oca 2026');
    });
  });

  group('importedAtLabel', () {
    test('bugün ve dün göreli yazılır', () {
      expect(importedAtLabel(DateTime(2026, 10, 12, 9, 5), l10n, now: now),
          'Bugün 09:05');
      expect(importedAtLabel(DateTime(2026, 10, 11, 20, 57), l10n, now: now),
          'Dün 20:57');
    });

    test('daha eski: ay adlı gün + saat; başka yılsa yıl da', () {
      expect(importedAtLabel(DateTime(2026, 9, 24, 9, 50), l10n, now: now),
          '24 Eyl 09:50');
      expect(importedAtLabel(DateTime(2025, 12, 31, 23, 59), l10n, now: now),
          '31 Ara 2025 23:59');
    });
  });
}
