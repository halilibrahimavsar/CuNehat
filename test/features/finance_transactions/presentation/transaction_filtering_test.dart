import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/transaction_filtering.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx({
  required String id,
  required String title,
  required String tag,
  required double amount,
  required DateTime date,
  bool expense = true,
  String? reference,
}) {
  return TransactionEntity(
    id: id,
    userId: 'u1',
    walletId: 'w1',
    title: title,
    tag: tag,
    amount: amount,
    date: date,
    type: expense ? TransactionTypeModel.expense : TransactionTypeModel.income,
    reference: reference,
  );
}

CombinedFilter _filter({
  FinanceMode mode = FinanceMode.compare,
  DateTime? start,
  DateTime? end,
  Set<String> categories = const {},
  PriceRangeFilter? priceRange,
  String? search,
}) {
  return CombinedFilter(
    viewFilter: ViewFilter(
      financeMode: mode,
      startDate: start ?? DateTime(2026, 8, 1),
      endDate: end ?? DateTime(2026, 8, 31, 23, 59, 59),
    ),
    dataFilter: DataFilter(
      selectedCategories: categories,
      priceRange: priceRange,
      searchQuery: search,
    ),
  );
}

void main() {
  final transactions = [
    _tx(
      id: 'a',
      title: 'ŞOK 4712',
      tag: 'cat-market',
      amount: 250,
      date: DateTime(2026, 8, 10),
    ),
    _tx(
      id: 'b',
      title: 'İnternet faturası',
      tag: 'cat-fatura',
      amount: 500,
      date: DateTime(2026, 8, 12),
    ),
    _tx(
      id: 'c',
      title: 'Maaş',
      tag: 'cat-maas',
      amount: 40000,
      date: DateTime(2026, 8, 1),
      expense: false,
    ),
    _tx(
      id: 'd',
      title: 'Temmuz kirası',
      tag: 'cat-kira',
      amount: 12000,
      date: DateTime(2026, 7, 5),
      reference: 'DK-99187',
    ),
  ];

  const labels = {
    'cat-market': 'Market',
    'cat-fatura': 'Fatura › İnternet',
    'cat-maas': 'Maaş',
    'cat-kira': 'Kira',
  };

  List<String> idsOf(CombinedFilter filter, {bool applyDateWindow = true}) {
    return applyTransactionFilters(
      transactions: transactions,
      currentBalance: 1000,
      filter: filter,
      categoryLabels: labels,
      applyDateWindow: applyDateWindow,
    ).map((e) => e.transaction.id!).toList();
  }

  group('tarih penceresi', () {
    test('aralık dışındaki işlem düşer', () {
      expect(idsOf(_filter()), ['b', 'a', 'c']);
    });

    test('applyDateWindow: false tüm geçmişi verir', () {
      expect(idsOf(_filter(), applyDateWindow: false), ['b', 'a', 'c', 'd']);
    });
  });

  group('mod', () {
    test('gider modu yalnız giderleri bırakır', () {
      expect(idsOf(_filter(mode: FinanceMode.expense)), ['b', 'a']);
    });

    test('gelir modu yalnız gelirleri bırakır', () {
      expect(idsOf(_filter(mode: FinanceMode.income)), ['c']);
    });
  });

  group('kategori', () {
    test('seçili kategori kümesi süzülür', () {
      expect(idsOf(_filter(categories: {'cat-market'})), ['a']);
    });

    test('boş küme hiçbir şeyi elemez', () {
      expect(idsOf(_filter(categories: const {})).length, 3);
    });
  });

  group('fiyat aralığı', () {
    test('alt sınır uygulanır', () {
      expect(
        idsOf(_filter(priceRange: const PriceRangeFilter(minPrice: 300))),
        ['b', 'c'],
      );
    });

    test('üst sınır uygulanır', () {
      expect(
        idsOf(_filter(priceRange: const PriceRangeFilter(maxPrice: 300))),
        ['a'],
      );
    });
  });

  group('arama', () {
    test('başlıkta eşleşir', () {
      expect(idsOf(_filter(search: 'şok')), ['a']);
    });

    test('kategori adında eşleşir (başlık tutmasa bile)', () {
      // "ŞOK 4712" başlığında "market" geçmiyor; kategori adı eşleşmeli.
      expect(idsOf(_filter(search: 'market')), ['a']);
    });

    test('Türkçe büyük İ ile aranan sözcük küçük harfli satırı bulur', () {
      // Düz toLowerCase() ile bu satır BULUNAMAZ ('İ' → 'i̇').
      expect(idsOf(_filter(search: 'İNTERNET')), ['b']);
    });

    test('dekont numarasında eşleşir', () {
      expect(
        idsOf(_filter(search: 'DK-99187'), applyDateWindow: false),
        ['d'],
      );
    });

    test('yalnız boşluktan oluşan sorgu hiçbir şeyi elemez', () {
      expect(idsOf(_filter(search: '   ')).length, 3);
    });

    test('tutar aranmaz — "250" başlıkta geçmiyorsa eşleşmez', () {
      expect(idsOf(_filter(search: '250')), isEmpty);
    });
  });

  group('birleşik', () {
    test('mod + kategori + arama birlikte uygulanır', () {
      final result = idsOf(_filter(
        mode: FinanceMode.expense,
        categories: {'cat-market', 'cat-fatura'},
        search: 'fatura',
      ));
      expect(result, ['b']);
    });
  });

  group('running balance', () {
    test('çapa TAM geçmiş üzerinde kurulur, pencere sonradan uygulanır', () {
      // En yeni işlem 12 Ağustos gideri (500). Güncel bakiye 1000 ise
      // ondan SONRAKİ bakiye 1000'dir; bir öncekinin sonrası 1000 + 500.
      final ledger = applyTransactionFilters(
        transactions: transactions,
        currentBalance: 1000,
        filter: _filter(),
        categoryLabels: labels,
      );
      expect(ledger.first.transaction.id, 'b');
      expect(ledger.first.balanceAfter, 1000);
      expect(ledger[1].balanceAfter, 1500);
    });
  });
}
