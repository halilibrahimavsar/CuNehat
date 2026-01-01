import 'package:hive/hive.dart';
part 'receivable_model.g.dart';

@HiveType(typeId: 7)
class Receivable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String walletId;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String fromPerson;

  @HiveField(5)
  final double amount;

  @HiveField(6)
  final DateTime expectedDate;

  @HiveField(7)
  final DateTime? receivedDate;

  @HiveField(8)
  final bool isReceived;

  @HiveField(9)
  final String? notes;

  Receivable({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.title,
    required this.fromPerson,
    required this.amount,
    required this.expectedDate,
    this.receivedDate,
    this.isReceived = false,
    this.notes,
  });
}
