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
  final double? targetAmount;

  /// Toplam birim (gram/lot/adet). null = miktar takibi olmayan yatırım
  /// (ör. özel varlık).
  final double? quantity;

  /// Hedef kategorisi anahtarı (ev, dugun, araba, acil_fon, egitim, diger).
  final String? goalCategory;

  /// Fiyat kaynağının para birimi (örn. 'TRY', 'USD'). null ⇒ TRY varsayılır.
  final String? currency;

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
    this.targetAmount,
    this.quantity,
    this.goalCategory,
    this.currency,
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
    double? targetAmount,
    double? quantity,
    String? goalCategory,
    String? currency,
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
      targetAmount: targetAmount ?? this.targetAmount,
      quantity: quantity ?? this.quantity,
      goalCategory: goalCategory ?? this.goalCategory,
      currency: currency ?? this.currency,
    );
  }

  double get profit => currentValue - amount;
  double get profitPercentage => amount > 0 ? (profit / amount) * 100 : 0;
  bool get isProfitable => profit >= 0;

  double get targetProgress {
    if (targetAmount == null || targetAmount! <= 0) return 0.0;
    return (currentValue / targetAmount!).clamp(0.0, 1.0);
  }

  bool get isTargetReached =>
      targetAmount != null &&
      targetAmount! > 0 &&
      currentValue >= targetAmount!;

  bool get isGoal => targetAmount != null && targetAmount! > 0;

  /// Birim başına güncel değer; miktar takibi yoksa null.
  double? get unitValue =>
      (quantity != null && quantity! > 0) ? currentValue / quantity! : null;

  /// Fiyat yenileme yalnızca sembollü ve miktarı bilinen kayıtlarda mümkün.
  bool get canRefreshPrice =>
      symbol != null && quantity != null && quantity! > 0;

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
        targetAmount,
        quantity,
        goalCategory,
        currency,
      ];
}
