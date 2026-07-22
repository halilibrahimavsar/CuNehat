import 'dart:convert';

import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ColumnMapping toMap/fromMap', () {
    test('signedAmount + balanceCol round-trip (JSON dahil)', () {
      const m = ColumnMapping(
        dateCol: 0,
        descCol: 1,
        amountCol: 2,
        balanceCol: 3,
        signMode: SignMode.signedAmount,
        dateFormat: StatementDateFormat.dayFirst,
      );
      final restored = ColumnMapping.fromMap(
          jsonDecode(jsonEncode(m.toMap())) as Map<String, dynamic>);
      expect(restored, m);
    });

    test('debitCredit + null alanlar round-trip', () {
      const m = ColumnMapping(
        dateCol: 0,
        descCol: 1,
        debitCol: 2,
        creditCol: 3,
        signMode: SignMode.debitCreditColumns,
        dateFormat: StatementDateFormat.auto,
        hasHeaderRow: false,
      );
      final restored = ColumnMapping.fromMap(
          jsonDecode(jsonEncode(m.toMap())) as Map<String, dynamic>);
      expect(restored, m);
      expect(restored.amountCol, isNull);
      expect(restored.balanceCol, isNull);
    });
  });
}
