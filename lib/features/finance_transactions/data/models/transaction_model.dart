// lib/features/finance_transections/data/models/transaction_model.dart
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/transaction_entity.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.userId,
    required super.walletId,
    required super.title,
    required super.tag,
    required super.amount,
    required super.date,
    required super.time,
    required super.type,
  });

  factory TransactionModel.fromJson(String id, Map<String, dynamic> json) {
    return TransactionModel(
      id: id,
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

  @override
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
      'type': type == TransactionTypeModel.income ? 'income' : 'expense',
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

  TransactionEntity toEntity() {
    return TransactionEntity(
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
  }

  static TransactionTypeModel _parseTransactionType(String type) {
    return type == 'income'
        ? TransactionTypeModel.income
        : TransactionTypeModel.expense;
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
    TransactionTypeModel? type,
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

  // Hive alanlarını `TransactionEntity`'deki alanlarla eşleştirmek için
  // getter'ları override edip HiveField annotation'larını ekliyoruz.
  @override
  @HiveField(0)
  String get id => super.id;

  @override
  @HiveField(1)
  String get userId => super.userId;

  @override
  @HiveField(2)
  String get walletId => super.walletId;

  @override
  @HiveField(3)
  String get title => super.title;

  @override
  @HiveField(4)
  String get tag => super.tag;

  @override
  @HiveField(5)
  double get amount => super.amount;

  @override
  @HiveField(6)
  DateTime get date => super.date;

  @override
  @HiveField(7)
  String get time => super.time;

  @override
  @HiveField(8)
  TransactionTypeModel get type => super.type;
}
