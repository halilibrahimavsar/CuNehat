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

  String get description {
    switch (this) {
      case FinanceMode.expense:
        return 'Sadece gider işlemlerini gösterir';
      case FinanceMode.income:
        return 'Sadece gelir işlemlerini gösterir';
      case FinanceMode.compare:
        return 'Gelir ve giderleri birlikte gösterir';
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

  Color get secondaryColor {
    switch (this) {
      case FinanceMode.expense:
        return Colors.red.shade400;
      case FinanceMode.income:
        return Colors.green.shade400;
      case FinanceMode.compare:
        return Colors.blue.shade400;
    }
  }

  Color get darkColor {
    switch (this) {
      case FinanceMode.expense:
        return Colors.red.shade900;
      case FinanceMode.income:
        return Colors.green.shade900;
      case FinanceMode.compare:
        return Colors.blue.shade900;
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case FinanceMode.expense:
        return [
          Colors.red.shade400,
          Colors.red.shade700,
          Colors.red.shade900,
        ];
      case FinanceMode.income:
        return [
          Colors.green.shade400,
          Colors.green.shade700,
          Colors.green.shade900,
        ];
      case FinanceMode.compare:
        return [
          Colors.blue.shade400,
          Colors.blue.shade700,
          Colors.blue.shade900,
        ];
    }
  }

  double get sliderValue {
    switch (this) {
      case FinanceMode.expense:
        return 0.0;
      case FinanceMode.compare:
        return 0.5;
      case FinanceMode.income:
        return 1.0;
    }
  }

  Color get gradientAppBarColor {
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
