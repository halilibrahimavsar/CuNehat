import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
part 'investment_model.g.dart';

@HiveType(typeId: 4)
class InvestmentModel extends InvestmentEntity {
  const InvestmentModel({
    required super.id,
    required super.userId,
    required super.walletId,
    required super.name,
    required super.amount,
    required super.currentValue,
    required super.type,
    required super.color,
    required super.dateAdded,
    super.symbol,
    super.returnRate,
    super.targetAmount,
    super.quantity,
    super.goalCategory,
    super.currency,
  });

  // Create Investment from firestore document
  factory InvestmentModel.fromJson(String id, Map<String, dynamic> json) {
    return InvestmentModel(
      id: id,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      type: InvestmentType.values
          .firstWhere((type) => type.toString() == json['type']),
      color: Color(json['color'] as int),
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      symbol: json['symbol'] as String?,
      returnRate: (json['returnRate'] as num?)?.toDouble(),
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble(),
      goalCategory: json['goalCategory'] as String?,
      currency: json['currency'] as String?,
    );
  }

  InvestmentModel.fromEntity(InvestmentEntity entity)
      : this(
          id: entity.id ?? '',
          userId: entity.userId,
          walletId: entity.walletId,
          name: entity.name,
          amount: entity.amount,
          currentValue: entity.currentValue,
          type: entity.type,
          color: entity.color,
          dateAdded: entity.dateAdded,
          symbol: entity.symbol,
          returnRate: entity.returnRate,
          targetAmount: entity.targetAmount,
          quantity: entity.quantity,
          goalCategory: entity.goalCategory,
          currency: entity.currency,
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'name': name,
      'amount': amount,
      'currentValue': currentValue,
      'type': type.toString(),
      'color': color.toARGB32(),
      'dateAdded': dateAdded.toIso8601String(),
      'symbol': symbol,
      'returnRate': returnRate,
      'targetAmount': targetAmount,
      'quantity': quantity,
      'goalCategory': goalCategory,
      'currency': currency,
    };
  }

  //copy with method for updates
  @override
  InvestmentModel copyWith({
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
    return InvestmentModel(
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

  @override
  @HiveField(0)
  String? get id => super.id;
  @override
  @HiveField(1)
  String get userId => super.userId;
  @override
  @HiveField(2)
  String get walletId => super.walletId;
  @override
  @HiveField(3)
  String get name => super.name;
  @override
  @HiveField(4)
  double get amount => super.amount;
  @override
  @HiveField(5)
  double get currentValue => super.currentValue;
  @override
  @HiveField(6)
  InvestmentType get type => super.type;
  @override
  @HiveField(7)
  Color get color => super.color;
  @override
  @HiveField(8)
  DateTime get dateAdded => super.dateAdded;
  @override
  @HiveField(9)
  String? get symbol => super.symbol;
  @override
  @HiveField(10)
  double? get returnRate => super.returnRate;

  @override
  @HiveField(11)
  double? get targetAmount => super.targetAmount;

  @override
  @HiveField(12)
  double? get quantity => super.quantity;

  @override
  @HiveField(13)
  String? get goalCategory => super.goalCategory;

  @override
  @HiveField(14)
  String? get currency => super.currency;
}
