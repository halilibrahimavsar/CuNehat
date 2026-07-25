import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_occurrences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RecurringTransactionEntity template({
    required RecurringFrequency frequency,
    required DateTime next,
  }) =>
      RecurringTransactionEntity(
        id: 'rec_1',
        userId: 'u',
        walletId: 'w',
        title: 'Netflix',
        tag: 'Abonelik',
        amount: 100,
        type: TransactionTypeModel.expense,
        frequency: frequency,
        nextExecutionDate: next,
      );

  final now = DateTime(2026, 7, 25, 12);

  test('vadesi gelmemiş şablonda 0 döner', () {
    expect(
      RecurringOccurrences.dueCount(
        template(
            frequency: RecurringFrequency.monthly, next: DateTime(2026, 8, 1)),
        now,
      ),
      0,
    );
  });

  test('vadesi tam bugün olan şablonda 1 döner', () {
    expect(
      RecurringOccurrences.dueCount(
        template(
            frequency: RecurringFrequency.monthly, next: DateTime(2026, 7, 25)),
        now,
      ),
      1,
    );
  });

  test('günlük şablonda birikmiş gün sayısını verir', () {
    // 20 Tem → 25 Tem arası 6 vade (20,21,22,23,24,25)
    expect(
      RecurringOccurrences.dueCount(
        template(
            frequency: RecurringFrequency.daily, next: DateTime(2026, 7, 20)),
        now,
      ),
      6,
    );
  });

  test('aylık şablonda birikmiş ay sayısını verir', () {
    // 20 Nis, 20 May, 20 Haz, 20 Tem
    expect(
      RecurringOccurrences.dueCount(
        template(
            frequency: RecurringFrequency.monthly, next: DateTime(2026, 4, 20)),
        now,
      ),
      4,
    );
  });

  test('çok eski tarihte güvenlik tavanında durur (sonsuz döngü yok)', () {
    expect(
      RecurringOccurrences.dueCount(
        template(
            frequency: RecurringFrequency.daily, next: DateTime(1990, 1, 1)),
        now,
      ),
      RecurringOccurrences.maxBacklog,
    );
  });
}
