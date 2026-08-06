import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Payment', () {
    final date = DateTime(2026, 6, 1);
    test('supports value comparisons (Equatable)', () {
      expect(
        Payment(id: 'p1', date: date, amount: 100.0, notes: 'Part 1'),
        Payment(id: 'p1', date: date, amount: 100.0, notes: 'Part 1'),
      );
    });

    test('copyWith returns updated object', () {
      final payment =
          Payment(id: 'p1', date: date, amount: 100.0, notes: 'Part 1');
      final updated = payment.copyWith(
        date: DateTime(2026, 6, 2),
        amount: 200.0,
        overdueInterestPart: 30.0,
        notes: 'Part 2',
      );

      expect(updated.id, 'p1');
      expect(updated.date, DateTime(2026, 6, 2));
      expect(updated.amount, 200.0);
      expect(updated.overdueInterestPart, 30.0);
      expect(updated.notes, 'Part 2');
    });

    test('copyWith returns same object when no arguments are provided', () {
      final payment =
          Payment(id: 'p1', date: date, amount: 100.0, notes: 'Part 1');
      expect(payment.copyWith(), payment);
    });

    test('principalPart, faiz payı düşülmüş kısımdır', () {
      final payment = Payment(
          id: 'p1', date: date, amount: 1000.0, overdueInterestPart: 250.0);
      expect(payment.principalPart, 750.0);
    });
  });

  group('DebtEntity', () {
    final startDate = DateTime(2026, 1, 1);
    final dueDate = DateTime(2026, 12, 1);

    DebtEntity buildDebt({
      List<Payment> payments = const [],
      double expectedTotalAmount = 11200.0,
      double overdueInterestRate = 0,
    }) =>
        DebtEntity(
          id: 'debt_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'Car Loan',
          counterparty: 'Bank A',
          type: DebtType.bankLoan,
          calcMode: DebtCalcMode.amortized,
          principalAmount: 10000.0,
          interestRate: 1.0,
          termMonths: 12,
          overdueInterestRate: overdueInterestRate,
          startDate: startDate,
          dueDate: dueDate,
          payments: payments,
          isPaid: false,
          expectedTotalAmount: expectedTotalAmount,
        );

    final debt = buildDebt();

    test('supports value comparisons (Equatable)', () {
      expect(buildDebt(), buildDebt());
    });

    test('calcMode farkı eşitliği bozar', () {
      expect(
        debt.copyWith(calcMode: DebtCalcMode.flatSurcharge) == debt,
        isFalse,
      );
    });

    test('copyWith returns updated object', () {
      final updated = debt.copyWith(
        id: 'updated_id',
        userId: 'updated_user',
        walletId: 'updated_wallet',
        title: 'New Title',
        counterparty: 'New Bank',
        type: DebtType.installmentDebt,
        calcMode: DebtCalcMode.flatSurcharge,
        principalAmount: 5000.0,
        interestRate: 5.0,
        termMonths: 6,
        overdueInterestRate: 2.0,
        startDate: DateTime(2026, 2, 1),
        dueDate: DateTime(2026, 8, 1),
        payments: [Payment(id: 'p1', date: startDate, amount: 500.0)],
        isPaid: true,
        notes: 'new notes',
        expectedTotalAmount: 6000.0,
      );

      expect(updated.id, 'updated_id');
      expect(updated.userId, 'updated_user');
      expect(updated.walletId, 'updated_wallet');
      expect(updated.title, 'New Title');
      expect(updated.counterparty, 'New Bank');
      expect(updated.type, DebtType.installmentDebt);
      expect(updated.calcMode, DebtCalcMode.flatSurcharge);
      expect(updated.principalAmount, 5000.0);
      expect(updated.interestRate, 5.0);
      expect(updated.termMonths, 6);
      expect(updated.overdueInterestRate, 2.0);
      expect(updated.startDate, DateTime(2026, 2, 1));
      expect(updated.dueDate, DateTime(2026, 8, 1));
      expect(updated.payments.length, 1);
      expect(updated.isPaid, true);
      expect(updated.notes, 'new notes');
      expect(updated.expectedTotalAmount, 6000.0);
    });

    test('copyWith returns same object when no arguments are provided', () {
      expect(debt.copyWith(), debt);
    });

    group('calculations', () {
      test('totalPaidAmount sum payments amount', () {
        final withPayments = buildDebt(payments: [
          Payment(id: 'p1', date: startDate, amount: 500.0),
          Payment(id: 'p2', date: startDate, amount: 1500.0),
        ]);
        expect(withPayments.totalPaidAmount, 2000.0);
      });

      test('totalDebtAmount, kayıtlı toplamı döndürür', () {
        expect(debt.totalDebtAmount, 11200.0);
        expect(
            buildDebt(expectedTotalAmount: 15000.0).totalDebtAmount, 15000.0);
      });

      test('remainingAmount is totalDebtAmount minus principalPaidAmount', () {
        final withPayments = buildDebt(
          payments: [Payment(id: 'p1', date: startDate, amount: 2000.0)],
        );
        expect(withPayments.remainingAmount, 9200.0); // 11200 - 2000
      });

      test(
          'gecikme faizine sayılan kısım borcu azaltmaz; nakit toplamı yine tam tutardır',
          () {
        final withPayments = buildDebt(
          payments: [
            Payment(
                id: 'p1',
                date: startDate,
                amount: 2000.0,
                overdueInterestPart: 500.0),
          ],
        );
        expect(withPayments.totalPaidAmount, 2000.0);
        expect(withPayments.principalPaidAmount, 1500.0);
        expect(withPayments.settledOverdueInterest, 500.0);
        // Kalan yalnız ana para tarafından düşer.
        expect(withPayments.remainingAmount, 9700.0);
      });

      test('progress returns correct ratio', () {
        final withPayments = buildDebt(
          payments: [Payment(id: 'p1', date: startDate, amount: 5600.0)],
        );
        expect(withPayments.progress, 0.5); // 5600 / 11200
      });

      test('progress returns 0 if totalDebtAmount is 0', () {
        expect(buildDebt(expectedTotalAmount: 0).progress, 0.0);
      });
    });
  });
}
