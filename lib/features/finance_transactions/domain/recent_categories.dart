import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// İşlem formunun "son kullanılanlar" şeridi: bu cüzdanda EN SON kullanılan,
/// birbirinden farklı kategoriler — yeniden eskiye.
///
/// Kategori şeridi kullanıcının kendi sırasında durur ve ekrana ~4 kök sığar;
/// her gün aynı üç-dört kaleme giren kullanıcı her kayıtta şeridi kaydırıyordu.
/// Bu liste o sırayı BOZMAZ, yalnız önüne bir kısayol satırı koyar.
///
/// - Yalnız [isExpense] türündeki ve elle girilebilir (sistem olmayan) satırlar
///   sayılır: transfer/borç/yatırım bacaklarının etiketi kategori değildir.
/// - [validIds] dışındaki etiketler atlanır (silinmiş ya da bu cüzdanda gizli
///   kategori seçilemez).
List<String> recentCategoryIds(
  Iterable<TransactionEntity> transactions, {
  required bool isExpense,
  required Set<String> validIds,
  int limit = 4,
}) {
  final candidates = transactions
      .where((t) =>
          !t.isSystem && t.isExpense == isExpense && validIds.contains(t.tag))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  final recent = <String>[];
  for (final t in candidates) {
    if (recent.contains(t.tag)) continue;
    recent.add(t.tag);
    if (recent.length == limit) break;
  }
  return recent;
}
