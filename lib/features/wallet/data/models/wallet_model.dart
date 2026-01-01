// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:hive/hive.dart';

part 'wallet_model.g.dart';

@HiveType(typeId: 0)
class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.balance,
    required super.debt,
    required super.credit,
    required super.investment,
    required super.colorHex,
    required super.iconName,
    required super.createdAt,
    super.isActive = false,
    super.sortOrder = 0,
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
    );
  }

  WalletModel.fromEntity(WalletEntity entity)
      : this(
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
        );

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
    };
  }

  /// Copy with method for updates
  @override
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
  }) {
    return WalletModel(
      id: id ?? this.id, // preserve id to not change
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
    );
  }

  @override
  String toString() {
    return 'Wallet(id: $id, name: $name, balance: $balance)';
  }

  @override
  @HiveField(0)
  String? get id => super.id;
  @override
  @HiveField(1)
  String get userId => super.userId;
  @override
  @HiveField(2)
  String get name => super.name;
  @override
  @HiveField(3)
  double get balance => super.balance;
  @override
  @HiveField(4)
  double get debt => super.debt;
  @override
  @HiveField(5)
  double get credit => super.credit;
  @override
  @HiveField(6)
  double get investment => super.investment;
  @override
  @HiveField(7)
  String get colorHex => super.colorHex;
  @override
  @HiveField(8)
  String get iconName => super.iconName;
  @override
  @HiveField(9)
  DateTime get createdAt => super.createdAt;
  @override
  @HiveField(10)
  bool get isActive => super.isActive;
  @override
  @HiveField(11)
  int get sortOrder => super.sortOrder;
}
