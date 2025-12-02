// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/core/constants/repository_constants.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 1)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String tag;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final String time;

  @HiveField(7) // ⚠️ NEW FIELD
  final String walletId;

  Expense({
    required this.id,
    required this.userId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
    required this.walletId,
  });

  factory Expense.fromJson(String id, Map<String, dynamic> json) {
    return Expense(
      id: id,
      userId: json[fieldUserId] ?? '',
      title: json[fieldTitle] ?? '',
      tag: json[fieldTag] ?? '',
      amount: (json[fieldAmount] as num? ?? 0.0).toDouble(),
      date: (json[fieldDate] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: json[fieldTime] ?? '',
      walletId:
          json['walletId'] ?? 'default_wallet', // ⚠️ Backward compatibility
    );
  }

  Map<String, dynamic> toJson() {
    return {
      fieldUserId: userId,
      fieldTitle: title,
      fieldTag: tag,
      fieldAmount: amount,
      fieldDate: Timestamp.fromDate(date),
      fieldTime: time,
      'walletId': walletId, // ⚠️ NEW FIELD
    };
  }

  factory Expense.createLocal({
    required String userId,
    required String title,
    required String tag,
    required double amount,
    required DateTime date,
    required String time,
    required String walletId, // ⚠️ NEW PARAMETER
  }) {
    return Expense(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      tag: tag,
      amount: amount,
      date: date,
      time: time,
      walletId: walletId,
    );
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  Expense copyWith({
    String? id,
    String? userId,
    String? title,
    String? tag,
    double? amount,
    DateTime? date,
    String? time,
    String? walletId,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
      walletId: walletId ?? this.walletId,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, walletId: $walletId)';
  }
}
