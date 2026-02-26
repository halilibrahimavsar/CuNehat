import 'dart:ui';
import 'package:equatable/equatable.dart';

enum InvestmentType {
  stock,
  gold,
  custom,
}

class InvestmentEntity extends Equatable {
  final String? id;
  final String userId;
  final String walletId;
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
    required this.userId,
    required this.walletId,
    required this.name,
    required this.amount,
    required this.currentValue,
    required this.type,
    required this.color,
    required this.dateAdded,
    this.symbol,
    this.returnRate,
  });

  InvestmentEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? name,
    double? amount,
    double? currentValue,
    InvestmentType? type,
    Color? color,
    DateTime? dateAdded,
    String? symbol,
    double? returnRate,
  }) {
    return InvestmentEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currentValue: currentValue ?? this.currentValue,
      type: type ?? this.type,
      color: color ?? this.color,
      dateAdded: dateAdded ?? this.dateAdded,
      symbol: symbol ?? this.symbol,
      returnRate: returnRate ?? this.returnRate,
    );
  }

  double get profit => currentValue - amount;
  double get profitPercentage => amount > 0 ? (profit / amount) * 100 : 0;
  bool get isProfitable => profit >= 0;

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        name,
        amount,
        currentValue,
        type,
        color,
        dateAdded,
        symbol,
        returnRate,
      ];
}
