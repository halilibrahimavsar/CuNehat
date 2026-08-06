import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/debt_sorting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 15);

  DebtEntity debt(
    String title, {
    required DateTime start,
    int term = 12,
    bool isPaid = false,
  }) =>
      DebtEntity(
        id: title,
        userId: 'u',
        walletId: 'w',
        title: title,
        counterparty: 'c',
        type: DebtType.bankLoan,
        calcMode: DebtCalcMode.fixedInstallment,
        principalAmount: 12000,
        interestRate: 0,
        termMonths: term,
        startDate: start,
        dueDate: DateTime(start.year + 1, start.month, start.day),
        expectedTotalAmount: 12000,
      );

  test('gecikmiş borçlar listenin başına gelir', () {
    // 1. taksitleri: geç → 2026-02-01, erken → 2026-08-01 (henüz gelmedi)
    final overdue = debt('Gecikmis', start: DateTime(2026, 1, 1));
    final upcoming = debt('Yaklasan', start: DateTime(2026, 7, 1));

    final sorted = sortDebtsForDisplay([upcoming, overdue], now: now);
    expect(sorted.map((d) => d.title), ['Gecikmis', 'Yaklasan']);
  });

  test('aynı gecikme durumunda sıradaki taksit vadesi artan sıralanır', () {
    final a = debt('Once', start: DateTime(2026, 6, 20)); // 1. taksit 07-20
    final b = debt('Sonra', start: DateTime(2026, 7, 10)); // 1. taksit 08-10

    final sorted = sortDebtsForDisplay([b, a], now: now);
    expect(sorted.map((d) => d.title), ['Once', 'Sonra']);
  });

  test('vadesi olmayan kayıtlar sona düşer', () {
    final withDue = debt('Vadeli', start: DateTime(2026, 7, 1));
    final withoutDue = debt('Vadesiz', start: DateTime(2026, 7, 1), term: 1)
        .copyWith(dueDate: null);

    final sorted = sortDebtsForDisplay([withoutDue, withDue], now: now);
    expect(sorted.map((d) => d.title), ['Vadeli', 'Vadesiz']);
  });

  test('eşitlikte başlığa göre kararlı sıralanır', () {
    final a = debt('Ahmet', start: DateTime(2026, 7, 1));
    final b = debt('Zeynep', start: DateTime(2026, 7, 1));

    expect(sortDebtsForDisplay([b, a], now: now).map((d) => d.title),
        ['Ahmet', 'Zeynep']);
  });

  test('girdi listesini yerinde değiştirmez', () {
    final input = [
      debt('B', start: DateTime(2026, 7, 1)),
      debt('A', start: DateTime(2026, 1, 1)),
    ];
    final before = input.map((d) => d.title).toList();
    sortDebtsForDisplay(input, now: now);
    expect(input.map((d) => d.title).toList(), before);
  });
}
