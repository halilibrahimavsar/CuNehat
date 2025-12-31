import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
part 'investment_model.g.dart';

@HiveType(typeId: 4)
class InvestmentModel extends InvestmentEntity {
  const InvestmentModel({
    required super.id,
    required super.name,
    required super.amount,
    required super.currentValue,
    required super.type,
    required super.color,
    required super.dateAdded,
    super.symbol,
    super.returnRate,
  });

  // Create Investment from firestore document
  factory InvestmentModel.fromJson(String id, Map<String, dynamic> json) {
    return InvestmentModel(
      id: id,
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      type: InvestmentType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => InvestmentType.stock,
      ),
      color: Color(json['color'] ?? 0xFF000000),
      dateAdded: DateTime.parse(json['dateAdded']),
      symbol: json['symbol'],
      returnRate: (json['returnRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  InvestmentModel.fromEntity(InvestmentEntity entity)
      : this(
          id: entity.id ?? '',
          name: entity.name,
          amount: entity.amount,
          currentValue: entity.currentValue,
          type: entity.type,
          color: entity.color,
          dateAdded: entity.dateAdded,
          symbol: entity.symbol,
          returnRate: entity.returnRate,
        );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'currentValue': currentValue,
      'type': type.toString(),
      'color': color.value,
      'dateAdded': dateAdded.toIso8601String(),
      'symbol': symbol,
      'returnRate': returnRate,
    };
  }

  //copy with method for updates
  InvestmentModel copyWith({
    String? id,
    String? name,
    double? amount,
    double? currentValue,
    InvestmentType? type,
    Color? color,
    DateTime? dateAdded,
    String? symbol,
    double? returnRate,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
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

  // double get profit => currentValue - amount;
  // double get profitPercentage => amount > 0 ? (profit / amount) * 100 : 0;
  // bool get isProfitable => profit >= 0;

  @override
  @HiveField(0)
  String? get id => super.id;
  @override
  @HiveField(1)
  String get name => super.name;
  @override
  @HiveField(2)
  double get amount => super.amount;
  @override
  @HiveField(3)
  double get currentValue => super.currentValue;
  @override
  @HiveField(4)
  InvestmentType get type => super.type;
  @override
  @HiveField(5)
  Color get color => super.color;
  @override
  @HiveField(6)
  DateTime get dateAdded => super.dateAdded;
  @override
  @HiveField(7)
  String? get symbol => super.symbol;
  @override
  @HiveField(8)
  double? get returnRate => super.returnRate;
}

/////////////////////////////////////////////////////////////////
// Mock data
List<InvestmentEntity> mockInvestments = [
  InvestmentModel(
    id: '1',
    name: 'Apple Inc.',
    amount: 50000,
    currentValue: 55000,
    type: InvestmentType.stock,
    color: Colors.green,
    dateAdded: DateTime.now().subtract(const Duration(days: 30)),
    symbol: 'AAPL',
    returnRate: 10.0,
  ),
  InvestmentModel(
    id: '2',
    name: 'Tesla Inc.',
    amount: 30000,
    currentValue: 33000,
    type: InvestmentType.stock,
    color: Colors.red,
    dateAdded: DateTime.now().subtract(const Duration(days: 60)),
    symbol: 'TSLA',
    returnRate: 10.0,
  ),
  InvestmentModel(
    id: '3',
    name: 'Altın',
    amount: 25000,
    currentValue: 27000,
    type: InvestmentType.gold,
    color: Colors.amber[700]!,
    dateAdded: DateTime.now().subtract(const Duration(days: 90)),
    returnRate: 8.0,
  ),
  InvestmentModel(
    id: '4',
    name: 'Kira Geliri',
    amount: 100000,
    currentValue: 100000,
    type: InvestmentType.custom,
    color: Colors.green,
    dateAdded: DateTime.now().subtract(const Duration(days: 120)),
    returnRate: 0.0,
  ),
  InvestmentModel(
    id: '5',
    name: 'Microsoft',
    amount: 40000,
    currentValue: 44000,
    type: InvestmentType.stock,
    color: Colors.blue,
    dateAdded: DateTime.now().subtract(const Duration(days: 45)),
    symbol: 'MSFT',
    returnRate: 10.0,
  ),
];
