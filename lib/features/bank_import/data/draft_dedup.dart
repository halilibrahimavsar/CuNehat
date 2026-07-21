/// Taslakları olası tekrarlara göre işaretler.
///
/// Eşleşme anahtarı: (gün, işaretli-kuruş, normalize-açıklama). Hem mevcut
/// cüzdan işlemleriyle hem de dosya içi kendi tekrarlarıyla karşılaştırır.
/// Eşleşen taslak `isDuplicate=true, selected=false` döner (kullanıcı isterse
/// incelemede yeniden işaretler). Muhafazakâr: fazladan tekrar işaretlemez,
/// eksik kalanı kullanıcı görür.
library;

import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

List<ImportDraft> markDuplicateDrafts(
  List<ImportDraft> drafts,
  List<TransactionEntity> existing,
) {
  final seen = <String>{
    for (final t in existing) _key(t.date, t.amount, t.isExpense, t.title),
  };

  final result = <ImportDraft>[];
  final withinFile = <String>{};
  for (final d in drafts) {
    final k = _key(d.date, d.amount, d.type.name == 'expense', d.description);
    final isDup = seen.contains(k) || withinFile.contains(k);
    withinFile.add(k);
    result.add(
      isDup ? d.copyWith(isDuplicate: true, selected: false) : d,
    );
  }
  return result;
}

String _key(DateTime date, double amount, bool isExpense, String desc) {
  final day = DateTime(date.year, date.month, date.day).toIso8601String();
  final cents = (amount.abs() * 100).round() * (isExpense ? -1 : 1);
  final normDesc = desc.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return '$day|$cents|$normDesc';
}
