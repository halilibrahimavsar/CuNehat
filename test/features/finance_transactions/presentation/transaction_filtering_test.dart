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

    test('üst kategorinin adında da eşleşir (smoke T-36)', () {
      // "fatura" yazan kullanıcı Fatura altındaki Elektrik ve Su
      // kayıtlarını bekler; etiket haritası yalnız YAPRAK adı taşır.
      final rows = [
        _tx(
            id: 'e',
            title: 'Enerjisa',
            tag: 'c-elektrik',
            amount: 800,
            date: DateTime(2026, 8, 3)),
        _tx(
            id: 's',
            title: 'İSKİ',
            tag: 'c-su',
            amount: 200,
            date: DateTime(2026, 8, 3)),
        _tx(
            id: 'm',
            title: 'Migros',
            tag: 'c-market',
            amount: 650,
            date: DateTime(2026, 8, 4)),
      ];
      List<String> ids(String query) => applyTransactionFilters(
            transactions: rows,
            currentBalance: 0,
            filter: _filter(search: query),
            categoryLabels: const {
              'c-fatura': 'Fatura',
              'c-elektrik': 'Elektrik',
              'c-su': 'Su',
              'c-market': 'Market',
            },
            categoryRoots: const {
              'c-elektrik': 'c-fatura',
              'c-su': 'c-fatura',
              'c-market': 'c-market',
            },
          ).map((e) => e.transaction.id!).toList()
            ..sort();
      expect(ids('fatura'), ['e', 's']);
      expect(ids('elektr'), ['e']);
      expect(ids('market'), ['m']);
    });
  });

  group('ek filtreler', () {
    // Ağustos'a bir kart ödemesi (para taşıma), fişli bir market ve
    // ekstreden gelen bir satır eklenir.
    final extra = [
      ...transactions,
      TransactionEntity(
        id: 'm',
        userId: 'u1',
        walletId: 'w1',
        title: 'Kart ödemesi',
        tag: 'Transfer',
        amount: 2500,
        date: DateTime(2026, 8, 20),
        type: TransactionTypeModel.expense,
        isSystem: true,
      ),
      TransactionEntity(
        id: 'r',
        userId: 'u1',
        walletId: 'w1',
        title: 'Migros',
        tag: 'cat-market',
        amount: 90,
        date: DateTime(2026, 8, 21),
        type: TransactionTypeModel.expense,
        receiptFileName: 'r.jpg',
      ),
      TransactionEntity(
        id: 'i',
        userId: 'u1',
        walletId: 'w1',
        title: 'SOK',
        tag: 'cat-market',
        amount: 40,
        date: DateTime(2026, 8, 22),
        type: TransactionTypeModel.expense,
        importBatchId: 'batch-1',
      ),
    ];
    List<String> ids(DataFilter data) => applyTransactionFilters(
          transactions: extra,
          currentBalance: 1000,
          filter: _filter().copyWith(dataFilter: data),
          categoryLabels: labels,
        ).map((e) => e.transaction.id!).toSet().toList()
          ..sort();

    test('para taşıma varsayılan GÖRÜNÜR (defter olduğu gibi)', () {
      expect(ids(const DataFilter()), containsAll(['m', 'r', 'i']));
    });

    test('gizle: para taşıma düşer, gelir–gider kalır', () {
      final got = ids(const DataFilter(movedMoney: MovedMoneyFilter.hide));
      expect(got, isNot(contains('m')));
      expect(got, containsAll(['a', 'b', 'c']));
    });

    test('yalnız bunlar: yalnız para taşıma', () {
      expect(ids(const DataFilter(movedMoney: MovedMoneyFilter.only)), ['m']);
    });

    test('yalnız fişi olanlar', () {
      expect(ids(const DataFilter(onlyWithReceipt: true)), ['r']);
    });

    test('yalnız ekstreden: referans ya da içe aktarım kimliği KANIT', () {
      // 'd' (referanslı) dönem dışında; 'i' içe aktarım kimliğiyle.
      expect(ids(const DataFilter(onlyImported: true)), ['i']);
    });

    test('ek filtreler hasActiveFilters ve sayıda sayılır; temizlenir', () {
      const f = DataFilter(
          movedMoney: MovedMoneyFilter.hide,
          onlyWithReceipt: true,
          onlyImported: true);
      expect(f.hasActiveFilters, isTrue);
      expect(f.activeFilterCount, 3);
      expect(const DataFilter().hasActiveFilters, isFalse);
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
