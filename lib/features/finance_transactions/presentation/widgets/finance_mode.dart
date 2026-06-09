import 'package:flutter/material.dart';

enum FinanceMode {
  expense,
  income,
  compare;

  String get title {
    switch (this) {
      case FinanceMode.expense:
        return 'Giderler';
      case FinanceMode.income:
        return 'Gelirler';
      case FinanceMode.compare:
        return 'Karşılaştırma';
    }
  }

  String get name {
    switch (this) {
      case FinanceMode.expense:
        return 'Gider';
      case FinanceMode.income:
        return 'Gelir';
      case FinanceMode.compare:
        return 'Karşılaştırma';
    }
  }

  IconData get icon {
    switch (this) {
      case FinanceMode.expense:
        return Icons.trending_down_rounded;
      case FinanceMode.income:
        return Icons.trending_up_rounded;
      case FinanceMode.compare:
        return Icons.compare_arrows_rounded;
    }
  }

  Color get primaryColor {
    switch (this) {
      case FinanceMode.expense:
        return Colors.red.shade700;
      case FinanceMode.income:
        return Colors.green.shade700;
      case FinanceMode.compare:
        return Colors.blue.shade700;
    }
  }
}
