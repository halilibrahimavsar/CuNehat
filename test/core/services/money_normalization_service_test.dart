import 'package:cunehat/core/services/money_normalization_service.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saf normalizer sözleşmesi: kirli → kuruşa yuvarlı YENİ örnek;
/// temiz → AYNI örnek (identical). İkinci koşu her zaman no-op.
void main() {
  const dirty = 314.55999999999995;

  WalletModel wallet({
    double balance = 100,
    double debt = 0,
    double credit = 0,
    double investment = 0,
    double? opening = 100,
  }) {
    return WalletModel(
      id: 'w',
      userId: 'u',
      name: 'Cüzdan',
      balance: balance,
      debt: debt,
      credit: credit,
      investment: investment,
      colorHex: '0xFF2196F3',
      iconName: 'wallet',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: opening,
    );
  }

  group('normalizeWalletMoney', () {
    test('kirli alanlar yuvarlanır, null opening KORUNUR', () {
      final n = normalizeWalletMoney(
          wallet(balance: dirty, debt: 0.1 + 0.2, opening: null));
      expect(n.balance, 314.56);
      expect(n.debt, 0.3);
      expect(n.openingBalance, isNull); // backfill tuzağı: null kalmalı
    });

    test('temiz kayıtta aynı örnek döner (idempotent, sıfır yazım)', () {
      final w = wallet();
      expect(identical(normalizeWalletMoney(w), w), true);
      final n = normalizeWalletMoney(wallet(balance: dirty));
      expect(identical(normalizeWalletMoney(n), n), true);
    });
  });

  group('normalizeDebtMoney', () {
    DebtModel debtModel({
      double principal = 300,
      double interest = 3.125,
      double overdue = 1.375,
      double? expected,
      List<Payment> payments = const [],
    }) {
      return DebtModel(
        id: 'd',
        userId: 'u',
        walletId: 'w',
        title: 'Kredi',
        counterparty: 'Banka',
        type: DebtType.bankLoan,
        principalAmount: principal,
        interestRate: interest,
        overdueInterestRate: overdue,
        termMonths: 12,
        startDate: DateTime(2026, 1, 1),
        payments: payments,
        expectedTotalAmount: expected,
      );
    }

    test('anapara/beklenen toplam/ödemeler yuvarlanır; ORANLAR dokunulmaz', () {
      final m = debtModel(
        principal: dirty,
        expected: 400.999999999999,
        payments: [PaymentModel(date: DateTime(2026, 2, 1), amount: 0.1 + 0.2)],
      );
      final n = normalizeDebtMoney(m);
      expect(n.principalAmount, 314.56);
      expect(n.expectedTotalAmount, 401.00);
      expect(n.payments.single.amount, 0.3);
      expect(n.interestRate, 3.125); // oran: hassas kalır
      expect(n.overdueInterestRate, 1.375);
    });

    test('null expectedTotalAmount null kalır; temizde aynı örnek', () {
      final m = debtModel(expected: null);
      final n = normalizeDebtMoney(m);
      expect(identical(n, m), true);
      expect(n.expectedTotalAmount, isNull);
    });
  });

  group('diğer modeller', () {
    test('transaction/receivable/budget/recurring tutarları yuvarlanır', () {
      final tx = normalizeTransactionMoney(TransactionModel(
        id: 't',
        userId: 'u',
        walletId: 'w',
        title: 'x',
        tag: 'y',
        amount: dirty,
        date: DateTime(2026, 1, 1),
        type: TransactionTypeModel.expense,
      ));
      expect(tx.amount, 314.56);

      final r = normalizeReceivableMoney(ReceivableModel(
        id: 'r',
        userId: 'u',
        walletId: 'w',
        debtorName: 'Ali',
        amount: 0.1 + 0.2,
        dueDate: DateTime(2026, 3, 1),
      ));
      expect(r.amount, 0.3);

      final b = normalizeBudgetMoney(
          BudgetModel(categoryId: 'c', limitAmount: dirty));
      expect(b.limitAmount, 314.56);

      final rec = normalizeRecurringMoney(RecurringTransactionModel(
        id: 'rt',
        userId: 'u',
        walletId: 'w',
        title: 'Kira',
        tag: 'ev',
        amount: dirty,
        type: TransactionTypeModel.expense,
        frequency: RecurringFrequency.monthly,
        nextExecutionDate: DateTime(2026, 2, 1),
      ));
      expect(rec.amount, 314.56);
    });

    test('investment: para alanları yuvarlanır, quantity/returnRate ASLA', () {
      final m = InvestmentModel(
        id: 'i',
        userId: 'u',
        walletId: 'w',
        name: 'Altın',
        amount: dirty,
        currentValue: 0.1 + 0.2,
        type: InvestmentType.gold,
        color: const Color(0xFF000000),
        dateAdded: DateTime(2026, 1, 1),
        quantity: 0.123456, // gram — hassas kalmalı
        returnRate: 12.3456789,
        targetAmount: 999.999999999,
      );
      final n = normalizeInvestmentMoney(m);
      expect(n.amount, 314.56);
      expect(n.currentValue, 0.3);
      expect(n.targetAmount, 1000.0);
      expect(n.quantity, 0.123456);
      expect(n.returnRate, 12.3456789);

      // Temiz sonuç ikinci geçişte aynı örnek.
      expect(identical(normalizeInvestmentMoney(n), n), true);
    });
  });
}
