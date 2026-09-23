import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/installments.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _purchase({double amount = 1000, DateTime? date}) =>
    TransactionEntity(
      id: null,
      userId: 'u',
      walletId: 'card',
      title: 'Buzdolabı',
      tag: 'cat-ev',
      amount: amount,
      date: date ?? DateTime(2026, 1, 31, 14, 5),
      type: TransactionTypeModel.expense,
      receiptFileName: 'fis.jpg',
      origin: TransactionOrigin.manual,
    );

void main() {
  test('kuruş üzerinden bölünür; yuvarlama farkını SON taksit emer', () {
    final rows = splitIntoInstallments(_purchase(), 3);
    expect(rows.map((t) => t.amount), [333.33, 333.33, 333.34]);
    final totalCents =
        rows.fold<int>(0, (s, t) => s + (t.amount * 100).round());
    expect(totalCents, 100000, reason: 'toplam kuruşu kuruşuna korunur');
  });

  test('başlık (k/N); tarihler alış gününe ÇAPALI ilerler (ay sonu)', () {
    final rows = splitIntoInstallments(_purchase(), 3);
    expect(rows.map((t) => t.title),
        ['Buzdolabı (1/3)', 'Buzdolabı (2/3)', 'Buzdolabı (3/3)']);
    expect(rows.map((t) => t.date), [
      DateTime(2026, 1, 31, 14, 5),
      DateTime(2026, 2, 28, 14, 5),
      DateTime(2026, 3, 31, 14, 5),
    ]);
  });

  test('her taksit ayrı kimlik; fiş yalnız ilkinde; köken korunur', () {
    var n = 0;
    final rows =
        splitIntoInstallments(_purchase(), 2, newId: () => 'id-${n++}');
    expect(rows.map((t) => t.id), ['id-0', 'id-1']);
    expect(rows.first.receiptFileName, 'fis.jpg');
    expect(rows.last.receiptFileName, isNull);
    expect(rows.every((t) => t.origin == TransactionOrigin.manual), isTrue);
    expect(rows.every((t) => t.walletId == 'card' && t.tag == 'cat-ev'),
        isTrue);
  });

  test('tek çekim olduğu gibi döner', () {
    final p = _purchase();
    expect(splitIntoInstallments(p, 1), [p]);
  });
}
