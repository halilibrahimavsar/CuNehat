import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/recent_categories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var seq = 0;
  TransactionEntity tx(
    String tag,
    DateTime date, {
    TransactionTypeModel type = TransactionTypeModel.expense,
    bool isSystem = false,
  }) =>
      TransactionEntity(
        id: 't${seq++}',
        userId: 'u',
        walletId: 'w',
        title: tag,
        tag: tag,
        amount: 10,
        date: date,
        type: type,
        isSystem: isSystem,
      );

  const valid = {'market', 'yemek', 'ulasim', 'fatura', 'kira', 'maas'};

  test('yeniden eskiye, yinelenenler tek', () {
    final recent = recentCategoryIds(
      [
        tx('market', DateTime(2026, 10, 1)),
        tx('yemek', DateTime(2026, 10, 5)),
        tx('market', DateTime(2026, 10, 7)),
        tx('ulasim', DateTime(2026, 10, 3)),
      ],
      isExpense: true,
      validIds: valid,
    );

    expect(recent, ['market', 'yemek', 'ulasim']);
  });

  test('sınır: en fazla [limit] kategori', () {
    final recent = recentCategoryIds(
      [
        for (final (i, tag)
            in ['market', 'yemek', 'ulasim', 'fatura', 'kira'].indexed)
          tx(tag, DateTime(2026, 10, 10 - i)),
      ],
      isExpense: true,
      validIds: valid,
    );

    expect(recent, ['market', 'yemek', 'ulasim', 'fatura']);
  });

  test('yalnız istenen tür sayılır', () {
    final recent = recentCategoryIds(
      [
        tx('maas', DateTime(2026, 10, 9), type: TransactionTypeModel.income),
        tx('market', DateTime(2026, 10, 1)),
      ],
      isExpense: true,
      validIds: valid,
    );

    expect(recent, ['market']);
  });

  test('sistem hareketinin etiketi kategori sayılmaz', () {
    final recent = recentCategoryIds(
      [
        tx('market', DateTime(2026, 10, 9), isSystem: true),
        tx('yemek', DateTime(2026, 10, 1)),
      ],
      isExpense: true,
      validIds: valid,
    );

    expect(recent, ['yemek']);
  });

  test('silinmiş ya da bu cüzdanda gizli kategori atlanır', () {
    final recent = recentCategoryIds(
      [
        tx('artik-yok', DateTime(2026, 10, 9)),
        tx('market', DateTime(2026, 10, 1)),
      ],
      isExpense: true,
      validIds: valid,
    );

    expect(recent, ['market']);
  });
}
