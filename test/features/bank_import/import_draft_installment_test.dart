import 'package:cunehat/features/bank_import/data/draft_dedup.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ekstredeki taksit satırı (UX turu · kart ekstresi, 11 Eki 2026).
///
/// Kullanıcı kararı: ekstrede "1/6" görülen alışverişin kalan beş taksiti de
/// ileri tarihe yazılsın. Yazılmadıklarında kartın borcu ve kullanılabilir
/// limiti kalan taksitler kadar eksik görünüyordu.
void main() {
  ImportDraft installment({
    required int no,
    required int count,
    required DateTime purchase,
    double amount = 503.03,
    String description = 'ORNEK MAGAZA',
  }) {
    final info = DraftInstallment(no: no, count: count, purchaseDate: purchase);
    return ImportDraft(
      date: info.dateOf(no),
      description: '$description ($no/$count)',
      amount: amount,
      type: TransactionTypeModel.expense,
      categoryId: 'cat',
      installment: info,
    );
  }

  TransactionEntity written(ImportDraft d, {String group = 'g1'}) => d.toEntity(
        id: 'row',
        userId: 'u',
        walletId: 'kart',
        importBatchId: 'batch',
        installmentGroupId: group,
      );

  group('kalan taksitler', () {
    test('1/3 → 2/3 ve 3/3 ileri tarihe, aynı grupla ve aynı içe aktarımla',
        () {
      final d = installment(no: 1, count: 3, purchase: DateTime(2026, 9, 11));
      final first = written(d);
      var n = 0;
      final rest = d.remainingInstallments(first, newId: () => 'n${n++}');

      expect(first.installmentNo, 1);
      expect(first.installmentCount, 3);
      expect(first.installmentGroupId, 'g1');

      expect(rest.map((t) => t.title),
          ['ORNEK MAGAZA (2/3)', 'ORNEK MAGAZA (3/3)']);
      expect(rest.map((t) => t.date),
          [DateTime(2026, 10, 11), DateTime(2026, 11, 11)]);
      expect(rest.map((t) => t.installmentNo), [2, 3]);
      expect(rest.every((t) => t.installmentGroupId == 'g1'), isTrue);
      // "Geri al" hepsini birlikte kaldırabilsin.
      expect(rest.every((t) => t.importBatchId == 'batch'), isTrue);
      expect(
          rest.every((t) => t.origin == TransactionOrigin.bankImport), isTrue);
      expect(rest.every((t) => t.tag == 'cat' && t.isExpense), isTrue);
      expect(rest.every((t) => t.amount == 503.03), isTrue);
    });

    test('tarihler alışveriş gününe ÇAPALI ilerler (31 Oca → 28 Şub → 31 Mar)',
        () {
      final d = installment(no: 1, count: 3, purchase: DateTime(2026, 1, 31));
      final rest =
          d.remainingInstallments(written(d), newId: () => 'x').toList();
      expect(rest.map((t) => t.date),
          [DateTime(2026, 2, 28), DateTime(2026, 3, 31)]);
    });

    test('ortadaki taksitten (2/3) yalnız sonrakiler üretilir', () {
      final d = installment(no: 2, count: 3, purchase: DateTime(2026, 9, 11));
      expect(d.date, DateTime(2026, 10, 11));
      final rest = d.remainingInstallments(written(d), newId: () => 'x');
      expect(rest.single.title, 'ORNEK MAGAZA (3/3)');
      expect(rest.single.date, DateTime(2026, 11, 11));
    });

    test('son taksitten ve taksitsiz satırdan bir şey üretilmez', () {
      final last =
          installment(no: 3, count: 3, purchase: DateTime(2026, 9, 11));
      expect(
          last.remainingInstallments(written(last), newId: () => 'x'), isEmpty);

      final plain = ImportDraft(
        date: DateTime(2026, 9, 11),
        description: 'ORNEK BUFE',
        amount: 10,
        type: TransactionTypeModel.expense,
      );
      final e = plain.toEntity(id: 'p', userId: 'u', walletId: 'kart');
      expect(e.installmentGroupId, isNull);
      expect(e.installmentNo, isNull);
      expect(plain.remainingInstallments(e, newId: () => 'x'), isEmpty);
    });

    test('kopyalar taksit bilgisini korur', () {
      final d = installment(no: 1, count: 6, purchase: DateTime(2026, 10, 6));
      expect(d.copyWith(amount: 1).installment, d.installment);
      expect(
          d.withCategory('c2', CategorySource.user).installment, d.installment);
      expect(d.withoutDuplicate().installment, d.installment);
    });
  });

  group('tekrar tespiti: taksit kimliği', () {
    // Eylül ekstresi 1/3'ü yazdı ve 2/3, 3/3'ü 503,03 TAHMİNİYLE ileri
    // tarihe koydu. Banka kuruş farkını ilk taksite yazar: 2/3 gerçekte
    // 503,00 gelir (gerçek dökümde ölçüldü).
    List<TransactionEntity> ledgerAfterFirst() {
      final d = installment(no: 1, count: 3, purchase: DateTime(2026, 9, 11));
      final first = written(d);
      var n = 0;
      return [
        first,
        ...d.remainingInstallments(first, newId: () => 'n${n++}'),
      ];
    }

    test('ileri yazılmış taksit, kuruş farkına ve başlığa rağmen bulunur', () {
      final incoming = installment(
        no: 2,
        count: 3,
        purchase: DateTime(2026, 9, 11),
        amount: 503.00,
        description: 'BASKA YAZIM',
      );
      final r = markDuplicateDrafts([incoming], ledgerAfterFirst()).single;

      expect(r.duplicateOf?.kind, DuplicateKind.exact);
      expect(r.duplicateOf?.existingId, 'n0');
      expect(r.selected, isFalse, reason: 'ikinci kez eklenmez');
      // Defterdeki tutar bizim tahminimizdi; bankanınki esas.
      expect(r.duplicateOf?.amountDelta, -0.03);
      expect(r.correctExisting, isTrue);
    });

    test('tutar aynıysa düzeltme istenmez', () {
      final incoming = installment(
          no: 2, count: 3, purchase: DateTime(2026, 9, 11), amount: 503.03);
      final r = markDuplicateDrafts([incoming], ledgerAfterFirst()).single;
      expect(r.duplicateOf?.existingId, 'n0');
      expect(r.correctExisting, isFalse);
    });

    test('başka taksit numarası ya da uzak tutar eşleşmez', () {
      final ledger = ledgerAfterFirst();
      final farAmount = installment(
          no: 2, count: 3, purchase: DateTime(2026, 9, 11), amount: 650);
      expect(
          markDuplicateDrafts([farAmount], ledger).single.duplicateOf, isNull);

      // Aynı gün, aynı tutarla başka bir yerden 6 taksitli alışverişin
      // 2. taksiti: taksit kimliği (2/6 ≠ 2/3) tutmaz.
      final otherPlan = installment(
        no: 2,
        count: 6,
        purchase: DateTime(2026, 9, 11),
        amount: 503.03,
        description: 'BASKA DUKKAN',
      );
      expect(
          markDuplicateDrafts([otherPlan], ledger).single.duplicateOf, isNull);
    });

    test('aynı gün iki ayrı taksitli alışveriş: her kayıt tek satır tüketir',
        () {
      final a = installment(no: 2, count: 3, purchase: DateTime(2026, 9, 11));
      final ledger = [
        written(a).copyWith(id: 'e1'),
      ];
      final r = markDuplicateDrafts([a, a], ledger, rowsProvenDistinct: true);
      expect(r.where((d) => d.duplicateOf != null), hasLength(1));
      expect(r.where((d) => d.selected), hasLength(1));
    });

    test(
        'ESKİ içe aktarımın satırı (özgün tarihte, başlıkta "(2/3)") yeniden '
        'eklenmez', () {
      // Düzeltmeden önce yazılmış satır: taksit alanı yok, tarih 11 Eylül.
      final legacy = TransactionEntity(
        id: 'old',
        userId: 'u',
        walletId: 'kart',
        title: '20260911 ORNEK MAGAZA 2. Taksit (2/3)',
        tag: 'cat',
        amount: 503,
        date: DateTime(2026, 9, 11),
        type: TransactionTypeModel.expense,
        origin: TransactionOrigin.bankImport,
      );
      final incoming = installment(
          no: 2, count: 3, purchase: DateTime(2026, 9, 11), amount: 503);
      final r = markDuplicateDrafts([incoming], [legacy]).single;

      expect(r.duplicateOf?.existingId, 'old');
      expect(r.selected, isFalse);
      expect(r.correctExisting, isFalse);
    });
  });
}
