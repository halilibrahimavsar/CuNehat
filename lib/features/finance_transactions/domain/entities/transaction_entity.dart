import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String? id;
  final String userId;
  final String walletId;
  final String title;
  final String tag;
  final double amount;
  final DateTime date;
  final String time;
  final TransactionTypeModel type;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
    required this.type,
  });

  TransactionEntity copyWith({
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
    return TransactionEntity(
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

  bool get isIncome => type == TransactionTypeModel.income;
  bool get isExpense => type == TransactionTypeModel.expense;

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
      'type': type.name,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        title,
        tag,
        amount,
        date,
        time,
        type,
      ];
}
