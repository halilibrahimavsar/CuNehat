import 'dart:math' as math;

import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';

/// Kabul edilen en uzun vade (ay). 50 yıl; en uzun konut kredisinin çok
/// üstünde ama amortisman formülünün taşma bölgesinden (~35.800 ay) uzak.
const int kMaxTermMonths = 600;

/// Kabul edilen en yüksek aylık oran (%). Faiz ve gecikme faizi için ortak.
const double kMaxInterestRatePercent = 100;

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

/// Saf-Dart borç geri ödeme hesaplayıcısı. **Tüm** toplam-geri-ödeme
/// formüllerinin tek sahibi.
///
/// Ekleme sayfasındaki canlı önizleme ile kaydetme yolu bu tek kaynağı
/// paylaşır → önizlenen tutar her zaman kaydedilenle aynıdır. Yöntem artık
/// borç TÜRÜNDEN değil, kayıtla birlikte saklanan [DebtCalcMode]'dan gelir;
/// tür yalnız formun hangi alanları göstereceğini belirler.
/// Flutter/Hive bağımlılığı yoktur → kolay birim test edilir.
class DebtRepaymentCalculator {
  const DebtRepaymentCalculator();

  DebtRepayment compute({
    required DebtCalcMode mode,
    required double principal,
    required int termMonths,
    double interestRate = 0,
    double monthlyInstallment = 0,
  }) {
    final total = _total(
      mode: mode,
      principal: principal,
      termMonths: termMonths,
      interestRate: interestRate,
      monthlyInstallment: monthlyInstallment,
    );

    // Aylık taksiti bilinen kredide toplam, ana paranın altında kalabilir;
    // bu durumda toplam faiz negatif gösterilmez.
    final totalInterest = mode == DebtCalcMode.fixedInstallment
        ? (total > principal ? total - principal : 0.0)
        : total - principal;
    final monthly = termMonths > 0 ? total / termMonths : 0.0;

    return DebtRepayment(
      expectedTotal: total,
      totalInterest: totalInterest,
      monthlyPayment: monthly,
    );
  }

  double _total({
    required DebtCalcMode mode,
    required double principal,
    required int termMonths,
    required double interestRate,
    required double monthlyInstallment,
  }) {
    final raw = switch (mode) {
      DebtCalcMode.none => principal,
      DebtCalcMode.fixedInstallment => monthlyInstallment * termMonths,
      DebtCalcMode.amortized => _amortizedTotal(
          principal: principal,
          monthlyInterestRate: interestRate,
          termMonths: termMonths,
        ),
      // Banka tüketici kredilerinde faiz üzerinden %15 KKDF ve %15 BSMV
      // alınır (toplam %30) → efektif aylık oran × 1,30.
      DebtCalcMode.amortizedWithTaxes => _amortizedTotal(
          principal: principal,
          monthlyInterestRate: interestRate * 1.30,
          termMonths: termMonths,
        ),
      DebtCalcMode.flatSurcharge =>
        principal + (principal * interestRate / 100),
      // Oran AYLIK: 12 ay × %5 → ana paranın %60'ı kadar faiz.
      DebtCalcMode.simpleMonthlyInterest =>
        principal + (principal * interestRate * termMonths / 100),
    };

    // Savunma amaçlı: `pow(1+r, n)` çok uzun vadede sonsuza taşar ve toplam
    // NaN olur. NaN kayda girerse `moneyIsPositive(NaN) == false` yüzünden
    // borç listeden tamamen kaybolurdu. Girdi doğrulaması (vade ≤ 600, oran
    // ≤ 100) bunu zaten engelliyor; buradaki kapı ikinci savunma hattıdır ve
    // kaydı yok etmek yerine faizsiz hâline düşer.
    return raw.isFinite ? raw : principal;
  }

  /// Eşit taksitli kredi (amortisman) formülü — aylık faiz üzerinden.
  double _amortizedTotal({
    required double principal,
    required double monthlyInterestRate,
    required int termMonths,
  }) {
    if (principal <= 0 || termMonths <= 0) return principal;
    if (monthlyInterestRate <= 0) return principal;

    final r = monthlyInterestRate / 100;
    final denominator = math.pow(1 + r, termMonths) - 1;
    if (denominator == 0) return principal;

    final monthlyPayment =
        principal * (r * math.pow(1 + r, termMonths)) / denominator;
    return monthlyPayment * termMonths;
  }
}
