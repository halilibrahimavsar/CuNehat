import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/installment_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Vadesi geçmemiş bir referans an: gecikme ekseni ayrıca test edilir.
  final start = DateTime(2026, 1, 15);
  final beforeAnyDue = DateTime(2026, 1, 20);

  List<InstallmentProgress> plan({
    double total = 12000,
    int term = 12,
    required double paid,
    DateTime? now,
  }) =>
      buildInstallmentPlan(
        totalDebtAmount: total,
        termMonths: term,
        startDate: start,
        principalPaidAmount: paid,
        now: now ?? beforeAnyDue,
      );

  group('buildInstallmentPlan', () {
    test('hiç ödeme yoksa tüm taksitler unpaid', () {
      final rows = plan(paid: 0);

      expect(rows, hasLength(12));
      expect(rows.every((r) => r.status == InstallmentStatus.unpaid), isTrue);
      expect(rows.every((r) => r.paidAmount == 0), isTrue);
      expect(rows.first.scheduledAmount, 1000);
    });

    test('3 kez 100 ₺ kısmi ödeme SADECE ilk taksiti kısmen doldurur', () {
      // Regresyon: durum ödeme SAYISINA baktığı için ilk üç taksit
      // "ödendi" görünüyordu (3 kayıt = 3 taksit), oysa toplam 300 ₺.
      final rows = plan(paid: 300);

      expect(rows[0].status, InstallmentStatus.partial);
      expect(rows[0].paidAmount, 300);
      expect(rows[0].remainingAmount, 700);
      expect(rows[1].status, InstallmentStatus.unpaid);
      expect(rows[2].status, InstallmentStatus.unpaid);
    });

    test('tek seferde "Tümünü öde" TÜM taksitleri kapatır', () {
      // Regresyon: tek ödeme kaydı olduğu için yalnız 1. taksit ödenmiş,
      // kalan 11'i gecikmiş görünüyordu.
      final rows = plan(paid: 12000, now: DateTime(2027, 6, 1));

      expect(rows.every((r) => r.status == InstallmentStatus.paid), isTrue);
      expect(rows.any((r) => r.isOverdue), isFalse);
    });

    test('ödeme taksitler arasında taşar', () {
      final rows = plan(paid: 2500);

      expect(rows[0].status, InstallmentStatus.paid);
      expect(rows[1].status, InstallmentStatus.paid);
      expect(rows[2].status, InstallmentStatus.partial);
      expect(rows[2].paidAmount, 500);
      expect(rows[3].status, InstallmentStatus.unpaid);
    });

    test('gecikme ödeme durumundan bağımsız bir eksendir', () {
      // 3 taksit vadesi geçmiş; 1.'si tam, 2.'si kısmen ödenmiş.
      final rows = plan(paid: 1400, now: DateTime(2026, 4, 20));

      expect(rows[0].status, InstallmentStatus.paid);
      expect(rows[0].isOverdue, isFalse, reason: 'ödenmiş taksit gecikmez');

      expect(rows[1].status, InstallmentStatus.partial);
      expect(rows[1].isOverdue, isTrue, reason: 'kısmi ödeme gecikmeyi silmez');

      expect(rows[2].status, InstallmentStatus.unpaid);
      expect(rows[2].isOverdue, isTrue);

      expect(rows[3].isOverdue, isFalse, reason: 'vadesi henüz gelmedi');
    });

    test('son taksit yuvarlama artığını üstlenir', () {
      // 1000/3 = 333,33 → 333,33×3 = 999,99; son taksit 333,34 olmalı ki
      // borç tamamen ödendiğinde son taksit de "ödendi" olabilsin.
      final rows = plan(total: 1000, term: 3, paid: 1000);

      expect(rows[0].scheduledAmount, 333.33);
      expect(rows[1].scheduledAmount, 333.33);
      expect(rows[2].scheduledAmount, 333.34);
      expect(rows.every((r) => r.status == InstallmentStatus.paid), isTrue);
    });

    test('vade 0 ise plan boştur', () {
      expect(plan(term: 0, paid: 0), isEmpty);
    });

    test('yuvarlama toplamı aşarsa son taksit 0 olur, ÇÖKMEZ', () {
      // REGRESYON: `monthly` kuruşa yuvarlanırken YUKARI kaçabilir
      // (1 ₺ / 36 ay → 0,03; 0,03 × 35 = 1,05 > 1,00). Son satırın planlanan
      // tutarı -0,05'e düşüyor, `clamp(0.0, -0.05)` ArgumentError fırlatıyor
      // (num.clamp alt sınır ≤ üst sınır ister) ve plan listesini çizen build
      // kırmızı ekrana dönüyordu.
      final rows = buildInstallmentPlan(
        totalDebtAmount: 1.0,
        termMonths: 36,
        startDate: DateTime(2026, 1, 15),
        principalPaidAmount: 0,
        now: DateTime(2026, 1, 1),
      );

      expect(rows, hasLength(36));
      expect(rows.last.scheduledAmount, 0.0);
      // Ödenecek bir şey kalmadığı için son satır "ödendi" sayılır ve
      // gecikmiş görünmez.
      expect(rows.last.status, InstallmentStatus.paid);
      expect(rows.last.isOverdue, isFalse);
      expect(rows.last.remainingAmount, 0.0);
    });

    test('planlanan tutarların hiçbiri negatif olamaz', () {
      for (final term in [2, 3, 7, 12, 24, 36, 60]) {
        for (final total in [0.01, 0.05, 1.0, 3.33, 1000.0]) {
          final rows = buildInstallmentPlan(
            totalDebtAmount: total,
            termMonths: term,
            startDate: DateTime(2026, 1, 15),
            principalPaidAmount: 0,
            now: DateTime(2026, 1, 1),
          );
          for (final r in rows) {
            expect(r.scheduledAmount, greaterThanOrEqualTo(0.0),
                reason: 'total=$total term=$term taksit=${r.number}');
          }
        }
      }
    });
  });

  group('buildInstallmentPlanFor', () {
    test('borcun toplam/vade/ödenen değerlerini tek kaynaktan okur', () {
      final debt = DebtEntity(
        calcMode: DebtCalcMode.none,
        userId: 'u',
        walletId: 'w',
        title: 'Kredi',
        counterparty: 'Banka',
        type: DebtType.installmentDebt,
        principalAmount: 1200,
        interestRate: 0,
        termMonths: 12,
        startDate: start,
        expectedTotalAmount: 1200,
        payments: [
          Payment(id: 'p1', date: start, amount: 100),
          Payment(id: 'p2', date: start, amount: 100),
        ],
      );

      final rows = buildInstallmentPlanFor(debt, now: beforeAnyDue);

      expect(rows, hasLength(12));
      expect(rows[0].status, InstallmentStatus.paid);
      expect(rows[1].status, InstallmentStatus.paid);
      expect(rows[2].status, InstallmentStatus.unpaid);
    });
  });

  // Liste ALLOKE ETMEYEN sorgular: kart listesi ve hatırlatma senkronu her
  // borç için bunları çağırıyor; 600 satırlık plan kurup atmamalılar.
  group('plan kurmayan sorgular', () {
    final start = DateTime(2026, 1, 1);

    DebtEntity debt({
      double total = 12000,
      int term = 12,
      double paid = 0,
      bool isPaid = false,
      DateTime? dueDate,
      bool noDueDate = false,
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
          startDate: start,
          dueDate: noDueDate ? null : (dueDate ?? DateTime(2027, 1, 1)),
          payments: paid > 0
              ? [Payment(id: 'p1', date: start, amount: paid)]
              : const [],
          isPaid: isPaid,
          expectedTotalAmount: total,
        );

    test('paidInstallmentCount tam kapanan taksitleri sayar', () {
      expect(paidInstallmentCount(debt(paid: 0)), 0);
      expect(paidInstallmentCount(debt(paid: 999)), 0); // 1 taksiti bile bitmez
      expect(paidInstallmentCount(debt(paid: 1000)), 1);
      expect(paidInstallmentCount(debt(paid: 3500)), 3);
      expect(paidInstallmentCount(debt(paid: 12000)), 12);
    });

    test('nextUnpaidInstallmentDate sıradaki ödenmemiş taksite işaret eder',
        () {
      expect(nextUnpaidInstallmentDate(debt(paid: 0)), DateTime(2026, 2, 1));
      expect(nextUnpaidInstallmentDate(debt(paid: 2000)), DateTime(2026, 4, 1));
      // Tüm taksitler kapandıysa sıradaki taksit yok.
      expect(nextUnpaidInstallmentDate(debt(paid: 12000)), isNull);
      expect(nextUnpaidInstallmentDate(debt(isPaid: true)), isNull);
    });

    test('tek taksitli kayıtta kaydın kendi vadesi geçerlidir', () {
      expect(
          nextUnpaidInstallmentDate(
              debt(term: 1, dueDate: DateTime(2026, 5, 5))),
          DateTime(2026, 5, 5));
      // Vade opsiyonel (kişisel borç): yoksa hatırlatma da yok.
      expect(nextUnpaidInstallmentDate(debt(term: 1, noDueDate: true)), isNull);
    });

    test('hasOverdueInstallment ARA taksit gecikmesini de yakalar', () {
      // REGRESYON: kart yalnız kaydın SON vadesine bakıyordu; 12 taksitin
      // 6'sı gecikmiş bir borç son vade gelmediği için tertemiz görünüyordu.
      final d = debt(paid: 0);
      expect(hasOverdueInstallment(d, now: DateTime(2026, 1, 15)), isFalse);
      expect(hasOverdueInstallment(d, now: DateTime(2026, 7, 15)), isTrue);
      // Son vade (2027-01-01) daha gelmemiş olmasına rağmen gecikme var.
      expect(d.dueDate!.isAfter(DateTime(2026, 7, 15)), isTrue);
    });

    test('kapanmış borç gecikmiş sayılmaz', () {
      expect(
        hasOverdueInstallment(debt(isPaid: true), now: DateTime(2030, 1, 1)),
        isFalse,
      );
    });
  });
}
