// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'wallet_model.g.dart';

/// **Wallet Model**: Represents a wallet/account
///
/// Each user can have multiple wallets for organizing finances
/// Example: "Ana Cüzdan", "Tatil Fonu", "Acil Durum"
@HiveType(typeId: 0)
class WalletModel extends HiveObject {
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
  final bool isActive; // Is this the currently active wallet?

  @HiveField(8)
  final int sortOrder; // Display order

  WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    this.isActive = false,
    this.sortOrder = 0,
  });

  /// Creates Wallet from Firestore document
  factory WalletModel.fromJson(String id, Map<String, dynamic> json) {
    return WalletModel(
      id: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Cüzdan',
      balance: (json['balance'] as num? ?? 0.0).toDouble(),
      colorHex: json['colorHex'] ?? '0xFF2196F3',
      iconName: json['iconName'] ?? 'wallet',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? false,
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
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }

  /// Creates new Wallet for local storage
  factory WalletModel.createLocal({
    required String userId,
    required String name,
    double balance = 0.0,
    String? colorHex,
    String? iconName,
    bool isActive = false,
    int sortOrder = 0,
  }) {
    return WalletModel(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      balance: balance,
      colorHex: colorHex ?? '0xFF2196F3',
      iconName: iconName ?? 'wallet',
      createdAt: DateTime.now(),
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }

  /// Copy with method for updates
  WalletModel copyWith({
    String? name,
    double? balance,
    String? colorHex,
    String? iconName,
    bool? isActive,
    int? sortOrder,
  }) {
    return WalletModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'Wallet(id: $id, name: $name, balance: $balance)';
  }
}
