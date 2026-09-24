import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Kart cüzdanında TAKSİTLİ alışveriş: toplam tutar [count] aylık gider
/// satırına bölünür ("Başlık (k/N)").
///
/// Kullanıcı kararı (23 Eyl 2026): her ekstrede taksit tutarı kadar gider —
/// alış gününe toplam tutar değil. Böylece her ayın raporu o ay ödenen taksiti
/// gösterir; gelecek tarihli taksitler kartın limitini bugünden tutar ama
/// ilgili kesime kadar ekstreye girmez (bkz. `computeCardStatus`).
///
/// - Tutar KURUŞ üzerinden bölünür; yuvarlama farkını SON taksit emer
///   (1.000 / 3 → 333,33 · 333,33 · 333,34) — toplam kuruşu kuruşuna korunur.
/// - Tarihler alış gününe ÇAPALI ilerler (31 Oca → 28 Şub → 31 Mar); ardışık
///   kenetleme günü kalıcı aşağı çekerdi (bkz. `addMonthsAnchored`).
/// - Fiş eki yalnız ilk taksitte kalır (alışverişin fişi tek).
List<TransactionEntity> splitIntoInstallments(
  TransactionEntity purchase,
  int count, {
  String Function()? newId,
}) {
  if (count <= 1) return [purchase];
  final totalCents = (purchase.amount * 100).round();
  final perCents = totalCents ~/ count;
  final lastCents = totalCents - perCents * (count - 1);
  final idOf = newId ?? UidGenerator.generateV7;
  return [
    for (var k = 0; k < count; k++)
      TransactionEntity(
        id: idOf(),
        userId: purchase.userId,
        walletId: purchase.walletId,
        title: '${purchase.title} (${k + 1}/$count)',
        tag: purchase.tag,
        amount: (k == count - 1 ? lastCents : perCents) / 100,
        date: addMonthsAnchored(purchase.date, k, purchase.date.day),
        type: purchase.type,
        receiptFileName: k == 0 ? purchase.receiptFileName : null,
        origin: purchase.origin,
        importBatchId: purchase.importBatchId,
      ),
  ];
}
