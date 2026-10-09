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
/// - Satırlar bir GRUP kimliği ve açık "k/N" taşır
///   ([TransactionEntity.installmentGroupId]): detayda birlikte görülür,
///   tek seferde silinir.
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
  final groupId = idOf();
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
        installmentGroupId: groupId,
        installmentNo: k + 1,
        installmentCount: count,
      ),
  ];
}

/// [all] içinde [groupId] taksit grubunun satırları, taksit sırasıyla.
List<TransactionEntity> installmentGroup(
  Iterable<TransactionEntity> all,
  String groupId,
) =>
    [
      for (final t in all)
        if (t.installmentGroupId == groupId) t,
    ]..sort((a, b) => (a.installmentNo ?? 0).compareTo(b.installmentNo ?? 0));

/// Kartın SÜREN taksitli alışverişleri: en az bir taksiti [today]'den sonra
/// tarihli gruplar. Kart ayrıntısı "kalan taksitler" toplamının hangi
/// alışverişlerden geldiğini bununla gösterir.
/// Süren bir taksitli alışveriş (bkz. [activeInstallmentPlans]).
typedef InstallmentPlan = ({
  String groupId,
  List<TransactionEntity> items,
  double remaining,
  int left,
});

List<InstallmentPlan> activeInstallmentPlans(
  Iterable<TransactionEntity> ledger, {
  required DateTime today,
}) {
  final dayEnd = DateTime(today.year, today.month, today.day + 1);
  final groups = <String, List<TransactionEntity>>{};
  for (final t in ledger) {
    final g = t.installmentGroupId;
    if (g != null) groups.putIfAbsent(g, () => []).add(t);
  }
  final out = <InstallmentPlan>[];
  for (final e in groups.entries) {
    final upcoming = e.value.where((t) => !t.date.isBefore(dayEnd));
    final remaining = upcoming.fold<double>(0, (s, t) => s + t.amount);
    if (remaining <= 0) continue;
    final items = [...e.value]
      ..sort((a, b) => (a.installmentNo ?? 0).compareTo(b.installmentNo ?? 0));
    out.add((
      groupId: e.key,
      items: items,
      remaining: (remaining * 100).round() / 100,
      left: upcoming.length,
    ));
  }
  out.sort((a, b) => b.remaining.compareTo(a.remaining));
  return out;
}

/// Taksit satırının başlığından alışverişin adı: sondaki " (k/N)" atılır
/// ("Laptop (2/6)" → "Laptop"). Kullanıcı başlığı düzenlediyse olduğu gibi.
String installmentBaseTitle(String title) =>
    title.replaceFirst(RegExp(r' \(\d+/\d+\)$'), '');
