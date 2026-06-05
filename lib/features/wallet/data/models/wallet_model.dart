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

  /// Creates Wallet from JSON Map
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
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
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

  /// Converts Wallet to JSON Map
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
      'createdAt': createdAt.toIso8601String(),
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

class WalletModelAdapter extends TypeAdapter<WalletModel> {
  @override
  final int typeId = 0;

  @override
  WalletModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final isOldSchema = !fields.containsKey(9);

    final String? id = fields[0] is String ? fields[0] as String : null;
    final String userId = fields[1] is String ? fields[1] as String : 'local_user';
    final String name = fields[2] is String ? fields[2] as String : '';
    final double balance = parseDouble(fields[3]);

    final double debt;
    final double credit;
    final double investment;
    final String colorHex;
    final String iconName;
    final DateTime createdAt;
    final bool isActive;
    final int sortOrder;
    final double? openingBalance;

    if (isOldSchema) {
      debt = 0.0;
      credit = 0.0;
      investment = 0.0;
      colorHex = fields[4] is String ? fields[4] as String : '0xFF2196F3';
      iconName = fields[5] is String ? fields[5] as String : 'wallet';
      createdAt = fields[6] is DateTime ? fields[6] as DateTime : DateTime.now();
      isActive = fields[7] is bool ? fields[7] as bool : false;
      sortOrder = fields[8] is int ? fields[8] as int : 0;
      openingBalance = null;
    } else {
      debt = parseDouble(fields[4]);
      credit = parseDouble(fields[5]);
      investment = parseDouble(fields[6]);
      colorHex = fields[7] is String ? fields[7] as String : '0xFF2196F3';
      iconName = fields[8] is String ? fields[8] as String : 'wallet';
      createdAt = fields[9] is DateTime ? fields[9] as DateTime : DateTime.now();
      isActive = fields[10] is bool ? fields[10] as bool : false;
      sortOrder = fields[11] is int ? fields[11] as int : 0;
      openingBalance = fields[12] != null ? parseDouble(fields[12]) : null;
    }

    return WalletModel(
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

  @override
  void write(BinaryWriter writer, WalletModel obj) {
    writer
      ..writeByte(13)
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
      ..write(obj.openingBalance);
  }
}
