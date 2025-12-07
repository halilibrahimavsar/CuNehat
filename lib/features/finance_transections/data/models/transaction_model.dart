// lib/features/transaction/data/models/transaction_model.dart
import 'package:hive/hive.dart';
import '../../domain/entities/transaction_entity.dart';

part 'transaction_model.g.dart'; // Build runner ile oluşturulacak

@HiveType(typeId: 5) // TypeId 5 kullanıyoruz
class TransactionModel extends TransactionEntity {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String userId;

  @HiveField(2)
  @override
  final String walletId;

  @HiveField(3)
  @override
  final String title;

  @HiveField(4)
  @override
  final String tag;

  @HiveField(5)
  @override
  final double amount;

  @HiveField(6)
  @override
  final DateTime date;

  @HiveField(7)
  @override
  final String time;

  @HiveField(8)
  @override
  final TransactionType type;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
    required this.type,
  }) : super(
          id: id,
          userId: userId,
          walletId: walletId,
          title: title,
          tag: tag,
          amount: amount,
          date: date,
          time: time,
          type: type,
        );

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      walletId: json['walletId'] as String,
      title: json['title'] as String,
      tag: json['tag'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      type: _parseTransactionType(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'walletId': walletId,
      'title': title,
      'tag': tag,
      'amount': amount,
      'date': date.toIso8601String(),
      'time': time,
      'type': type == TransactionType.income ? 'income' : 'expense',
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      walletId: entity.walletId,
      title: entity.title,
      tag: entity.tag,
      amount: entity.amount,
      date: entity.date,
      time: entity.time,
      type: entity.type,
    );
  }

  static TransactionType _parseTransactionType(String type) {
    return type == 'income' ? TransactionType.income : TransactionType.expense;
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    String? tag,
    double? amount,
    DateTime? date,
    String? time,
    TransactionType? type,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
    );
  }
}
