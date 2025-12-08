// ==========================================
// lib/features/transfer/data/models/transfer_model.dart

import 'package:cunehat/features/transfer/domain/entities/transfer_entity.dart';
import 'package:hive/hive.dart';

part 'transfer_model.g.dart';

@HiveType(typeId: 3)
class TransferModel extends TransferEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String userId;

  @HiveField(2)
  @override
  final String fromWalletId;

  @HiveField(3)
  @override
  final String toWalletId;

  @HiveField(4)
  @override
  final double amount;

  @HiveField(5)
  @override
  final String note;

  @HiveField(6)
  @override
  final DateTime date;

  @HiveField(7)
  @override
  final String time;

  const TransferModel({
    required this.id,
    required this.userId,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.note,
    required this.date,
    required this.time,
  }) : super(
          id: id,
          userId: userId,
          fromWalletId: fromWalletId,
          toWalletId: toWalletId,
          amount: amount,
          note: note,
          date: date,
          time: time,
        );

  factory TransferModel.fromJson(String id, Map<String, dynamic> json) {
    return TransferModel(
      id: id,
      userId: json['userId'] as String,
      fromWalletId: json['fromWalletId'] as String,
      toWalletId: json['toWalletId'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'time': time,
    };
  }

  factory TransferModel.fromEntity(TransferEntity entity) {
    return TransferModel(
      id: entity.id,
      userId: entity.userId,
      fromWalletId: entity.fromWalletId,
      toWalletId: entity.toWalletId,
      amount: entity.amount,
      note: entity.note,
      date: entity.date,
      time: entity.time,
    );
  }
}
