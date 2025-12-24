// lib/features/transfer/domain/entities/transfer_entity.dart

import 'package:equatable/equatable.dart';

/// **Transfer Entity**: Represents money transfer between wallets
class TransferEntity extends Equatable {
  final String id;
  final String userId;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String note; // Transfer açıklaması
  final DateTime date;

  const TransferEntity({
    required this.id,
    required this.userId,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.note,
    required this.date,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        fromWalletId,
        toWalletId,
        amount,
        note,
        date,
      ];
}
