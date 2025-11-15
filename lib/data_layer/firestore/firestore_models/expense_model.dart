// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/data_layer/firestore/cloud_const.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'expense_model.g.dart';

/// **Expense Model**: Represents an expense transaction
///
/// Storage Strategy:
/// - Hive: Stores pure DateTime (no Timestamp)
/// - Firestore: Converts DateTime ↔ Timestamp
///
/// This separation prevents Hive TypeAdapter conflicts
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

  /// ⚠️ IMPORTANT: This is DateTime for Hive compatibility
  /// Firestore conversion happens in toJson/fromJson
  @HiveField(5)
  final DateTime date;

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

  /// Creates Expense from Firestore document
  /// Converts Timestamp → DateTime
  factory Expense.fromJson(String id, Map<String, dynamic> json) {
    return Expense(
      id: id,
      userId: json[fieldUserId] ?? '',
      title: json[fieldTitle] ?? '',
      tag: json[fieldTag] ?? '',
      amount: (json[fieldAmount] as num? ?? 0.0).toDouble(),
      // ✅ Convert Firestore Timestamp to DateTime
      date: (json[fieldDate] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: json[fieldTime] ?? '',
    );
  }

  /// Converts Expense to Firestore-compatible map
  /// Converts DateTime → Timestamp
  Map<String, dynamic> toJson() {
    return {
      fieldUserId: userId,
      fieldTitle: title,
      fieldTag: tag,
      fieldAmount: amount,
      // ✅ Convert DateTime to Firestore Timestamp
      fieldDate: Timestamp.fromDate(date),
      fieldTime: time,
    };
  }

  /// Creates new Expense for local storage (Hive)
  /// Uses DateTime directly - no Timestamp involved
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
      date: date, // ✅ Pure DateTime, no conversion needed
      time: time,
    );
  }

  /// Optional: Helper to display formatted date
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Optional: Copy with method for updates
  Expense copyWith({
    String? id,
    String? userId,
    String? title,
    String? tag,
    double? amount,
    DateTime? date,
    String? time,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      time: time ?? this.time,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, date: $date)';
  }
}
