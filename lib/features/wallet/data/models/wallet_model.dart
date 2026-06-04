// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:hive/hive.dart';

part 'wallet_model.g.dart';

@HiveType(typeId: 0)
class WalletModel {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final double balance;
  @HiveField(4)
  final double debt;
  @HiveField(5)
  final double credit;
  @HiveField(6)
  final double investment;
  @HiveField(7)
  final String colorHex;
  @HiveField(8)
  final String iconName;
  @HiveField(9)
  final DateTime createdAt;
  @HiveField(10)
  final bool isActive;
  @HiveField(11)
  final int sortOrder;
  @HiveField(12)
  final double? openingBalance;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.debt,
    required this.credit,
    required this.investment,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    this.isActive = false,
    this.sortOrder = 0,
    this.openingBalance,
  });

  /// Creates Wallet from Firestore document
  factory WalletModel.fromJson(String id, Map<String, dynamic> json) {
    return WalletModel(
      id: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Cüzdan',
      balance: (json['balance'] as num? ?? 0.0).toDouble(),
      debt: (json['debt'] as num? ?? 0.0).toDouble(),
      credit: (json['credit'] as num? ?? 0.0).toDouble(),
      investment: (json['save'] as num? ?? 0.0).toDouble(),
      colorHex: json['colorHex'] ?? '0xFF2196F3',
      iconName: json['iconName'] ?? 'wallet',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      openingBalance: (json['openingBalance'] as num?)?.toDouble(),
    );
  }

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      balance: entity.balance,
      debt: entity.debt,
      credit: entity.credit,
      investment: entity.investment,
      colorHex: entity.colorHex,
      iconName: entity.iconName,
      createdAt: entity.createdAt,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
      openingBalance: entity.openingBalance,
    );
  }

  WalletEntity toEntity() {
    return WalletEntity(
      id: id,
      userId: userId,
      name: name,
      balance: balance,
      debt: debt,
      credit: credit,
      investment: investment,
      colorHex: colorHex,
      iconName: iconName,
      createdAt: createdAt,
      isActive: isActive,
      sortOrder: sortOrder,
      openingBalance: openingBalance,
    );
  }

  /// Converts Wallet to Firestore-compatible map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'balance': balance,
      'debt': debt,
      'credit': credit,
      'save': investment,
      'colorHex': colorHex,
      'iconName': iconName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'sortOrder': sortOrder,
      'openingBalance': openingBalance,
    };
  }

  /// Copy with method for updates
  WalletModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    double? debt,
    double? credit,
    double? investment,
    String? colorHex,
    String? iconName,
    bool? isActive,
    DateTime? createdAt,
    int? sortOrder,
    double? openingBalance,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      debt: debt ?? this.debt,
      credit: credit ?? this.credit,
      investment: investment ?? this.investment,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      openingBalance: openingBalance ?? this.openingBalance,
    );
  }

  @override
  String toString() {
    return 'WalletModel(id: $id, name: $name, balance: $balance)';
  }
}
