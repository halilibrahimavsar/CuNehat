// lib/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
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
