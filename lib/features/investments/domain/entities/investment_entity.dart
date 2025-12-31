import 'dart:ui';

enum InvestmentType {
  stock,
  gold,
  custom,
}

class InvestmentEntity {
  final String? id;
  final String name;
  final double amount;
  final double currentValue;
  final InvestmentType type;
  final Color color;
  final DateTime dateAdded;
  final String? symbol;
  final double? returnRate;

  const InvestmentEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.currentValue,
    required this.type,
    required this.color,
    required this.dateAdded,
    this.symbol,
    this.returnRate,
  });

  double get profit => currentValue - amount;
  double get profitPercentage => amount > 0 ? (profit / amount) * 100 : 0;
  bool get isProfitable => profit >= 0;
}
