import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
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

  /// Cüzdanın açılış (başlangıç) bakiyesi. `balance` artımlı delta'larla
  /// güncellendiği için sapma onarımında referans olarak kullanılır:
  /// `balance = openingBalance + Σ signed(işlemler)`. Eski kayıtlarda null
  /// olabilir (lazy geri-doldurulur).
  final double? openingBalance;

  const WalletEntity({
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

  WalletEntity copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    double? debt,
    double? credit,
    double? investment,
    String? colorHex,
    String? iconName,
    DateTime? createdAt,
    bool? isActive,
    int? sortOrder,
    double? openingBalance,
  }) {
    return WalletEntity(
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
  List<Object?> get props => [
        id,
        userId,
        name,
        balance,
        debt,
        credit,
        investment,
        colorHex,
        iconName,
        createdAt,
        isActive,
        sortOrder,
        openingBalance,
      ];
}
