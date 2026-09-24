import 'package:cunehat/features/credit_card/domain/card_spending_merge.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _t(
  String id,
  String wallet, {
  double amount = 100,
  bool income = false,
  bool system = false,
  String? pair,
}) =>
    TransactionEntity(
      id: id,
      userId: 'u',
      walletId: wallet,
      title: id,
      tag: system ? 'Transfer' : 'market',
      amount: amount,
      date: DateTime(2026, 9, 10),
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
      isSystem: system,
      linkedRecordId: pair,
    );

void main() {
  test('kart HARCAMALARI katılır, kartın ödeme bacağı katılmaz', () {
    final merged = mergeCardSpending(
      account: [_t('maas', 'bank', income: true)],
      cards: [
        _t('market', 'card'),
        _t('odeme-in', 'card', income: true, system: true, pair: 'p1'),
      ],
    );
    expect(merged.map((t) => t.id), ['maas', 'market']);
  });

  test(
      'hesabın O KARTA ödeme bacağı çıkar (aynı para iki kez sayılmasın); '
      'başka cüzdana transfer kalır', () {
    final merged = mergeCardSpending(
      account: [
        _t('odeme-out', 'bank', system: true, pair: 'p1'),
        _t('nakite', 'bank', system: true, pair: 'p2'),
        _t('kira', 'bank'),
      ],
      cards: [
        _t('odeme-in', 'card', income: true, system: true, pair: 'p1'),
      ],
    );
    expect(merged.map((t) => t.id), ['nakite', 'kira']);
  });

  test('kart yoksa hesabın defteri aynen', () {
    final account = [_t('a', 'bank'), _t('b', 'bank', system: true, pair: 'x')];
    expect(mergeCardSpending(account: account, cards: const []), account);
  });
}
