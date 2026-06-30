import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = TransactionReportService();

  TransactionEntity tx(
    DateTime date,
    double amount,
    TransactionTypeModel type, {
    String tag = 'cat',
  }) =>
      TransactionEntity(
        id: null,
        userId: 'u',
        walletId: 'w',
        title: 't',
        tag: tag,
        amount: amount,
        date: date,
        type: type,
      );

  group('TransactionReportService.filterByRange', () {
    test('boş liste boş liste döndürür', () {
      expect(
        service.filterByRange([], DateTime(2026, 6, 1), DateTime(2026, 6, 30)),
        isEmpty,
      );
    });

    test('başlangıç günü dahil (00:00 sınırı)', () {
      final result = service.filterByRange(
        [tx(DateTime(2026, 6, 1, 0, 0), 10, TransactionTypeModel.expense)],
        DateTime(2026, 6, 1, 23, 59),
        DateTime(2026, 6, 30),
      );
      expect(result, hasLength(1));
    });

    test('bitiş gününün gün-sonu mikrosaniyeli kaydı dahil kalır', () {
      final result = service.filterByRange(
        [
          tx(DateTime(2026, 6, 30, 23, 59, 59, 999, 500), 10,
              TransactionTypeModel.expense),
        ],
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30, 12), // bitiş saati önemsiz; gün baz alınır
      );
      expect(result, hasLength(1));
    });

    test('aralık dışı (başlangıçtan önce / bitişten sonraki gün) elenir', () {
      final result = service.filterByRange(
        [
          tx(DateTime(2026, 5, 31, 23, 59), 10, TransactionTypeModel.expense),
          tx(DateTime(2026, 7, 1, 0, 0), 20, TransactionTypeModel.expense),
        ],
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );
      expect(result, isEmpty);
    });
  });

  group('TransactionReportService.calculateTotals', () {
    test('boş liste sıfır toplam', () {
      final t = service.calculateTotals([]);
      expect(t.totalIncome, 0);
      expect(t.totalExpense, 0);
      expect(t.net, 0);
    });

    test('gelir + gider toplanır, net = gelir − gider', () {
      final t = service.calculateTotals([
        tx(DateTime(2026, 6, 1), 500, TransactionTypeModel.income),
        tx(DateTime(2026, 6, 2), 200, TransactionTypeModel.expense),
        tx(DateTime(2026, 6, 3), 100, TransactionTypeModel.expense),
      ]);
      expect(t.totalIncome, 500);
      expect(t.totalExpense, 300);
      expect(t.net, 200);
    });

    test('gider geliri aşınca net negatif', () {
      final t = service.calculateTotals([
        tx(DateTime(2026, 6, 1), 100, TransactionTypeModel.income),
        tx(DateTime(2026, 6, 2), 250, TransactionTypeModel.expense),
      ]);
      expect(t.net, -150);
    });
  });

  group('TransactionReportService.buildCategoryBreakdown', () {
    test('boş liste boş döndürür', () {
      expect(
        service.buildCategoryBreakdown([], isExpense: true),
        isEmpty,
      );
    });

    test('tag bazlı gruplar; her grup toplamı doğru', () {
      final result = service.buildCategoryBreakdown(
        [
          tx(DateTime(2026, 6, 1), 30, TransactionTypeModel.expense, tag: 'a'),
          tx(DateTime(2026, 6, 2), 20, TransactionTypeModel.expense, tag: 'a'),
          tx(DateTime(2026, 6, 3), 10, TransactionTypeModel.expense, tag: 'b'),
        ],
        isExpense: true,
      );

      expect(result, hasLength(2));
      final a = result.firstWhere((c) => c.name == 'a');
      expect(a.totalAmount, 50);
      expect(a.transactions, hasLength(2));
    });

    test('toplam tutara göre azalan sıralı', () {
      final result = service.buildCategoryBreakdown(
        [
          tx(DateTime(2026, 6, 1), 10, TransactionTypeModel.expense,
              tag: 'low'),
          tx(DateTime(2026, 6, 2), 90, TransactionTypeModel.expense,
              tag: 'high'),
          tx(DateTime(2026, 6, 3), 50, TransactionTypeModel.expense,
              tag: 'mid'),
        ],
        isExpense: true,
      );

      expect(result.map((c) => c.name).toList(), ['high', 'mid', 'low']);
    });

    test('isExpense filtresi gelir/gideri ayırır', () {
      final txns = [
        tx(DateTime(2026, 6, 1), 100, TransactionTypeModel.expense, tag: 'exp'),
        tx(DateTime(2026, 6, 2), 200, TransactionTypeModel.income, tag: 'inc'),
      ];

      final expenses = service.buildCategoryBreakdown(txns, isExpense: true);
      final incomes = service.buildCategoryBreakdown(txns, isExpense: false);

      expect(expenses.map((c) => c.name), ['exp']);
      expect(incomes.map((c) => c.name), ['inc']);
    });
  });

  // `double` toplama mikro sapma üretir (ör. 0.1+0.2 = 0.30000000000000004),
  // ama tolerans içinde kalır ve 2-hane gösterimde doğru yuvarlanır. Bu grup
  // finansal toplamların kullanıcıya doğru yansıdığını sabitler.
  group('calculateTotals — kayan-nokta sağlamlığı', () {
    test('ondalık gelir/gider toplamı tolerans içinde ve 2-hane gösterimde doğru',
        () {
      final t = service.calculateTotals([
        tx(DateTime(2026, 6, 1), 0.1, TransactionTypeModel.income),
        tx(DateTime(2026, 6, 1), 0.2, TransactionTypeModel.income),
        tx(DateTime(2026, 6, 1), 0.3, TransactionTypeModel.income),
        tx(DateTime(2026, 6, 2), 0.1, TransactionTypeModel.expense),
      ]);
      expect(t.totalIncome, closeTo(0.6, 1e-9));
      expect(t.totalExpense, closeTo(0.1, 1e-9));
      expect(t.net, closeTo(0.5, 1e-9));
      expect(t.net.toStringAsFixed(2), '0.50');
    });

    test('1000 kuruşluk gider toplamı 2-hane gösterimde sapmaz', () {
      final txns = List.generate(
        1000,
        (_) => tx(DateTime(2026, 6, 1), 0.01, TransactionTypeModel.expense),
      );
      final t = service.calculateTotals(txns);
      expect(t.totalExpense, closeTo(10.0, 1e-6)); // ham ~9.999999999999831
      expect(t.totalExpense.toStringAsFixed(2), '10.00');
    });

    test('kategori dağılımı ondalık toplamı tolerans içinde', () {
      final result = service.buildCategoryBreakdown(
        [
          tx(DateTime(2026, 6, 1), 0.1, TransactionTypeModel.expense, tag: 'a'),
          tx(DateTime(2026, 6, 2), 0.2, TransactionTypeModel.expense, tag: 'a'),
        ],
        isExpense: true,
      );
      expect(result.single.totalAmount, closeTo(0.3, 1e-9));
      expect(result.single.totalAmount.toStringAsFixed(2), '0.30');
    });
  });
}
