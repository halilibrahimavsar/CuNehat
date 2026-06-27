import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';

/// Bir borcun geri ödeme özeti. Saf veri; biçimlendirme UI'da yapılır.
class DebtRepayment {
  /// Toplam geri ödeme (ana para + faiz/vade farkı).
  final double expectedTotal;

  /// Toplam faiz / vade farkı (gösterimde negatif gösterilmez).
  final double totalInterest;

  /// Vade > 0 ise aylık taksit (toplam / vade), değilse 0.
  final double monthlyPayment;

  const DebtRepayment({
    required this.expectedTotal,
    required this.totalInterest,
    required this.monthlyPayment,
  });
}

/// Saf-Dart borç geri ödeme hesaplayıcısı. Borç türüne ve girdi moduna göre
/// toplam geri ödemeyi, aylık taksiti ve toplam faizi hesaplar.
///
/// Tek sorumluluğu hesaplama; tutar formülleri [DebtEntity] üzerindeki statik
/// metotlara dayanır. Ekleme sayfasındaki **canlı önizleme** ile **kaydetme**
/// yolu bu tek kaynağı paylaşır → önizlenen tutar her zaman kaydedilenle aynıdır.
/// Flutter/Hive bağımlılığı yoktur → kolay birim test edilir.
class DebtRepaymentCalculator {
  const DebtRepaymentCalculator();

  DebtRepayment compute({
    required DebtType type,
    required double principal,
    required int termMonths,
    double interestRate = 0,
    double monthlyInstallment = 0,
    bool isInstallmentAmortized = true,
    bool isBankLoanMonthly = true,
    bool includeBankTaxes = false,
  }) {
    final double total;
    switch (type) {
      case DebtType.personalDebt:
        // Tutar == Toplam Tutar (faizsiz).
        total = principal;
        break;

      case DebtType.installmentDebt:
        if (isInstallmentAmortized) {
          total = DebtEntity.calculateAmortizedTotal(
            principal: principal,
            monthlyInterestRate: interestRate,
            termMonths: termMonths,
            includeTaxes: false,
          );
        } else {
          // Basit vade farkı: ana para + (%faiz).
          total = principal + (principal * interestRate / 100);
        }
        break;

      case DebtType.bankLoan:
        if (isBankLoanMonthly) {
          // Aylık taksit biliniyor: toplam = taksit × vade.
          total = monthlyInstallment * termMonths;
        } else {
          total = DebtEntity.calculateAmortizedTotal(
            principal: principal,
            monthlyInterestRate: interestRate,
            termMonths: termMonths,
            includeTaxes: includeBankTaxes,
          );
        }
        break;

      case DebtType.otherDebt:
        total = DebtEntity.calculateTotalDebt(
          principal: principal,
          interestRate: interestRate,
          termMonths: termMonths,
        );
        break;
    }

    // Aylık taksiti bilinen banka kredisinde toplam, ana paranın altında
    // kalabilir; bu durumda toplam faiz negatif gösterilmez.
    final isMonthlyKnown = type == DebtType.bankLoan && isBankLoanMonthly;
    final totalInterest = isMonthlyKnown
        ? (total > principal ? total - principal : 0.0)
        : total - principal;
    final monthly = termMonths > 0 ? total / termMonths : 0.0;

    return DebtRepayment(
      expectedTotal: total,
      totalInterest: totalInterest,
      monthlyPayment: monthly,
    );
  }
}
