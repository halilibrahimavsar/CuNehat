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

  group('isRecurringDue', () {
    test('duraklatılmış şablon vadesi geçmiş olsa da vadesi gelmiş sayılmaz',
        () {
      expect(
        isRecurringDue(
          isActive: false,
          nextExecutionDate: DateTime(2026, 1, 1),
          now: now,
        ),
        isFalse,
      );
    });

    test('tam vade anı vadesi gelmiş sayılır (sınır dahil)', () {
      expect(
        isRecurringDue(isActive: true, nextExecutionDate: now, now: now),
        isTrue,
      );
    });

    test('gelecekteki vade sayılmaz', () {
      expect(
        isRecurringDue(
          isActive: true,
          nextExecutionDate: now.add(const Duration(seconds: 1)),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('monthlyEquivalent', () {
    test('aylık şablon olduğu gibi kalır', () {
      expect(
        RecurringOccurrences.monthlyEquivalent(100, RecurringFrequency.monthly),
        100,
      );
    });

    test('yıllık şablon 12\'ye bölünür', () {
      expect(
        RecurringOccurrences.monthlyEquivalent(1200, RecurringFrequency.yearly),
        100,
      );
    });

    test('günlük ve haftalık ortalama ay uzunluğuyla ölçeklenir', () {
      // 30 veya 31 sabitlemek yıl boyunca birikimli sapma yaratır; ortalama
      // ay 365.2425/12 = 30.436875 gün.
      expect(
        RecurringOccurrences.monthlyEquivalent(10, RecurringFrequency.daily),
        closeTo(304.37, 0.01),
      );
      expect(
        RecurringOccurrences.monthlyEquivalent(70, RecurringFrequency.weekly),
        closeTo(304.37, 0.01),
      );
    });
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
