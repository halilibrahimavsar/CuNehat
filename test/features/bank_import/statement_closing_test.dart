import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/statement_closing.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

ImportDraft _d(int day) => ImportDraft(
      date: DateTime(2026, 8, day),
      description: 'X',
      amount: 10,
      type: TransactionTypeModel.expense,
    );

BalanceReconciliation _rec({bool reverse = false, bool matched = true}) =>
    BalanceReconciliation(
      status: matched ? ReconcileStatus.matched : ReconcileStatus.mismatch,
      derivedSigned: const [],
      checked: 2,
      matched: matched ? 2 : 0,
      reverseOrder: reverse,
    );

void main() {
  test('artan sırada kapanış SON satırın bakiyesi ve tarihi', () {
    final c = statementClosing(
      drafts: [_d(1), _d(2), _d(3)],
      balances: [100, 90, 80],
      reconciliation: _rec(),
      verification: StatementVerification.none,
    );
    expect(c!.amount, 80);
    expect(c.date, DateTime(2026, 8, 3));
  });

  test('azalan sırada (yeniden eskiye) kapanış İLK satırınki', () {
    final c = statementClosing(
      drafts: [_d(3), _d(2), _d(1)],
      balances: [80, 90, 100],
      reconciliation: _rec(reverse: true),
      verification: StatementVerification.none,
    );
    expect(c!.amount, 80);
    expect(c.date, DateTime(2026, 8, 3));
  });

  test('son satırın bakiyesi yoksa bir öncekine düşer', () {
    final c = statementClosing(
      drafts: [_d(1), _d(2)],
      balances: [100, null],
      reconciliation: _rec(),
      verification: StatementVerification.none,
    );
    expect(c!.amount, 100);
    expect(c.date, DateTime(2026, 8, 1));
  });

  test('zincir TUTMUYORSA kapanış yok (yanlış eşitleme önerilmez)', () {
    expect(
      statementClosing(
        drafts: [_d(1), _d(2)],
        balances: [100, 90],
        reconciliation: _rec(matched: false),
        verification: StatementVerification.none,
      ),
      isNull,
    );
  });

  test('ekstrenin kendi beyanıyla doğrulandıysa mutabakatsız da güvenilir', () {
    final c = statementClosing(
      drafts: [_d(1)],
      balances: [42],
      reconciliation: null,
      verification: const StatementVerification(
        status: StatementVerificationStatus.verified,
        checks: [],
      ),
    );
    expect(c!.amount, 42);
  });

  test('bakiye listesi taslaklarla hizalı değilse kapanış yok', () {
    expect(
      statementClosing(
        drafts: [_d(1), _d(2)],
        balances: [100],
        reconciliation: _rec(),
        verification: StatementVerification.none,
      ),
      isNull,
    );
  });
}
