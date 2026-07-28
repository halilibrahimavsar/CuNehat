import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/approve_recurring_transaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Çapa verilmezse girdinin günü kullanılır (tek adımlık testler için).
  DateTime next(DateTime d, RecurringFrequency f, {int? anchorDay}) =>
      ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
        d,
        f,
        anchorDay: anchorDay ?? d.day,
      );

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

    test('aylık: Aralık → Ocak yıl devri', () {
      expect(next(DateTime(2026, 12, 15), RecurringFrequency.monthly),
          DateTime(2027, 1, 15));
    });

    test('yıllık: 29 Şubat → 28 Şubat (artık olmayan yıl)', () {
      expect(next(DateTime(2028, 2, 29), RecurringFrequency.yearly),
          DateTime(2029, 2, 28));
    });
  });

  group('nextExecutionDateAfter — çapa kenetleme birikimini önler', () {
    // REGRESYON: bu grup önceden kaymayı DOĞRU kabul ediyordu
    // ("ardışık onaylarda gün ayın sonunda kalır" → 28 Mar bekleniyordu).
    // Kenetleme `current.day`'den yapıldığı için kısa bir ay, ayın 29/30/31'inde
    // tekrarlayan her şablonu kalıcı olarak 28'e çekiyordu.

    test('ayın 31i: Şubat sonrası 31e geri döner', () {
      const anchor = 31;
      var d = DateTime(2026, 1, 31);
      final chain = <DateTime>[];
      for (var i = 0; i < 5; i++) {
        d = next(d, RecurringFrequency.monthly, anchorDay: anchor);
        chain.add(d);
      }
      expect(chain, [
        DateTime(2026, 2, 28), // kısa ay → kenetlenir
        DateTime(2026, 3, 31), // ama çapa korunduğu için geri döner
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 31),
        DateTime(2026, 6, 30),
      ]);
    });

    test('ayın 30u: yalnız Şubat kenetlenir, sonrası 30 kalır', () {
      const anchor = 30;
      var d = DateTime(2026, 1, 30);
      final chain = <DateTime>[];
      for (var i = 0; i < 4; i++) {
        d = next(d, RecurringFrequency.monthly, anchorDay: anchor);
        chain.add(d);
      }
      expect(chain, [
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 30),
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 30),
      ]);
    });

    test('artık yıl: 29 Şubat çapası korunur', () {
      const anchor = 29;
      var d = DateTime(2028, 1, 29);
      d = next(d, RecurringFrequency.monthly, anchorDay: anchor); // 29 Şub 2028
      expect(d, DateTime(2028, 2, 29));
      d = next(d, RecurringFrequency.monthly, anchorDay: anchor);
      expect(d, DateTime(2028, 3, 29));
    });

    test('yıllık: 29 Şubat çapası artık olmayan yılda 28e düşer, sonra döner',
        () {
      const anchor = 29;
      var d = DateTime(2028, 2, 29);
      d = next(d, RecurringFrequency.yearly, anchorDay: anchor);
      expect(d, DateTime(2029, 2, 28));
      // Çapa 29 olduğundan bir sonraki artık yılda 29a geri döner.
      d = next(d, RecurringFrequency.yearly, anchorDay: anchor);
      expect(d, DateTime(2030, 2, 28));
      d = next(d, RecurringFrequency.yearly, anchorDay: anchor);
      expect(d, DateTime(2031, 2, 28));
      d = next(d, RecurringFrequency.yearly, anchorDay: anchor);
      expect(d, DateTime(2032, 2, 29));
    });

    test('günlük/haftalık çapadan etkilenmez', () {
      expect(next(DateTime(2026, 1, 31), RecurringFrequency.daily, anchorDay: 1),
          DateTime(2026, 2, 1));
      expect(
          next(DateTime(2026, 1, 31), RecurringFrequency.weekly, anchorDay: 1),
          DateTime(2026, 2, 7));
    });
  });
}
