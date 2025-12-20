// lib/core/enums/finance_mode.dart
import 'package:flutter/material.dart';

enum FinanceMode {
  income, // Gelir modu
  expense, // Gider modu
  compare // Karşılaştırma modu
}

// Mod renkleri için extension
extension FinanceModeExtension on FinanceMode {
  Color get primaryColor {
    switch (this) {
      case FinanceMode.income:
        return Colors.green.shade600;
      case FinanceMode.expense:
        return Colors.red.shade600;
      case FinanceMode.compare:
        return Colors.blue.shade600;
    }
  }

  Color get secondaryColor {
    switch (this) {
      case FinanceMode.income:
        return Colors.green.shade100;
      case FinanceMode.expense:
        return Colors.red.shade100;
      case FinanceMode.compare:
        return Colors.blue.shade100;
    }
  }

  String get title {
    switch (this) {
      case FinanceMode.income:
        return 'Gelirler';
      case FinanceMode.expense:
        return 'Giderler';
      case FinanceMode.compare:
        return 'Karşılaştırma';
    }
  }

  IconData get icon {
    switch (this) {
      case FinanceMode.income:
        return Icons.trending_up;
      case FinanceMode.expense:
        return Icons.trending_down;
      case FinanceMode.compare:
        return Icons.compare_arrows;
    }
  }
}
