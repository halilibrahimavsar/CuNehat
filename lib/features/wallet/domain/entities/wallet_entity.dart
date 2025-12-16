import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final double balance;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final bool isActive;
  final int sortOrder;

  const WalletEntity({
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

  WalletEntity copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    String? colorHex,
    String? iconName,
    DateTime? createdAt,
    bool? isActive,
    int? sortOrder,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        balance,
        colorHex,
        iconName,
        createdAt,
        isActive,
        sortOrder,
      ];
}
