import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Payment', () {
    final date = DateTime(2026, 6, 1);
    test('supports value comparisons (Equatable)', () {
      expect(
        Payment(date: date, amount: 100.0, notes: 'Part 1'),
        Payment(date: date, amount: 100.0, notes: 'Part 1'),
      );
    });

    test('copyWith returns updated object', () {
      final payment = Payment(date: date, amount: 100.0, notes: 'Part 1');
      final updated = payment.copyWith(
        date: DateTime(2026, 6, 2),
        amount: 200.0,
        notes: 'Part 2',
      );

      expect(updated.date, DateTime(2026, 6, 2));
      expect(updated.amount, 200.0);
      expect(updated.notes, 'Part 2');
    });

    test('copyWith returns same object when no arguments are provided', () {
      final payment = Payment(date: date, amount: 100.0, notes: 'Part 1');
      expect(payment.copyWith(), payment);
    });
  });

  group('DebtEntity', () {
    final startDate = DateTime(2026, 1, 1);
    final dueDate = DateTime(2026, 12, 1);

    final debt = DebtEntity(
      id: 'debt_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Car Loan',
      counterparty: 'Bank A',
      type: DebtType.bankLoan,
      principalAmount: 10000.0,
      interestRate: 12.0, // 12% annual interest
      termMonths: 12,
      startDate: startDate,
      dueDate: dueDate,
      payments: const [],
      isPaid: false,
    );

    test('supports value comparisons (Equatable)', () {
      expect(
        DebtEntity(
          id: 'debt_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'Car Loan',
          counterparty: 'Bank A',
          type: DebtType.bankLoan,
          principalAmount: 10000.0,
          interestRate: 12.0,
          termMonths: 12,
          startDate: startDate,
          dueDate: dueDate,
        ),
        DebtEntity(
          id: 'debt_1',
          userId: 'user_1',
          walletId: 'wallet_1',
          title: 'Car Loan',
          counterparty: 'Bank A',
          type: DebtType.bankLoan,
          principalAmount: 10000.0,
          interestRate: 12.0,
          termMonths: 12,
          startDate: startDate,
          dueDate: dueDate,
        ),
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
        principalAmount: 5000.0,
        interestRate: 5.0,
        termMonths: 6,
        overdueInterestRate: 2.0,
        startDate: DateTime(2026, 2, 1),
        dueDate: DateTime(2026, 8, 1),
        payments: [Payment(date: startDate, amount: 500.0)],
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
        final withPayments = debt.copyWith(
          payments: [
            Payment(date: startDate, amount: 500.0),
            Payment(date: startDate, amount: 1500.0),
          ],
        );
        expect(withPayments.totalPaidAmount, 2000.0);
      });

      test('calculateTotalDebt calculates simple interest correctly', () {
        // principal: 10000, interestRate: 12% per year, termMonths: 12
        // total = 10000 + (10000 * 12 * 12 / 1200) = 10000 + 1200 = 11200
        final total = DebtEntity.calculateTotalDebt(
          principal: 10000.0,
          interestRate: 12.0,
          termMonths: 12,
        );
        expect(total, 11200.0);
      });

      test(
          'calculateAmortizedTotal calculates amortized loan correctly without taxes',
          () {
        final total = DebtEntity.calculateAmortizedTotal(
          principal: 10000.0,
          monthlyInterestRate: 1.0, // 1% per month
          termMonths: 12,
          includeTaxes: false,
        );
        // Using amortization formula: monthlyPayment = P * (r * (1+r)^n) / ((1+r)^n - 1)
        // P = 10000, r = 0.01, n = 12
        // monthlyPayment = 10000 * (0.01 * 1.126825) / 0.126825 ~ 888.4878
        // total = 888.4878 * 12 ~ 10661.85
        expect(total, closeTo(10661.85, 0.1));
      });

      test(
          'calculateAmortizedTotal calculates amortized loan correctly with taxes',
          () {
        final total = DebtEntity.calculateAmortizedTotal(
          principal: 10000.0,
          monthlyInterestRate: 1.0,
          termMonths: 12,
          includeTaxes: true,
        );
        // monthlyInterestRate effective = 1.0 * 1.3 = 1.3% -> r = 0.013
        // denominator = (1.013)^12 - 1 ~ 0.16765191244
        // monthlyPayment = 10000 * (0.013 * 1.16765191244) / 0.16765191244 ~ 905.416
        // total = 905.416 * 12 ~ 10865.00
        expect(total, closeTo(10865.00, 0.1));
      });

      test('calculateAmortizedTotal returns principal if invalid arguments',
          () {
        expect(
            DebtEntity.calculateAmortizedTotal(
                principal: 1000.0, monthlyInterestRate: 0.0, termMonths: 12),
            1000.0);
        expect(
            DebtEntity.calculateAmortizedTotal(
                principal: 1000.0, monthlyInterestRate: 1.0, termMonths: 0),
            1000.0);
        expect(
            DebtEntity.calculateAmortizedTotal(
                principal: 0.0, monthlyInterestRate: 1.0, termMonths: 12),
            0.0);
      });

      test('totalDebtAmount returns expectedTotalAmount if set', () {
        final customTotal = debt.copyWith(expectedTotalAmount: 15000.0);
        expect(customTotal.totalDebtAmount, 15000.0);
      });

      test(
          'totalDebtAmount calculates simple interest if expectedTotalAmount is null',
          () {
        expect(debt.totalDebtAmount, 11200.0);
      });

      test('remainingAmount is totalDebtAmount minus totalPaidAmount', () {
        final withPayments = debt.copyWith(
          payments: [Payment(date: startDate, amount: 2000.0)],
        );
        expect(withPayments.remainingAmount, 9200.0); // 11200 - 2000 = 9200
      });

      test('progress returns correct ratio', () {
        final withPayments = debt.copyWith(
          payments: [Payment(date: startDate, amount: 5600.0)],
        );
        expect(withPayments.progress, 0.5); // 5600 / 11200 = 0.5
      });

      test('progress returns 0 if totalDebtAmount is 0', () {
        final zeroDebt = debt.copyWith(principalAmount: 0.0, interestRate: 0.0);
        expect(zeroDebt.progress, 0.0);
      });
    });
  });
}
