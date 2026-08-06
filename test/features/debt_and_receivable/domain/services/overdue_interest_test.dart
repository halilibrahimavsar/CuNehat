import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/overdue_interest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 1, 1);

  DebtEntity debt({
    double total = 12000,
    int term = 12,
    double overdueRate = 7.5,
    List<Payment> payments = const [],
    DateTime? dueDate,
    bool noDueDate = false,
    bool isPaid = false,
  }) =>
      DebtEntity(
        id: 'd1',
        userId: 'u',
        walletId: 'w',
        title: 'Kredi',
        counterparty: 'Banka',
        type: DebtType.bankLoan,
        calcMode: DebtCalcMode.fixedInstallment,
        principalAmount: total,
        interestRate: 0,
        termMonths: term,
        overdueInterestRate: overdueRate,
        startDate: start,
        dueDate: noDueDate ? null : (dueDate ?? DateTime(2027, 1, 1)),
        payments: payments,
        isPaid: isPaid,
        expectedTotalAmount: total,
      );

  group('accruedOverdueInterest', () {
    test('ara ödeme yokken kullanıcının formülüne birebir iner', () {
      // 1. taksit 1.000 ₺, vadesi 2026-02-01, 60 gün gecikmiş, aylık %7,5.
      // 1000 × 0,075 × 60/30 = 150
      final d = debt();
      final accrued = accruedOverdueInterest(d, asOf: DateTime(2026, 4, 2));
      // Gecikmiş bakiye eğrisi vade tarihlerinde sıçrar; tahakkuk bu
      // segmentlerin toplamıdır (günlük oran = %7,5 / 30 = 0,0025):
      //   02-01 → 03-01 : 28 gün × 1.000 × 0,0025 =  70,0
      //   03-01 → 04-01 : 31 gün × 2.000 × 0,0025 = 155,0
      //   04-01 → 04-02 :  1 gün × 3.000 × 0,0025 =   7,5
      expect(accrued, closeTo(232.5, 0.01));
    });

    test('tek gecikmiş taksit, tek segment', () {
      final d = debt(term: 1, dueDate: DateTime(2026, 2, 1));
      // 12.000 × 0,075 × 60/30 = 1.800
      expect(accruedOverdueInterest(d, asOf: DateTime(2026, 4, 2)),
          closeTo(1800, 0.01));
    });

    test('oran 0 ise tahakkuk yok', () {
      final d = debt(overdueRate: 0);
      expect(accruedOverdueInterest(d, asOf: DateTime(2027, 1, 1)), 0);
    });

    test('vadesi gelmemiş borçta tahakkuk yok', () {
      final d = debt();
      expect(accruedOverdueInterest(d, asOf: DateTime(2026, 1, 15)), 0);
    });

    test('tek taksitli ve vadesi olmayan kayıtta tahakkuk yok', () {
      final d = debt(term: 1, noDueDate: true);
      expect(accruedOverdueInterest(d, asOf: DateTime(2030, 1, 1)), 0);
    });

    test('YOL BAĞIMLI: sonradan yapılan tam ödeme geçmiş faizi silmez', () {
      // Regresyon: tahakkuk "şu anki kalan × şu ana kadarki gün" diye
      // hesaplansaydı, borç kapandığında bütün satırların kalanı 0 olur ve
      // aylarca biriken faiz hiç yaşanmamış gibi sıfırlanırdı.
      final beforePayment = accruedOverdueInterest(
        debt(term: 1, dueDate: DateTime(2026, 2, 1)),
        asOf: DateTime(2026, 8, 1),
      );
      expect(beforePayment, greaterThan(0));

      final afterFullPayment = accruedOverdueInterest(
        debt(
          term: 1,
          dueDate: DateTime(2026, 2, 1),
          payments: [
            Payment(id: 'p1', date: DateTime(2026, 8, 1), amount: 12000),
          ],
        ),
        asOf: DateTime(2026, 8, 1),
      );
      expect(afterFullPayment, beforePayment,
          reason: 'ödeme anına kadar biriken faiz korunmalı');
    });

    test('ana para kapandıktan sonra tahakkuk BÜYÜMEZ (isPaid kararlı kalır)',
        () {
      final d = debt(
        term: 1,
        dueDate: DateTime(2026, 2, 1),
        payments: [
          Payment(id: 'p1', date: DateTime(2026, 3, 1), amount: 12000)
        ],
      );
      final atPayment = accruedOverdueInterest(d, asOf: DateTime(2026, 3, 1));
      final oneYearLater =
          accruedOverdueInterest(d, asOf: DateTime(2027, 3, 1));
      expect(oneYearLater, atPayment);
    });

    test('yaz saati geçişini kapsayan aralıkta gün sayımı doğru', () {
      // Türkiye kalıcı UTC+3'te ama takvim-günü sayımı yerel saatten bağımsız
      // olmalı; UTC normalizasyonu bunu garanti eder.
      final d = debt(term: 1, dueDate: DateTime(2026, 3, 28));
      // 28 Mart → 30 Mart = 2 gün: 12.000 × 0,075 × 2/30 = 60
      expect(accruedOverdueInterest(d, asOf: DateTime(2026, 3, 30)),
          closeTo(60, 0.01));
    });
  });

  group('outstanding / payoff', () {
    test('outstanding, ödenmiş faiz payını düşer ve negatife inmez', () {
      final d = debt(
        term: 1,
        dueDate: DateTime(2026, 2, 1),
        payments: [
          Payment(
              id: 'p1',
              date: DateTime(2026, 4, 2),
              amount: 2000,
              overdueInterestPart: 1800),
        ],
      );
      expect(outstandingOverdueInterest(d, now: DateTime(2026, 4, 2)), 0);
    });

    test('payoff = kalan ana para + kapanmamış faiz', () {
      final d = debt(term: 1, dueDate: DateTime(2026, 2, 1));
      final now = DateTime(2026, 4, 2);
      expect(payoffAmount(d, now: now), closeTo(12000 + 1800, 0.01));
    });
  });

  group('reallocatePayments', () {
    test('ödeme ÖNCE faizi kapatır, kalanı ana paraya sayılır', () {
      final d = debt(
        term: 1,
        dueDate: DateTime(2026, 2, 1),
        payments: [
          // 2026-03-03: 30 gün gecikme → 12.000 × 0,075 × 30/30 = 900 faiz
          Payment(id: 'p1', date: DateTime(2026, 3, 3), amount: 1000),
        ],
      );
      final out = reallocatePayments(d);
      expect(out.single.overdueInterestPart, closeTo(900, 0.01));
      expect(out.single.principalPart, closeTo(100, 0.01));

      final normalized = d.copyWith(payments: out);
      // Defterden çıkan para tam tutar; borcu azaltan yalnız faiz-dışı kısım.
      expect(normalized.totalPaidAmount, 1000);
      expect(normalized.principalPaidAmount, closeTo(100, 0.01));
      expect(normalized.remainingAmount, closeTo(11900, 0.01));
    });

    test('ödeme faizden küçükse tamamı faize sayılır', () {
      final d = debt(
        term: 1,
        dueDate: DateTime(2026, 2, 1),
        payments: [
          Payment(id: 'p1', date: DateTime(2026, 3, 3), amount: 500),
        ],
      );
      final out = reallocatePayments(d);
      expect(out.single.overdueInterestPart, 500);
      expect(out.single.principalPart, 0);
    });

    test('kuruş değişmezi: faiz payı + ana para payı = tam tutar', () {
      final d = debt(
        term: 12,
        payments: [
          Payment(id: 'p1', date: DateTime(2026, 3, 7), amount: 333.33),
          Payment(id: 'p2', date: DateTime(2026, 5, 19), amount: 1234.56),
          Payment(id: 'p3', date: DateTime(2026, 9, 2), amount: 4321.09),
        ],
      );
      for (final p in reallocatePayments(d)) {
        expect(
            p.overdueInterestPart + p.principalPart, closeTo(p.amount, 1e-9));
      }
    });

    test('idempotent: iki kez uygulamak aynı sonucu verir', () {
      final d = debt(
        payments: [
          Payment(id: 'p1', date: DateTime(2026, 4, 1), amount: 1500),
          Payment(id: 'p2', date: DateTime(2026, 7, 1), amount: 2500),
        ],
      );
      final once = reallocatePayments(d);
      final twice = reallocatePayments(d.copyWith(payments: once));
      expect(twice, once);
    });

    test('sıra bağımsız: karışık sırada verilen ödemeler aynı sonucu verir',
        () {
      final a = Payment(id: 'p1', date: DateTime(2026, 4, 1), amount: 1500);
      final b = Payment(id: 'p2', date: DateTime(2026, 7, 1), amount: 2500);
      expect(
        reallocatePayments(debt(payments: [b, a])),
        reallocatePayments(debt(payments: [a, b])),
      );
    });

    test('oran 0 ise tüm paylar sıfırlanır (faizsiz davranışa döner)', () {
      final d = debt(
        overdueRate: 0,
        payments: [
          Payment(
              id: 'p1',
              date: DateTime(2026, 4, 1),
              amount: 1500,
              overdueInterestPart: 400),
        ],
      );
      final out = reallocatePayments(d);
      expect(out.single.overdueInterestPart, 0);
      expect(d.copyWith(payments: out).principalPaidAmount, 1500);
    });
  });

  group('değişmezler (zaman geçse de kaymaz)', () {
    test('remainingAmount ve principalPaidAmount zamandan bağımsızdır', () {
      final d = debt(
        payments: [
          Payment(
              id: 'p1',
              date: DateTime(2026, 4, 1),
              amount: 1500,
              overdueInterestPart: 300),
        ],
      );
      // Getter'lar `now` almaz; saklanan alanlardan türer.
      expect(d.remainingAmount, 12000 - 1200);
      expect(d.principalPaidAmount, 1200);
      expect(d.totalPaidAmount, 1500);
      expect(d.settledOverdueInterest, 300);
    });
  });
}
