import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';

/// Ekstrenin kendi beyan ettiği kapanış bakiyesi ve o bakiyenin tarihi.
typedef StatementClosing = ({double amount, DateTime date});

/// Satır bakiyesi sütunu olan bir ekstrenin kapanış bakiyesi.
///
/// Neden: bitiş ekranı kullanıcıdan "bankandaki bakiyeyi yaz" diye istiyordu,
/// oysa hesap ekstresinin son satırı bankanın o günkü bakiyesini zaten
/// taşıyor ve uygulama onu ayrıştırıp yalnız doğrulamada kullanıp atıyordu.
///
/// Yalnız bakiye zinciri KANITLANMIŞSA döner (ekstrenin kendi beyanlarıyla
/// doğrulandı ya da her satırın bakiye farkı tutarıyla tuttu). Tutmayan bir
/// zincirden okunan "kapanış" yanlış bir eşitlemeyi önerirdi — sessiz yanlış
/// sayı, hiç sayı göstermemekten kötüdür.
///
/// Sıra yönü mutabakattan okunur: artan sıralı ekstrede kapanış SON satırın,
/// azalan sıralıda (yeniden eskiye) İLK satırın bakiyesidir.
StatementClosing? statementClosing({
  required List<ImportDraft> drafts,
  required List<double?> balances,
  required BalanceReconciliation? reconciliation,
  required StatementVerification verification,
}) {
  final proven = verification.status == StatementVerificationStatus.verified ||
      reconciliation?.status == ReconcileStatus.matched;
  if (!proven || drafts.isEmpty || balances.length != drafts.length) {
    return null;
  }
  final reverse = reconciliation?.reverseOrder ?? false;
  final order = reverse
      ? List<int>.generate(drafts.length, (i) => i)
      : List<int>.generate(drafts.length, (i) => drafts.length - 1 - i);
  for (final i in order) {
    final balance = balances[i];
    if (balance != null) return (amount: balance, date: drafts[i].date);
  }
  return null;
}
