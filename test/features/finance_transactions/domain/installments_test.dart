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
    // İlk kimlik grubun; satırlar sonrakileri alır.
    expect(rows.map((t) => t.id), ['id-1', 'id-2']);
    expect(rows.first.receiptFileName, 'fis.jpg');
    expect(rows.last.receiptFileName, isNull);
    expect(rows.every((t) => t.origin == TransactionOrigin.manual), isTrue);
    expect(rows.every((t) => t.walletId == 'card' && t.tag == 'cat-ev'),
        isTrue);
  });

  test('satırlar AYNI grup kimliğini ve açık k/N\'yi taşır', () {
    final rows = splitIntoInstallments(_purchase(), 3);
    final group = rows.first.installmentGroupId;
    expect(group, isNotNull);
    expect(rows.every((t) => t.installmentGroupId == group), isTrue);
    expect(rows.map((t) => t.installmentNo), [1, 2, 3]);
    expect(rows.every((t) => t.installmentCount == 3), isTrue);
    // İki ayrı alışveriş ayrı gruptur.
    expect(splitIntoInstallments(_purchase(), 2).first.installmentGroupId,
        isNot(group));
  });

  test('installmentGroup: grubun satırları sırayla; başkaları karışmaz', () {
    final a = splitIntoInstallments(_purchase(), 3);
    final b = splitIntoInstallments(_purchase(amount: 90), 3);
    final mixed = [a[2], b[0], a[0], b[1], a[1]];
    expect(installmentGroup(mixed, a.first.installmentGroupId!),
        [a[0], a[1], a[2]]);
  });

  test('activeInstallmentPlans: yalnız GELECEK taksiti kalan gruplar', () {
    final done = splitIntoInstallments(
        _purchase(amount: 300, date: DateTime(2026, 1, 10)), 3);
    final running = splitIntoInstallments(
        _purchase(amount: 600, date: DateTime(2026, 3, 10)), 6);
    final plans = activeInstallmentPlans(
      [...done, ...running],
      today: DateTime(2026, 4, 20),
    );
    expect(plans, hasLength(1));
    expect(plans.single.groupId, running.first.installmentGroupId);
    // Mart ve Nisan geçti; Mayıs–Ağustos (4 × 100) kaldı.
    expect(plans.single.remaining, 400);
    expect(plans.single.left, 4);
    expect(plans.single.items, hasLength(6));
  });

  test('tek çekim olduğu gibi döner', () {
    final p = _purchase();
    expect(splitIntoInstallments(p, 1), [p]);
  });
}
