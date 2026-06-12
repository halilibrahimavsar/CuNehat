import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/approve_recurring_transaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime next(DateTime d, RecurringFrequency f) =>
      ApproveRecurringTransactionUsecase.nextExecutionDateAfter(d, f);

  group('nextExecutionDateAfter', () {
    test('günlük: +1 gün', () {
      expect(next(DateTime(2026, 6, 12), RecurringFrequency.daily),
          DateTime(2026, 6, 13));
    });

    test('haftalık: +7 gün', () {
      expect(next(DateTime(2026, 6, 12), RecurringFrequency.weekly),
          DateTime(2026, 6, 19));
    });

    test('aylık: 31 Ocak → 28 Şubat (Mart 2-3 kayması olmamalı)', () {
      expect(next(DateTime(2026, 1, 31), RecurringFrequency.monthly),
          DateTime(2026, 2, 28));
    });

    test('aylık: ardışık onaylarda gün ayın sonunda kalır', () {
      var d = DateTime(2026, 1, 31);
      d = next(d, RecurringFrequency.monthly); // 28 Şub
      d = next(d, RecurringFrequency.monthly); // 28 Mar
      expect(d, DateTime(2026, 3, 28));
    });

    test('aylık: Aralık → Ocak yıl devri', () {
      expect(next(DateTime(2026, 12, 15), RecurringFrequency.monthly),
          DateTime(2027, 1, 15));
    });

    test('yıllık: 29 Şubat → 28 Şubat (artık olmayan yıl)', () {
      expect(next(DateTime(2028, 2, 29), RecurringFrequency.yearly),
          DateTime(2029, 2, 28));
    });
  });
}
