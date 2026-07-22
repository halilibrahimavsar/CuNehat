import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx(String title, String tag, {bool income = false}) =>
    TransactionEntity(
      id: title,
      userId: 'u',
      walletId: 'w',
      title: title,
      tag: tag,
      amount: 10,
      date: DateTime(2026, 1, 1),
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );

CategoryEntity _cat(String id, {bool expense = true}) =>
    CategoryEntity(id: id, iconName: 'x', isExpense: expense, sortOrder: 1);

void main() {
  final guesser = CategoryGuesser();

  group('guessFromHistory', () {
    test('geçmişte aynı marka nasıl kategorize edildiyse onu döner', () {
      final index = guesser.buildHistoryIndex([
        _tx('MIGROS KADIKOY', 'Market'),
        _tx('MIGROS BESIKTAS', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'MIGROS ATASEHIR',
        isIncome: false,
        index: index,
        candidates: [_cat('Market'), _cat('Yemek')],
      );
      expect(r, 'Market');
    });

    test('mağaza koduna tire ile bitişik marka da (SOK-10419) eşleşir', () {
      final index = guesser.buildHistoryIndex([
        _tx('SOK-11223-USKUDAR', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'SOK-99887-KADIKOY',
        isIncome: false,
        index: index,
        candidates: [_cat('Market')],
      );
      expect(r, 'Market'); // sayısal kod farklı ama 'sok' token'ı ortak
    });

    test('kategori artık listede yoksa (silinmiş) null döner', () {
      final index = guesser.buildHistoryIndex([_tx('MIGROS', 'Market')]);
      final r = guesser.guessFromHistory(
        description: 'MIGROS',
        isIncome: false,
        index: index,
        candidates: [_cat('Yemek')], // 'Market' yok
      );
      expect(r, isNull);
    });

    test('gelir/gider ayrı: gider geçmişi gelir tahminini etkilemez', () {
      final index = guesser.buildHistoryIndex([
        _tx('ACME LTD', 'Market'), // gider
      ]);
      final r = guesser.guessFromHistory(
        description: 'ACME LTD',
        isIncome: true, // gelir tarafı
        index: index,
        candidates: [_cat('Maaş', expense: false)],
      );
      expect(r, isNull);
    });

    test('jenerik/stopword token yanlış eşleşme yapmaz', () {
      final index = guesser.buildHistoryIndex([
        _tx('POS ODEME', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'POS ODEME',
        isIncome: false,
        index: index,
        candidates: [_cat('Market')],
      );
      expect(r, isNull); // 'pos'/'odeme' stopword → anlamlı token yok
    });

    test('en çok kullanılan kategori kazanır (frekans)', () {
      final index = guesser.buildHistoryIndex([
        _tx('AKARYAKIT SHELL', 'Ulaşım'),
        _tx('AKARYAKIT SHELL', 'Ulaşım'),
        _tx('AKARYAKIT MARKET', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'AKARYAKIT DEPO',
        isIncome: false,
        index: index,
        candidates: [_cat('Ulaşım'), _cat('Market')],
      );
      expect(r, 'Ulaşım'); // 'akaryakit' 2× Ulaşım, 1× Market
    });

    test('sistem işlemleri (isSystem) indekse girmez', () {
      final index = guesser.buildHistoryIndex([
        TransactionEntity(
          id: 't',
          userId: 'u',
          walletId: 'w',
          title: 'MIGROS TRANSFER',
          tag: 'Transfer',
          amount: 10,
          date: DateTime(2026, 1, 1),
          type: TransactionTypeModel.expense,
          isSystem: true,
        ),
      ]);
      expect(index.isEmpty, isTrue);
    });
  });
}
