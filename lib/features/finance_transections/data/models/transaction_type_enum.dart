import 'package:hive/hive.dart';

@HiveType(typeId: 6)
enum TransactionType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}
