import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTimeRange month(int y, int m) => monthRangeOf(DateTime(y, m, 1));

  test('ayın ortasında: geçen ayın AYNI günlerine kadar', () {
    final w = comparisonWindowFor(month(2026, 10), now: DateTime(2026, 10, 9))!;
    expect(w.start, DateTime(2026, 9, 1));
    expect(w.end, DateTime(2026, 9, 9));
  });

  test('geçmiş tam ay: geçen ayın tamamı', () {
    final w = comparisonWindowFor(month(2026, 8), now: DateTime(2026, 10, 9))!;
    expect(w.start, DateTime(2026, 7, 1));
    expect(w.end, DateTime(2026, 7, 31));
  });

  test('önceki ay daha kısa: pencere onun sonunda durur', () {
    final w = comparisonWindowFor(month(2026, 3), now: DateTime(2026, 3, 31))!;
    expect(w.start, DateTime(2026, 2, 1));
    expect(w.end, DateTime(2026, 2, 28));
  });

  test('özel aralık: kendi uzunluğundaki bitişik pencere', () {
    final range =
        DateTimeRange(start: DateTime(2026, 9, 10), end: DateTime(2026, 9, 19));
    final w = comparisonWindowFor(range, now: DateTime(2026, 10, 1))!;
    expect(w.start, DateTime(2026, 8, 31));
    expect(w.end, DateTime(2026, 9, 9));
  });

  test('aralık tamamen gelecekte: kıyas yok', () {
    expect(comparisonWindowFor(month(2026, 11), now: DateTime(2026, 10, 9)),
        isNull);
  });

  test('önceki ay daha UZUN: pencere yaşanmış gün kadar (30 Nisan → 1–30 Mart)',
      () {
    final w = comparisonWindowFor(month(2026, 4), now: DateTime(2026, 4, 30))!;
    expect(w.end, DateTime(2026, 3, 30));
  });
}
