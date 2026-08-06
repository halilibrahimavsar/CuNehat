import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/debt_repayment_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calc = DebtRepaymentCalculator();

  group('DebtRepaymentCalculator.compute', () {
    test('none: toplam = ana para, faizsiz', () {
      final r = calc.compute(
        mode: DebtCalcMode.none,
        principal: 5000,
        termMonths: 1,
      );
      expect(r.expectedTotal, 5000);
      expect(r.totalInterest, 0);
      expect(r.monthlyPayment, 5000);
    });

    test('flatSurcharge: ana para + tek seferlik %vade farkı', () {
      final r = calc.compute(
        mode: DebtCalcMode.flatSurcharge,
        principal: 10000,
        termMonths: 12,
        interestRate: 20,
      );
      expect(r.expectedTotal, 12000);
      expect(r.totalInterest, 2000);
      expect(r.monthlyPayment, 1000);
    });

    test('amortized: eşit taksitli kredi formülü, aylık oran', () {
      // P=10000, r=0.01, n=12 → taksit ≈ 888,49 → toplam ≈ 10.661,85
      final r = calc.compute(
        mode: DebtCalcMode.amortized,
        principal: 10000,
        termMonths: 12,
        interestRate: 1,
      );
      expect(r.expectedTotal, closeTo(10661.85, 0.1));
    });

    test('amortizedWithTaxes: efektif oran × 1,30 (KKDF + BSMV)', () {
      // Efektif aylık oran %1,3 → toplam ≈ 10.865
      final r = calc.compute(
        mode: DebtCalcMode.amortizedWithTaxes,
        principal: 10000,
        termMonths: 12,
        interestRate: 1,
      );
      expect(r.expectedTotal, closeTo(10865.00, 0.1));
      // Vergiler toplamı gerçekten yükseltmeli.
      final withoutTaxes = calc.compute(
        mode: DebtCalcMode.amortized,
        principal: 10000,
        termMonths: 12,
        interestRate: 1,
      );
      expect(r.expectedTotal, greaterThan(withoutTaxes.expectedTotal));
    });

    test('amortized: oran 0 ise toplam ana paraya eşit', () {
      final r = calc.compute(
        mode: DebtCalcMode.amortized,
        principal: 10000,
        termMonths: 12,
      );
      expect(r.expectedTotal, 10000);
      expect(r.totalInterest, 0);
    });

    test('amortized: vade 0 ya da ana para 0 ise ana parayı döndürür', () {
      expect(
        calc
            .compute(
                mode: DebtCalcMode.amortized,
                principal: 1000,
                termMonths: 0,
                interestRate: 1)
            .expectedTotal,
        1000,
      );
      expect(
        calc
            .compute(
                mode: DebtCalcMode.amortized,
                principal: 0,
                termMonths: 12,
                interestRate: 1)
            .expectedTotal,
        0,
      );
    });

    test('fixedInstallment: toplam = taksit × vade', () {
      final r = calc.compute(
        mode: DebtCalcMode.fixedInstallment,
        principal: 10000,
        termMonths: 12,
        monthlyInstallment: 1000,
      );
      expect(r.expectedTotal, 12000);
      expect(r.totalInterest, 2000);
      expect(r.monthlyPayment, 1000);
    });

    test('fixedInstallment: toplam ana paranın altındaysa faiz negatif değil',
        () {
      final r = calc.compute(
        mode: DebtCalcMode.fixedInstallment,
        principal: 10000,
        termMonths: 12,
        monthlyInstallment: 500,
      );
      expect(r.expectedTotal, 6000);
      expect(r.totalInterest, 0);
    });

    test('simpleMonthlyInterest: oran AYLIK uygulanır', () {
      // Regresyon: aynı girdi eskiden yıllık nominal faiz gibi işleniyordu
      // (rate × term / 1200) ve toplam 10.500 çıkıyordu — girilen oranın
      // etkisi 12 kat küçüktü. Etiket "Aylık Faiz %" diyor.
      final r = calc.compute(
        mode: DebtCalcMode.simpleMonthlyInterest,
        principal: 10000,
        termMonths: 12,
        interestRate: 5,
      );
      expect(r.expectedTotal, 16000);
      expect(r.totalInterest, 6000);
    });

    test('vade 0 ise aylık taksit 0', () {
      final r = calc.compute(
        mode: DebtCalcMode.simpleMonthlyInterest,
        principal: 1000,
        termMonths: 0,
        interestRate: 5,
      );
      expect(r.monthlyPayment, 0);
    });

    test('taşan girdide NaN/Infinity kayda sızmaz, ana paraya düşer', () {
      // Doğrulama vadeyi kMaxTermMonths ile sınırlıyor; bu ikinci savunma
      // hattı. Eskiden toplam NaN oluyor, kayıt `moneyIsPositive(NaN)==false`
      // yüzünden listeden tamamen kayboluyordu.
      final r = calc.compute(
        mode: DebtCalcMode.amortized,
        principal: 100000,
        termMonths: 36000,
        interestRate: 2,
      );
      expect(r.expectedTotal.isFinite, isTrue);
      expect(r.expectedTotal, 100000);
    });

    test('sınır sabitleri makul aralıkta', () {
      expect(kMaxTermMonths, 600);
      expect(kMaxInterestRatePercent, 100);
    });
  });
}
