import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/draft_dedup.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kendi cüzdanların arasındaki para taşıması (bankadan karta ödeme) bir
/// harcama/gelir değildir: inceleme ekranında kategori yerine transfer olarak
/// işaretlenir.
void main() {
  ImportDraft payment({bool income = false, String? category}) => ImportDraft(
        date: DateTime(2026, 9, 30),
        description: income
            ? 'Ödeme - Teşekkür Ederiz'
            : 'Kart İşlemleri - 4321 nolu kart ödemesi',
        amount: 1303.03,
        type:
            income ? TransactionTypeModel.income : TransactionTypeModel.expense,
        categoryId: category,
      );

  BankImportReview review(List<ImportDraft> drafts) => BankImportReview(
        drafts: drafts,
        expenseCategories: const [],
        incomeCategories: const [],
        skippedRows: 0,
      );

  group('işaret', () {
    test('işaretli satır kategori İSTEMEZ; işaret kalkınca yine ister', () {
      final plain = payment();
      expect(plain.needsCategory, isTrue);

      final marked = plain.withTransfer('c1');
      expect(marked.isTransfer, isTrue);
      expect(marked.needsCategory, isFalse);

      final unmarked = marked.withTransfer(null);
      expect(unmarked.isTransfer, isFalse);
      expect(unmarked.needsCategory, isTrue);
    });

    test('kopyalar işareti korur', () {
      final marked = payment().withTransfer('c1');
      expect(marked.copyWith(amount: 1).transferWalletId, 'c1');
      expect(marked.withoutDuplicate().transferWalletId, 'c1');
      expect(
          marked.withCategory('x', CategorySource.user).transferWalletId, 'c1');
    });

    test('içe aktarma kapısı: kategorisiz ama işaretli satır engel değildir',
        () {
      expect(review([payment()]).canCommit, isFalse);
      expect(review([payment()]).selectedUncategorizedCount, 1);

      final ok = review([payment().withTransfer('c1')]);
      expect(ok.selectedUncategorizedCount, 0);
      expect(ok.uncategorizedCount, 0);
      expect(ok.canCommit, isTrue);
    });
  });

  group('öbür ekstre sonradan gelince', () {
    // Banka ekstresi aktarılıp ödeme satırı karta bağlandı: kartın defterinde
    // artık bir transfer bacağı (sistem satırı) var. Ardından kartın kendi
    // dökümü aynı ödemeyi "Ödeme - Teşekkür Ederiz" diye getirir.
    final leg = TransactionEntity(
      id: 'leg',
      userId: 'u',
      walletId: 'c1',
      title: 'Kart ödemesi ← Banka',
      tag: CashMovementTags.transfer,
      amount: 1303.03,
      date: DateTime(2026, 9, 30),
      type: TransactionTypeModel.income,
      isSystem: true,
      linkedRecordId: 'pair-1',
    );

    test('kartın dökümündeki ödeme satırı ikinci kez EKLENMEZ', () {
      final r = markDuplicateDrafts([payment(income: true)], [leg]).single;

      expect(r.duplicateOf?.existingId, 'leg');
      expect(r.duplicateOf?.existingIsSystem, isTrue);
      expect(r.selected, isFalse);
    });

    test('başka tutarlı ödeme o bacağın tekrarı sayılmaz', () {
      final other = payment(income: true).copyWith(amount: 500);
      expect(markDuplicateDrafts([other], [leg]).single.duplicateOf, isNull);
    });
  });
}
