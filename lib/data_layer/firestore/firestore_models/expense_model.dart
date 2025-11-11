// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/data_layer/firestore/cloud_const.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'expense_model.g.dart';

// typeId'nin Income'dan (0) farklı olması gerekir.
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
  final DateTime date; // Timestamp yerine DateTime

  @HiveField(6)
  final String time;

  Expense({
    required this.id,
    required this.userId,
    required this.title,
    required this.tag,
    required this.amount,
    required this.date,
    required this.time,
  });

  // Firestore'dan okumak için
  factory Expense.fromJson(String id, Map<String, dynamic> json) {
    return Expense(
      id: id,
      userId: json[fieldUserId] ?? '',
      title: json[fieldTitle] ?? '',
      tag: json[fieldTag] ?? '',
      amount: (json[fieldAmount] as num? ?? 0.0).toDouble(),
      date: (json[fieldDate] as Timestamp? ?? Timestamp.now()).toDate(),
      time: json[fieldTime] ?? '',
    );
  }

  // Firestore'a yazmak için
  Map<String, dynamic> toJson() {
    return {
      fieldUserId: userId,
      fieldTitle: title,
      fieldTag: tag,
      fieldAmount: amount,
      fieldDate: Timestamp.fromDate(date),
      fieldTime: time,
    };
  }

  // Yerel (Hive) oluşturmak için
  factory Expense.createLocal({
    required String userId,
    required String title,
    required String tag,
    required double amount,
    required DateTime date,
    required String time,
  }) {
    return Expense(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      tag: tag,
      amount: amount,
      date: date,
      time: time,
    );
  }
}
