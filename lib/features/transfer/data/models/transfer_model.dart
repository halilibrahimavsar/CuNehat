// ==========================================
// lib/features/transfer/data/models/transfer_model.dart

import 'package:cunehat/features/transfer/domain/entities/transfer_entity.dart';
import 'package:hive/hive.dart';

part 'transfer_model.g.dart';

@HiveType(typeId: 3)
class TransferModel extends TransferEntity {
  @HiveField(0)
  @override
  String get id => super.id;

  @HiveField(1)
  @override
  String get userId => super.userId;

  @HiveField(2)
  @override
  String get fromWalletId => super.fromWalletId;

  @HiveField(3)
  @override
  String get toWalletId => super.toWalletId;

  @HiveField(4)
  @override
  double get amount => super.amount;

  @HiveField(5)
  @override
  String get note => super.note;

  @HiveField(6)
  @override
  DateTime get date => super.date;

  const TransferModel({
    required super.id,
    required super.userId,
    required super.fromWalletId,
    required super.toWalletId,
    required super.amount,
    required super.note,
    required super.date,
  });

  factory TransferModel.fromJson(String id, Map<String, dynamic> json) {
    return TransferModel(
      id: id,
      userId: json['userId'] as String,
      fromWalletId: json['fromWalletId'] as String,
      toWalletId: json['toWalletId'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String,
      date: DateTime.parse(json['date'] as String),
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
    );
  }
}
