import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinanceMode Unit Tests', () {
    test('title getter returns correct values', () {
      expect(FinanceMode.expense.title, 'Giderler');
      expect(FinanceMode.income.title, 'Gelirler');
      expect(FinanceMode.compare.title, 'Karşılaştırma');
    });

    test('name getter returns correct values', () {
      expect(FinanceMode.expense.name, 'Gider');
      expect(FinanceMode.income.name, 'Gelir');
      expect(FinanceMode.compare.name, 'Karşılaştırma');
    });

    test('icon getter returns correct icons', () {
      expect(FinanceMode.expense.icon, Icons.trending_down_rounded);
      expect(FinanceMode.income.icon, Icons.trending_up_rounded);
      expect(FinanceMode.compare.icon, Icons.compare_arrows_rounded);
    });

    test('primaryColor getter returns correct colors', () {
      expect(FinanceMode.expense.primaryColor, Colors.red.shade700);
      expect(FinanceMode.income.primaryColor, Colors.green.shade700);
      expect(FinanceMode.compare.primaryColor, Colors.blue.shade700);
    });
  });
}
