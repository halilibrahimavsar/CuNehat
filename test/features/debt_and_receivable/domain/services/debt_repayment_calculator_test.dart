import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/debt_repayment_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calc = DebtRepaymentCalculator();

  group('DebtRepaymentCalculator.compute', () {
    test('personalDebt: toplam = ana para, faizsiz', () {
      final r = calc.compute(
        type: DebtType.personalDebt,
        principal: 1000,
        termMonths: 1,
      );
      expect(r.expectedTotal, 1000);
      expect(r.totalInterest, 0);
      expect(r.monthlyPayment, 1000);
    });

    test('installmentDebt basit vade farkı: ana para + %faiz', () {
      final r = calc.compute(
        type: DebtType.installmentDebt,
        principal: 1000,
        termMonths: 10,
        interestRate: 10,
        isInstallmentAmortized: false,
      );
      expect(r.expectedTotal, 1100); // 1000 + 1000*10/100
      expect(r.totalInterest, 100);
      expect(r.monthlyPayment, 110); // 1100 / 10
    });

    test('installmentDebt amortized, faiz 0 → toplam ana paraya eşit', () {
      final r = calc.compute(
        type: DebtType.installmentDebt,
        principal: 2000,
        termMonths: 4,
        interestRate: 0,
        isInstallmentAmortized: true,
      );
      // calculateAmortizedTotal faiz <= 0 için principal döndürür.
      expect(r.expectedTotal, 2000);
      expect(r.totalInterest, 0);
      expect(r.monthlyPayment, 500);
    });

    test('bankLoan aylık taksit biliniyor: toplam = taksit × vade', () {
      final r = calc.compute(
        type: DebtType.bankLoan,
        principal: 5000,
        termMonths: 12,
        monthlyInstallment: 500,
        isBankLoanMonthly: true,
      );
      expect(r.expectedTotal, 6000); // 500 * 12
      expect(r.totalInterest, 1000); // 6000 - 5000
      expect(r.monthlyPayment, 500);
    });

    test('bankLoan aylık modda toplam < ana para ise faiz negatif gösterilmez',
        () {
      final r = calc.compute(
        type: DebtType.bankLoan,
        principal: 10000,
        termMonths: 12,
        monthlyInstallment: 500, // 6000 < 10000
        isBankLoanMonthly: true,
      );
      expect(r.expectedTotal, 6000);
      expect(r.totalInterest, 0); // negatif değil
    });

    test('bankLoan faiz oranıyla, faiz 0 → amortisman ana parayı döndürür', () {
      final r = calc.compute(
        type: DebtType.bankLoan,
        principal: 3000,
        termMonths: 6,
        interestRate: 0,
        isBankLoanMonthly: false,
      );
      expect(r.expectedTotal, 3000);
      expect(r.totalInterest, 0);
    });

    test('otherDebt: basit faiz formülü (principal*rate*term/1200)', () {
      final r = calc.compute(
        type: DebtType.otherDebt,
        principal: 1200,
        termMonths: 12,
        interestRate: 10,
      );
      // 1200 + 1200*10*12/1200 = 1200 + 120
      expect(r.expectedTotal, 1320);
      expect(r.totalInterest, 120);
      expect(r.monthlyPayment, 110); // 1320 / 12
    });

    test('vade 0 ise aylık taksit 0', () {
      final r = calc.compute(
        type: DebtType.otherDebt,
        principal: 1000,
        termMonths: 0,
        interestRate: 10,
      );
      expect(r.monthlyPayment, 0);
    });
  });
}
