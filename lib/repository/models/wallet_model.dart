// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'wallet_model.g.dart';

/// **Wallet Model**: Represents a wallet/account
///
/// Each user can have multiple wallets for organizing finances
/// Example: "Ana Cüzdan", "Tatil Fonu", "Acil Durum"
@HiveType(typeId: 3)
class Wallet extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name; // "Ana Cüzdan", "Tatil Fonu"

  @HiveField(3)
  final double balance;

  @HiveField(4)
  final String colorHex; // UI color: "0xFFFF5722"

  @HiveField(5)
  final String iconName; // Icon identifier: "wallet", "savings", "emergency"

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final bool isDefault; // Is this the default wallet?

  @HiveField(8)
  final int sortOrder; // Display order

  Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  /// Creates Wallet from Firestore document
  factory Wallet.fromJson(String id, Map<String, dynamic> json) {
    return Wallet(
      id: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Cüzdan',
      balance: (json['balance'] as num? ?? 0.0).toDouble(),
      colorHex: json['colorHex'] ?? '0xFF2196F3',
      iconName: json['iconName'] ?? 'wallet',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDefault: json['isDefault'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  /// Converts Wallet to Firestore-compatible map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'balance': balance,
      'colorHex': colorHex,
      'iconName': iconName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  /// Creates new Wallet for local storage
  factory Wallet.createLocal({
    required String userId,
    required String name,
    double balance = 0.0,
    String? colorHex,
    String? iconName,
    bool isDefault = false,
    int sortOrder = 0,
  }) {
    return Wallet(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      balance: balance,
      colorHex: colorHex ?? '0xFF2196F3',
      iconName: iconName ?? 'wallet',
      createdAt: DateTime.now(),
      isDefault: isDefault,
      sortOrder: sortOrder,
    );
  }

  /// Copy with method for updates
  Wallet copyWith({
    String? name,
    double? balance,
    String? colorHex,
    String? iconName,
    bool? isDefault,
    int? sortOrder,
  }) {
    return Wallet(
      id: id,
      userId: userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'Wallet(id: $id, name: $name, balance: $balance)';
  }
}
