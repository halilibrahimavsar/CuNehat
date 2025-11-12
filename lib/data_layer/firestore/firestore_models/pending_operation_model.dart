import 'package:hive/hive.dart';

part 'pending_operation_model.g.dart';

/// Çevrimdışı yapılan işlemleri saklar
@HiveType(typeId: 2)
class PendingOperation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String
      operationType; // 'add_income', 'add_expense', 'delete_income', 'delete_expense', 'update_income', 'update_expense'

  @HiveField(2)
  final Map<String, dynamic> data;

  @HiveField(3)
  final DateTime timestamp;

  PendingOperation({
    required this.id,
    required this.operationType,
    required this.data,
    required this.timestamp,
  });

  factory PendingOperation.create({
    required String operationType,
    required Map<String, dynamic> data,
  }) {
    return PendingOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operationType: operationType,
      data: data,
      timestamp: DateTime.now(),
    );
  }
}
