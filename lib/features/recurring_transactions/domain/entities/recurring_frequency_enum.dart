// lib/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart

import 'package:hive/hive.dart';

part 'recurring_frequency_enum.g.dart';

// Hive adapter'sız enum, RecurringTransactionModel yazımını "unknown type"
// hatasıyla düşürür; transaction_type_enum ile aynı desen.
@HiveType(typeId: 13)
enum RecurringFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly;

  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Günlük';
      case RecurringFrequency.weekly:
        return 'Haftalık';
      case RecurringFrequency.monthly:
        return 'Aylık';
      case RecurringFrequency.yearly:
        return 'Yıllık';
    }
  }
}
