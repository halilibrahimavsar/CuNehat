import 'dart:math' as math;

import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/installment_progress.dart';

/// Gecikme faizi: vadesi geçmiş ama ödenmemiş bakiyeye günlük oransal işleyen
/// tahakkuk.
///
/// **Yöntem.** `gecikmişBakiye × (aylıkOran/100) × gecikilenGün/30`. Tek bir
/// gecikmiş taksit ve arada ödeme yoksa formül birebir budur.
///
/// **Neden zaman üzerinden integral?** Tahakkuku her seferinde "şu ANDAKİ
/// gecikmiş kalan × şu ANA kadar geçen gün" diye hesaplamak, borcun kapanması
/// hâlinde geçmişte birikmiş faizi geriye dönük SİLER: bütün satırların kalanı
/// 0 olur, çarpım 0 çıkar, altı aylık gecikme hiç yaşanmamış gibi olur. Bu
/// yüzden tahakkuk, gecikmiş bakiye eğrisinin zaman integralidir; eğri
/// yalnızca vade tarihlerinde (borç artar) ve ödeme tarihlerinde (borç azalır)
/// sıçradığından integral, bu kırılım noktaları arasındaki basit dikdörtgenler
/// toplamına iner.
///
/// **Değişmez.** Ana para tamamen kapandığı anda gecikmiş bakiye kalıcı olarak
/// 0'a düşer ve tahakkuk BÜYÜMEYİ DURDURUR. Bu sayede `isPaid` zaman geçtikçe
/// kendiliğinden değişmez.

/// Gün farkı, takvim günü üzerinden.
///
/// Yerel `DateTime.difference().inDays` yaz saati geçişinde 23 saatlik bir
/// günü 0 gün sayar; UTC'ye normalleştirmek bunu ortadan kaldırır.
int _daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// Planın (vade, tutar) çiftleri. Tek taksitli kayıtta kaydın kendi vadesi.
List<({DateTime due, double amount})> _schedule(DebtEntity debt) {
  final total = debt.totalDebtAmount;
  if (debt.termMonths <= 1) {
    final due = debt.dueDate;
    return due == null ? const [] : [(due: due, amount: total)];
  }
  return [
    for (var i = 0; i < debt.termMonths; i++)
      (
        due: installmentDueDate(debt.startDate, i),
        amount: installmentScheduledAmount(
          totalDebtAmount: total,
          termMonths: debt.termMonths,
          index: i,
        ),
      ),
  ];
}

/// [asOf] tarihine kadar TAHAKKUK EDEN toplam gecikme faizi.
///
/// Ödenmiş kısım düşülmez — kapanmamış tutar için [outstandingOverdueInterest].
double accruedOverdueInterest(DebtEntity debt, {required DateTime asOf}) {
  final rate = debt.overdueInterestRate;
  if (!moneyIsPositive(rate)) return 0;

  final schedule = _schedule(debt);
  if (schedule.isEmpty) return 0;

  // Eğrinin kırılım noktaları: vade tarihleri + ödeme tarihleri + bugün.
  // İlk vadeden önce gecikmiş bakiye tanım gereği 0'dır.
  final firstDue = schedule.first.due;
  if (!firstDue.isBefore(asOf)) return 0;

  final points = <DateTime>{firstDue, asOf};
  for (final row in schedule) {
    if (row.due.isAfter(firstDue) && row.due.isBefore(asOf)) {
      points.add(row.due);
    }
  }
  for (final p in debt.payments) {
    if (p.date.isAfter(firstDue) && p.date.isBefore(asOf)) points.add(p.date);
  }
  final breakpoints = points.toList()..sort();

  final dailyRate = rate / 100 / 30;
  var accrued = 0.0;

  for (var i = 0; i < breakpoints.length - 1; i++) {
    final from = breakpoints[i];
    final days = _daysBetween(from, breakpoints[i + 1]);
    if (days <= 0) continue;

    // [from] ANINDAKİ gecikmiş bakiye: o güne kadar vadesi gelmiş taksitler
    // eksi o güne kadar ana paraya sayılmış ödemeler.
    var scheduledDue = 0.0;
    for (final row in schedule) {
      if (!row.due.isAfter(from)) scheduledDue += row.amount;
    }
    var principalPaid = 0.0;
    for (final p in debt.payments) {
      // Kayıt başına değil toplamda yuvarlanır (bkz. principalPaidAmount).
      if (!p.date.isAfter(from)) {
        principalPaid += p.amount - p.overdueInterestPart;
      }
    }

    final overdueBalance = scheduledDue - principalPaid;
    if (overdueBalance <= 0) continue;

    accrued += overdueBalance * dailyRate * days;
  }

  return roundToCents(accrued);
}

/// [now] itibarıyla KAPANMAMIŞ gecikme faizi: tahakkuk eksi ödemelerin faize
/// sayılan kısmı. Asla negatif dönmez.
double outstandingOverdueInterest(DebtEntity debt, {DateTime? now}) {
  final accrued = accruedOverdueInterest(debt, asOf: now ?? DateTime.now());
  return roundToCents(math.max(0.0, accrued - debt.settledOverdueInterest));
}

/// Borcu [now] tarihinde TAMAMEN kapatmak için gereken tutar:
/// kalan ana para + kapanmamış gecikme faizi.
double payoffAmount(DebtEntity debt, {DateTime? now}) => roundToCents(
    debt.remainingAmount + outstandingOverdueInterest(debt, now: now));

/// Ödeme listesinin TAMAMINI kronolojik sırayla yeniden mahsuplar: her ödeme
/// önce o tarihe kadar kapanmamış gecikme faizini kapatır, kalanı ana paraya
/// sayılır.
///
/// Ekleme, düzenleme ve silme yollarının üçü de bunu çağırır — sonuç
/// deterministik, giriş sırasından bağımsız ve idempotenttir. Aksi hâlde
/// geçmişe tarihli bir ödeme eklemek ya da ortadaki bir ödemeyi silmek,
/// sonraki ödemelerin faiz paylarını tutarsız bırakırdı.
List<Payment> reallocatePayments(DebtEntity debt) {
  final sorted = [...debt.payments]..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      // UUIDv7 zaman sıralı: aynı gün içinde de kararlı bir sıra verir.
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });

  if (!moneyIsPositive(debt.overdueInterestRate)) {
    return [for (final p in sorted) p.copyWith(overdueInterestPart: 0)];
  }

  final out = <Payment>[];
  var interestPaid = 0.0;
  for (final p in sorted) {
    // Tahakkuk YALNIZ daha önceki ödemelere bakar → döngüsel bağımlılık yok.
    final accrued =
        accruedOverdueInterest(debt.copyWith(payments: out), asOf: p.date);
    final due = math.max(0.0, roundToCents(accrued - interestPaid));
    // Yalnız faiz payı yuvarlanır; ana para payı `amount - part` olarak
    // TÜRETİLİR (bkz. Payment.principalPart) → kuruş kaçağı olamaz.
    final part = roundToCents(math.min(p.amount, due));
    out.add(p.copyWith(overdueInterestPart: part));
    interestPaid = roundToCents(interestPaid + part);
  }
  return out;
}
