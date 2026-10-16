import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final b = TempBudgetEntity(
    id: 'tb',
    name: 'Tatil',
    limitAmount: 1000,
    startDate: DateTime(2026, 11, 10),
    endDate: DateTime(2026, 11, 20),
    categoryIds: const ['c'],
  );

  test('gün sayısı iki ucu da içerir', () {
    expect(b.totalDays, 11);
    final single = b.copyWith(endDate: DateTime(2026, 11, 10));
    expect(single.totalDays, 1);
  });

  test('durum: başlamadan önce yaklaşan, iki uçta da süren, sonra biten', () {
    expect(b.statusOn(DateTime(2026, 11, 9, 23)), TempBudgetStatus.upcoming);
    expect(b.statusOn(DateTime(2026, 11, 10)), TempBudgetStatus.active);
    expect(b.statusOn(DateTime(2026, 11, 20, 23, 59)), TempBudgetStatus.active);
    expect(b.statusOn(DateTime(2026, 11, 21)), TempBudgetStatus.finished);
  });

  test('kalan gün bugünü sayar; son gün 1, bitmişte 0, başlamamışta tamamı',
      () {
    expect(b.remainingDaysOn(DateTime(2026, 11, 10)), 11);
    expect(b.remainingDaysOn(DateTime(2026, 11, 20)), 1);
    expect(b.remainingDaysOn(DateTime(2026, 11, 21)), 0);
    expect(b.remainingDaysOn(DateTime(2026, 11, 1)), 11);
    expect(b.daysUntilStartOn(DateTime(2026, 11, 8)), 2);
    expect(b.daysUntilStartOn(DateTime(2026, 11, 12)), 0);
  });

  test('yaz saati geçişinde gün sayısı kaymaz', () {
    // 25 Eki 2026 Avrupa saat geri alma günü; yerel gece yarısı farkı 25 sa.
    final dst = b.copyWith(
        startDate: DateTime(2026, 10, 24), endDate: DateTime(2026, 10, 26));
    expect(dst.totalDays, 3);
  });

  test('doldu / aşıldı yarım kuruş toleransıyla', () {
    expect(b.copyWith(spentAmount: 1000.0000001).isFilled, isTrue);
    expect(b.copyWith(spentAmount: 1000.0000001).isExceeded, isFalse);
    expect(b.copyWith(spentAmount: 1000.01).isExceeded, isTrue);
    expect(b.copyWith(spentAmount: 400).remaining, 600);
  });
}
