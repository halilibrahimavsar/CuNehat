import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx({
  required double amount,
  required bool income,
  required DateTime date,
  String? id,
}) =>
    TransactionEntity(
      id: id ?? date.toIso8601String(),
      userId: 'u',
      walletId: 'w',
      title: 't',
      tag: 'g',
      amount: amount,
      date: date,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );

void main() {
  group('calculateRunningBalance', () {
    test('en yeni işlem güncel (final) bakiyeyi gösterir, geri çözülür', () {
      // newest -> oldest, current balance = 250 (opening 0)
      final txs = [
        _tx(amount: 200, income: true, date: DateTime(2026, 5, 10)),
        _tx(amount: 50, income: false, date: DateTime(2026, 5, 5)),
        _tx(amount: 100, income: true, date: DateTime(2026, 5, 1)),
      ];

      final result = calculateRunningBalance(txs, 250);

      expect(result[0].balanceAfter, 250); // en yeni gelir sonrası
      expect(result[1].balanceAfter, 50); // 250 - 200
      expect(result[2].balanceAfter, 100); // 50 + 50 (gideri geri al)
    });

    test('boş liste boş döner', () {
      expect(calculateRunningBalance(const [], 100), isEmpty);
    });

    test('tek gider işlemi en yeni satırda final bakiyeyi gösterir', () {
      final txs = [_tx(amount: 30, income: false, date: DateTime(2026, 1, 2))];
      final r = calculateRunningBalance(txs, 70);
      expect(r.single.balanceAfter, 70);
    });
  });

  group('buildLedgerView', () {
    // Mayıs + Haziran'a yayılmış geçmiş; güncel bakiye 250 (opening 0).
    final history = [
      _tx(amount: 200, income: true, date: DateTime(2026, 6, 10)),
      _tx(amount: 50, income: false, date: DateTime(2026, 5, 5)),
      _tx(amount: 100, income: true, date: DateTime(2026, 5, 1)),
    ];

    test('geçmiş aralık seçilince çapa tam geçmişe göre doğru kalır', () {
      // "Geçen Ay" (Mayıs): Haziran'daki +200 dışlanır ama balanceAfter
      // değerleri tam geçmişteki değerlerle birebir aynı olmalı.
      final full = buildLedgerView(
        allTransactions: history,
        currentBalance: 250,
      );
      final lastMonth = buildLedgerView(
        allTransactions: history,
        currentBalance: 250,
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 31),
      );

      expect(lastMonth.length, 2);
      expect(lastMonth[0].balanceAfter, full[1].balanceAfter); // 50
      expect(lastMonth[1].balanceAfter, full[2].balanceAfter); // 100
    });

    test('endDate gece yarısı (00:00) gelse de o günün işlemleri dahil', () {
      final txWithTime = [
        _tx(amount: 40, income: true, date: DateTime(2026, 6, 10, 14, 30)),
      ];
      final view = buildLedgerView(
        allTransactions: txWithTime,
        currentBalance: 40,
        start: DateTime(2026, 6, 4),
        end: DateTime(2026, 6, 10), // gün başı
      );
      expect(view.length, 1);
    });

    test('eş tarihte UUIDv7/id desc kararlı sıralama', () {
      final sameDay = [
        _tx(amount: 10, income: true, date: DateTime(2026, 6, 1), id: 'a'),
        _tx(amount: 20, income: true, date: DateTime(2026, 6, 1), id: 'b'),
      ];
      final view = buildLedgerView(
        allTransactions: sameDay,
        currentBalance: 30,
      );
      // id desc: 'b' (daha yeni) üstte ve güncel bakiyeyi gösterir.
      expect(view[0].transaction.id, 'b');
      expect(view[0].balanceAfter, 30);
      expect(view[1].transaction.id, 'a');
      expect(view[1].balanceAfter, 10);
    });

    test('tamamen dışlayan aralık boş döner', () {
      final view = buildLedgerView(
        allTransactions: history,
        currentBalance: 250,
        start: DateTime(2025, 1, 1),
        end: DateTime(2025, 12, 31),
      );
      expect(view, isEmpty);
    });

    test('aralıksız çağrı tüm geçmişi döndürür', () {
      final view = buildLedgerView(
        allTransactions: history,
        currentBalance: 250,
      );
      expect(view.length, 3);
      expect(view[0].balanceAfter, 250);
    });
  });
}
