import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextReminderSlot', () {
    test('vade gelecekteyse o günün sabahına kurulur', () {
      final now = DateTime(2026, 7, 25, 14, 35);
      expect(
        nextReminderSlot(DateTime(2026, 7, 28, 23, 59), now),
        DateTime(2026, 7, 28, kReminderHour),
      );
    });

    test('vade bugün ama sabah saati geçmişse yarın sabaha kurulur', () {
      // Kullanıcının kaydettiği saat (14:35) değil, hatırlatma saati esastır;
      // 09:00 geçtiği için bugüne planlanamaz ve atlanırdı.
      final now = DateTime(2026, 7, 25, 14, 35);
      expect(
        nextReminderSlot(DateTime(2026, 7, 25, 14, 35), now),
        DateTime(2026, 7, 26, kReminderHour),
      );
    });

    test('vade bugün ve sabah saati henüz gelmediyse bugüne kurulur', () {
      final now = DateTime(2026, 7, 25, 7, 0);
      expect(
        nextReminderSlot(DateTime(2026, 7, 25, 14, 35), now),
        DateTime(2026, 7, 25, kReminderHour),
      );
    });

    test('çok gecikmiş vade de bir sonraki sabaha kurulur', () {
      final now = DateTime(2026, 7, 25, 14, 35);
      expect(
        nextReminderSlot(DateTime(2024, 1, 1), now),
        DateTime(2026, 7, 26, kReminderHour),
      );
    });

    test('ay sonunda gün taşması takvimden normalize edilir', () {
      final now = DateTime(2026, 7, 31, 20, 0);
      expect(
        nextReminderSlot(DateTime(2026, 7, 31), now),
        DateTime(2026, 8, 1, kReminderHour),
      );
    });

    test('sonuç her zaman şimdiden sonradır', () {
      final now = DateTime(2026, 7, 25, 8, 59, 59);
      expect(
        nextReminderSlot(DateTime(2026, 7, 25), now).isAfter(now),
        isTrue,
      );
    });
  });
}
