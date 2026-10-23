import 'package:cunehat/features/finance_transactions/data/period_preferences_store.dart';
import 'package:cunehat/features/finance_transactions/domain/period_preferences.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  void expectRange(DateTimeRange r, DateTime start, DateTime lastDay) {
    expect(r.start, start);
    expect(isSameDayValue(r.end, lastDay), isTrue,
        reason: 'son gün ${r.end}, beklenen $lastDay');
    expect(r.end.hour, 23);
  }

  group('hafta', () {
    test('Çarşamba başlangıçlı hafta Çarşamba–Salı', () {
      const p = PeriodPreferences(
          unit: PeriodUnit.week, weekStart: DateTime.wednesday);
      // 25 Eyl 2026 Cuma → 23 Eyl Çarşamba – 29 Eyl Salı.
      expectRange(p.periodContaining(DateTime(2026, 9, 25)),
          DateTime(2026, 9, 23), DateTime(2026, 9, 29));
      // Başlangıç gününün kendisi kendi haftasındadır.
      expectRange(p.periodContaining(DateTime(2026, 9, 23)),
          DateTime(2026, 9, 23), DateTime(2026, 9, 29));
      // Bir gün öncesi (Salı) önceki haftanın son günü.
      expectRange(p.periodContaining(DateTime(2026, 9, 22)),
          DateTime(2026, 9, 16), DateTime(2026, 9, 22));
    });
  });

  group('2 hafta', () {
    test('ödeme gününe hizalanır; ödeme gününden ÖNCEKİ tarih de doğru', () {
      final p = PeriodPreferences(
          unit: PeriodUnit.biweek, biweekAnchor: DateTime(2026, 9, 4));
      expectRange(p.periodContaining(DateTime(2026, 9, 20)),
          DateTime(2026, 9, 18), DateTime(2026, 10, 1));
      expectRange(p.periodContaining(DateTime(2026, 9, 1)),
          DateTime(2026, 8, 21), DateTime(2026, 9, 3));
    });
  });

  group('ay', () {
    test('15\'inde başlayan ay 15–14; yıl devri doğru', () {
      const p = PeriodPreferences(unit: PeriodUnit.month, monthStartDay: 15);
      expectRange(p.periodContaining(DateTime(2026, 9, 25)),
          DateTime(2026, 9, 15), DateTime(2026, 10, 14));
      expectRange(p.periodContaining(DateTime(2026, 9, 3)),
          DateTime(2026, 8, 15), DateTime(2026, 9, 14));
      expectRange(p.periodContaining(DateTime(2027, 1, 5)),
          DateTime(2026, 12, 15), DateTime(2027, 1, 14));
    });

    test('varsayılan (1\'i) takvim ayıdır', () {
      expectRange(
          PeriodPreferences.calendarMonth
              .periodContaining(DateTime(2026, 2, 9)),
          DateTime(2026, 2, 1),
          DateTime(2026, 2, 28));
    });
  });

  test('adım: dönemler BİTİŞİK kayar (ay uzunlukları farklı olsa da)', () {
    const p = PeriodPreferences(unit: PeriodUnit.month, monthStartDay: 31 - 3);
    var r = p.periodContaining(DateTime(2026, 1, 30)); // 28 Oca – 27 Şub
    for (var i = 0; i < 14; i++) {
      final next = p.step(r, 1);
      expect(
          dayOf(next.start), DateTime(r.end.year, r.end.month, r.end.day + 1));
      r = next;
    }
    final back = p.step(r, -14);
    expect(back.start, DateTime(2026, 1, 28));
  });

  group('kalıcılık', () {
    test('yaz → oku aynı tercihi verir', () async {
      SharedPreferences.setMockInitialValues({});
      final store =
          PeriodPreferencesStore(await SharedPreferences.getInstance());
      final p = PeriodPreferences(
        unit: PeriodUnit.biweek,
        weekStart: DateTime.wednesday,
        biweekAnchor: DateTime(2026, 9, 4),
        monthStartDay: 15,
      );
      await store.write(p);
      expect(store.read(), p);
    });

    test('bozuk değerler varsayılana düşer', () async {
      SharedPreferences.setMockInitialValues({
        PeriodPreferencesStore.unitKey: 'fortnight?',
        PeriodPreferencesStore.weekStartKey: 9,
        PeriodPreferencesStore.monthStartDayKey: 31,
        PeriodPreferencesStore.biweekAnchorKey: 'x',
      });
      final store =
          PeriodPreferencesStore(await SharedPreferences.getInstance());
      expect(store.read(), PeriodPreferences.calendarMonth);
    });
  });

  group('süzgeç (TransactionFilterCubit)', () {
    const wed =
        PeriodPreferences(unit: PeriodUnit.week, weekStart: DateTime.wednesday);

    test('varsayılan dönemdeyken tercih uygulanır; oklar birimle kayar', () {
      final cubit = TransactionFilterCubit()..usePeriodPreferences(wed);
      final now = wed.periodContaining(DateTime.now());
      expect(cubit.period.start, now.start);
      expect(cubit.isDefaultPeriod, isTrue);

      cubit.stepPeriod(-1);
      expect(cubit.period.start,
          DateTime(now.start.year, now.start.month, now.start.day - 7));
      cubit.jumpToToday();
      expect(cubit.period.start, now.start);
    });

    test('kullanıcının özel aralığına tercih değişimi DOKUNMAZ', () {
      final custom = DateTimeRange(
          start: DateTime(2025, 3, 3), end: DateTime(2025, 3, 20, 23, 59, 59));
      final cubit = TransactionFilterCubit()..setPeriod(custom);
      cubit.usePeriodPreferences(wed);
      expect(cubit.period.start, DateTime(2025, 3, 3));
    });

    test(
        'birim değişimi özel aralıktayken de AYRI akıştan duyurulur '
        '(Gelecek ufku bayat kalmasın); aynı tercih duyurulmaz', () async {
      final custom = DateTimeRange(
          start: DateTime(2025, 3, 3), end: DateTime(2025, 3, 20, 23, 59, 59));
      final cubit = TransactionFilterCubit()..setPeriod(custom);
      addTearDown(cubit.close);
      final heard = <PeriodPreferences>[];
      final sub = cubit.periodPreferencesChanges.listen(heard.add);
      addTearDown(sub.cancel);
      final states = <Object>[];
      final stateSub = cubit.stream.listen(states.add);
      addTearDown(stateSub.cancel);

      cubit.usePeriodPreferences(wed);
      cubit.usePeriodPreferences(wed);
      await Future<void>.delayed(Duration.zero);

      expect(heard, [wed]);
      // Süzgecin durumu değişmedi: eski dinleyici (durum akışı) duymazdı.
      expect(states, isEmpty);
    });

    test('temizle kullanıcının birimine döner', () {
      final cubit = TransactionFilterCubit()..usePeriodPreferences(wed);
      cubit.stepPeriod(-3);
      cubit.clearAll();
      expect(cubit.period.start, wed.periodContaining(DateTime.now()).start);
    });
  });
}
