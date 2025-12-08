import 'package:hive/hive.dart';

part 'transaction_type_enum.g.dart';

@HiveType(typeId: 2)
enum TransactionTypeModel {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}
