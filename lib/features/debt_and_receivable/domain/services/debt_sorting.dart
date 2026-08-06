import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/installment_progress.dart';

/// Aktif borç listesinin görüntüleme sırası:
/// 1. gecikmiş taksiti olanlar önce (yapılacak iş listenin başında dursun),
/// 2. sıradaki ödenmemiş taksitin vadesi artan (vadesi olmayan sona),
/// 3. eşitlikte başlık.
///
/// Sıralama depolama katmanında DEĞİL burada yapılır: `getAllDebts()`
/// hatırlatma senkronu ve cüzdan metriği tarafından da tüketiliyor, oralarda
/// sıranın anlamı yok.
List<DebtEntity> sortDebtsForDisplay(List<DebtEntity> debts, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final sorted = [...debts];
  sorted.sort((a, b) {
    final aOverdue = hasOverdueInstallment(a, now: reference);
    final bOverdue = hasOverdueInstallment(b, now: reference);
    if (aOverdue != bOverdue) return aOverdue ? -1 : 1;

    final aDue = nextUnpaidInstallmentDate(a);
    final bDue = nextUnpaidInstallmentDate(b);
    if (aDue != null && bDue != null) {
      final byDate = aDue.compareTo(bDue);
      if (byDate != 0) return byDate;
    } else if (aDue != bDue) {
      return aDue == null ? 1 : -1;
    }

    return a.title.compareTo(b.title);
  });
  return sorted;
}
