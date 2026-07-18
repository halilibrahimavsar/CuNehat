import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:hive/hive.dart';

class WalletModel {
  final String? id;
  final String userId;
  final String name;
  final double balance;
  final double debt;
  final double credit;
  final double investment;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final bool isActive;
  final int sortOrder;
  final double openingBalance;
  final String currency;

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
    required this.openingBalance,
    this.currency = 'TRY',
  });

  /// Creates Wallet from JSON Map
  factory WalletModel.fromJson(String id, Map<String, dynamic> json) {
    return WalletModel(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      debt: (json['debt'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      investment: (json['investment'] as num).toDouble(),
      colorHex: json['colorHex'] as String,
      iconName: json['iconName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
      sortOrder: json['sortOrder'] as int,
      openingBalance: (json['openingBalance'] as num).toDouble(),
      currency: json['currency'] as String,
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
      currency: entity.currency,
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
      currency: currency,
    );
  }

  /// Converts Wallet to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'balance': balance,
      'debt': debt,
      'credit': credit,
      'investment': investment,
      'colorHex': colorHex,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'sortOrder': sortOrder,
      'openingBalance': openingBalance,
      'currency': currency,
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
    String? currency,
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
      currency: currency ?? this.currency,
    );
  }

  @override
  String toString() {
    return 'WalletModel(id: $id, name: $name, balance: $balance)';
  }
}

class WalletModelAdapter extends TypeAdapter<WalletModel> {
  @override
  final int typeId = 0;

  @override
  WalletModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return WalletModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      name: fields[2] as String,
      balance: (fields[3] as num).toDouble(),
      debt: (fields[4] as num).toDouble(),
      credit: (fields[5] as num).toDouble(),
      investment: (fields[6] as num).toDouble(),
      colorHex: fields[7] as String,
      iconName: fields[8] as String,
      createdAt: fields[9] as DateTime,
      isActive: fields[10] as bool,
      sortOrder: fields[11] as int,
      openingBalance: (fields[12] as num).toDouble(),
      currency: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WalletModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.debt)
      ..writeByte(5)
      ..write(obj.credit)
      ..writeByte(6)
      ..write(obj.investment)
      ..writeByte(7)
      ..write(obj.colorHex)
      ..writeByte(8)
      ..write(obj.iconName)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.sortOrder)
      ..writeByte(12)
      ..write(obj.openingBalance)
      ..writeByte(13)
      ..write(obj.currency);
  }
}
