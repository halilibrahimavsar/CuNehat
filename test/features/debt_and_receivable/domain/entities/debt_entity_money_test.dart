import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kullanıcı hatasının reprosu: "Tümü" = 314.56 seçiliyken
/// "kalan tutardan fazla olamaz" hatası. Kök neden: totalDebtAmount'un
/// 314.55999999999995 gibi FP artığı taşıması + toleranssız `>`.
void main() {
  DebtEntity debt({
    double principal = 300,
    double interest = 0,
    int term = 1,
    double expectedTotal = 300,
    List<Payment> payments = const [],
    bool isPaid = false,
  }) {
    return DebtEntity(
      calcMode: DebtCalcMode.none,
      userId: 'u',
      walletId: 'w',
      title: 'Kredi',
      counterparty: 'Banka',
      type: DebtType.bankLoan,
      principalAmount: principal,
      interestRate: interest,
      termMonths: term,
      startDate: DateTime(2026, 1, 1),
      payments: payments,
      isPaid: isPaid,
      expectedTotalAmount: expectedTotal,
    );
  }

  group('314.56 senaryosu (getter yuvarlama)', () {
    test('kirli expectedTotalAmount getter\'da kuruşa oturur', () {
      final d = debt(expectedTotal: 314.55999999999995);
      expect(d.totalDebtAmount, 314.56);
      expect(d.remainingAmount, 314.56);
    });

    test('faiz formülünden gelen çok basamaklı toplam yuvarlanır', () {
      // 300 + (300 * 3.7 * 7 / 1200) = 306.475 → tam kuruş değil ama
      // double temsili kirli olabilen bir örnek; getter her durumda 2 hane.
      final d = debt(principal: 300, interest: 3.7, term: 7);
      final t = d.totalDebtAmount;
      expect(t, roundToCents(t)); // sabit nokta: zaten kuruş-temiz
    });

    test('"Tümü" prefill değeri artık doğrulamadan geçer', () {
      final d = debt(expectedTotal: 314.55999999999995);
      // Dialog "Tümü" için remainingAmount'u 2 haneyle yazar: "314.56".
      final prefill = d.remainingAmount.toStringAsFixed(2);
      expect(prefill, '314.56');
      expect(
        validateAmount(prefill,
            max: d.remainingAmount, maxExceededMessage: 'fazla'),
        isNull,
      );
      // Gerçekten fazla tutar hâlâ reddedilir.
      expect(
        validateAmount('314.57',
            max: d.remainingAmount, maxExceededMessage: 'fazla'),
        'fazla',
      );
    });

    test('eski >2 basamaklı ödemelerle de kapanış doğru (moneyGte)', () {
      // Normalizasyon koşmamış gibi: kayıtlı ödemeler kirli.
      final d = debt(
        expectedTotal: 314.56,
        payments: [
          Payment(
              id: 'p1', date: DateTime(2026, 2, 1), amount: 104.85333333333334),
          Payment(
              id: 'p2', date: DateTime(2026, 3, 1), amount: 104.85333333333334),
          Payment(
              id: 'p3', date: DateTime(2026, 4, 1), amount: 104.85333333333331),
        ],
      );
      // Toplam ~314.55999...99 → getter 314.56'ya oturur, borç kapanmıştır.
      expect(d.totalPaidAmount, 314.56);
      expect(moneyGte(d.totalPaidAmount, d.totalDebtAmount), true);
      expect(moneyIsPositive(d.remainingAmount), false);
    });

    test('kalan tutar negatif artık bırakmaz', () {
      final d = debt(
        expectedTotal: 100,
        payments: [
          Payment(id: 'p4', date: DateTime(2026, 2, 1), amount: 100.001)
        ],
      );
      // Ödeme yazımı artık yuvarlı geliyor ama eski veri böyle olabilir;
      // getter'lar kuruşa oturur ve kalan "para olarak" pozitif değildir.
      expect(moneyIsPositive(d.remainingAmount), false);
    });
  });
}
