import 'package:cunehat/features/bank_import/data/draft_dedup.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx(DateTime d, double a, String title,
        {bool expense = true}) =>
    TransactionEntity(
      id: 'x',
      userId: 'u',
      walletId: 'w',
      title: title,
      tag: 'Food',
      amount: a,
      date: d,
      type:
          expense ? TransactionTypeModel.expense : TransactionTypeModel.income,
    );

ImportDraft _draft(DateTime d, double a, String desc, {bool expense = true}) =>
    ImportDraft(
      date: d,
      description: desc,
      amount: a,
      type:
          expense ? TransactionTypeModel.expense : TransactionTypeModel.income,
    );

void main() {
  test('mevcut cüzdan işlemiyle eşleşen taslak işaretlenir ve seçilmez', () {
    final existing = [_tx(DateTime(2026, 6, 15), 150, 'MARKET')];
    final drafts = [
      _draft(DateTime(2026, 6, 15), 150, 'Market'), // eşleşir (normalize)
      _draft(DateTime(2026, 6, 16), 50, 'Faiz', expense: false),
    ];
    final marked = markDuplicateDrafts(drafts, existing);
    expect(marked[0].isDuplicate, isTrue);
    expect(marked[0].selected, isFalse);
    expect(marked[1].isDuplicate, isFalse);
    expect(marked[1].selected, isTrue);
  });

  test('dosya içi tekrar ikinci kaydı işaretler', () {
    final drafts = [
      _draft(DateTime(2026, 6, 16), 50, 'Faiz', expense: false),
      _draft(DateTime(2026, 6, 16), 50, 'Faiz', expense: false),
    ];
    final marked = markDuplicateDrafts(drafts, const []);
    expect(marked[0].isDuplicate, isFalse);
    expect(marked[1].isDuplicate, isTrue);
  });

  test('aynı tutar farklı yön (gider/gelir) tekrar sayılmaz', () {
    final existing = [_tx(DateTime(2026, 6, 15), 100, 'İADE', expense: true)];
    final drafts = [
      _draft(DateTime(2026, 6, 15), 100, 'İADE', expense: false),
    ];
    final marked = markDuplicateDrafts(drafts, existing);
    expect(marked[0].isDuplicate, isFalse);
  });
}
