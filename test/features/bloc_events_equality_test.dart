import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/presentation/bloc/budgets_event.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletEvent', () {
    final wallet = WalletEntity(
      id: 'w1',
      userId: 'u1',
      name: 'W1',
      balance: 100,
      debt: 0.0,
      credit: 0.0,
      investment: 0.0,
      colorHex: '#123456',
      iconName: 'wallet',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 100,
    );

    test('GetWalletsEvent props', () {
      const e1 = GetWalletsEvent('u1');
      const e2 = GetWalletsEvent('u1');
      expect(e1, e2);
      expect(e1.props, ['u1']);
    });

    test('WatchWalletsEvent props', () {
      const e1 = WatchWalletsEvent('u1');
      const e2 = WatchWalletsEvent('u1');
      expect(e1, e2);
      expect(e1.props, ['u1']);
    });

    test('CreateWalletEvent props', () {
      final e1 = CreateWalletEvent(wallet);
      final e2 = CreateWalletEvent(wallet);
      expect(e1, e2);
      expect(e1.props, [wallet]);
    });

    test('UpdateWalletEvent props', () {
      final e1 = UpdateWalletEvent(wallet);
      final e2 = UpdateWalletEvent(wallet);
      expect(e1, e2);
      expect(e1.props, [wallet]);
    });

    test('DeleteWalletEvent props', () {
      const e1 = DeleteWalletEvent('w1');
      const e2 = DeleteWalletEvent('w1');
      expect(e1, e2);
      expect(e1.props, ['w1']);
    });

    test('SetActiveWalletEvent props', () {
      const e1 = SetActiveWalletEvent(userId: 'u1', walletId: 'w1');
      const e2 = SetActiveWalletEvent(userId: 'u1', walletId: 'w1');
      expect(e1, e2);
      expect(e1.props, ['u1', 'w1']);
    });
  });

  group('DebtEvent', () {
    final debt = DebtEntity(
      id: 'd1',
      userId: 'u1',
      walletId: 'w1',
      title: 'Araba Kredisi',
      counterparty: 'Ziraat Bankası',
      type: DebtType.bankLoan,
      principalAmount: 1000,
      interestRate: 0,
      termMonths: 12,
      startDate: DateTime(2026, 1, 1),
      dueDate: DateTime(2026, 12, 31),
      isPaid: false,
      payments: const [],
    );

    test('GetDebtsEvent props', () {
      const e1 = GetDebtsEvent('w1');
      const e2 = GetDebtsEvent('w1');
      expect(e1, e2);
      expect(e1.props, ['w1']);
    });

    test('AddDebtEvent props', () {
      final e1 = AddDebtEvent(debt);
      final e2 = AddDebtEvent(debt);
      expect(e1, e2);
      expect(e1.props, [debt]);
    });

    test('UpdateDebtEvent props', () {
      final e1 = UpdateDebtEvent(debt, prevPrincipal: 1000.0);
      final e2 = UpdateDebtEvent(debt, prevPrincipal: 1000.0);
      expect(e1, e2);
      expect(e1.props, [debt, 1000.0]);
    });

    test('PayDebtEvent props', () {
      final e1 = PayDebtEvent(debt, 500.0);
      final e2 = PayDebtEvent(debt, 500.0);
      expect(e1, e2);
      expect(e1.props, [debt, 500.0]);
    });

    test('DeleteDebtEvent props', () {
      const e1 = DeleteDebtEvent(
        id: 'd1',
        userId: 'u1',
        walletId: 'w1',
        principalAmount: 1000.0,
        totalPaidAmount: 0.0,
      );
      const e2 = DeleteDebtEvent(
        id: 'd1',
        userId: 'u1',
        walletId: 'w1',
        principalAmount: 1000.0,
        totalPaidAmount: 0.0,
      );
      expect(e1, e2);
      expect(e1.props, ['d1', 'w1']);
    });
  });

  group('ReceivableEvent', () {
    final receivable = ReceivableEntity(
      id: 'r1',
      userId: 'u1',
      walletId: 'w1',
      debtorName: 'Debtor 1',
      amount: 1000,
      dueDate: DateTime(2026, 12, 31),
      isPaid: false,
    );

    test('GetReceivablesEvent props', () {
      const e1 = GetReceivablesEvent('w1');
      const e2 = GetReceivablesEvent('w1');
      expect(e1, e2);
      expect(e1.props, ['w1']);
    });

    test('AddReceivableEvent props', () {
      final e1 = AddReceivableEvent(receivable);
      final e2 = AddReceivableEvent(receivable);
      expect(e1, e2);
      expect(e1.props, [receivable]);
    });

    test('UpdateReceivableEvent props', () {
      final e1 =
          UpdateReceivableEvent(receivable: receivable, prevAmount: 1000.0);
      final e2 =
          UpdateReceivableEvent(receivable: receivable, prevAmount: 1000.0);
      expect(e1, e2);
      expect(e1.props, [receivable, 1000.0]);
    });

    test('DeleteReceivableEvent props', () {
      const e1 = DeleteReceivableEvent(
        id: 'r1',
        userId: 'u1',
        walletId: 'w1',
        amount: 1000.0,
        isPaid: false,
      );
      const e2 = DeleteReceivableEvent(
        id: 'r1',
        userId: 'u1',
        walletId: 'w1',
        amount: 1000.0,
        isPaid: false,
      );
      expect(e1, e2);
      expect(e1.props, ['r1', 'u1', 'w1', 1000.0, false]);
    });

    test('MarkReceivableAsPaidEvent props', () {
      final e1 = MarkReceivableAsPaidEvent(receivable);
      final e2 = MarkReceivableAsPaidEvent(receivable);
      expect(e1, e2);
      expect(e1.props, [receivable]);
    });
  });

  group('BudgetsEvent', () {
    final budget = BudgetEntity(
      categoryId: 'Market',
      limitAmount: 5000,
      spentAmount: 1000,
    );

    test('LoadBudgetsEvent props', () {
      const e1 = LoadBudgetsEvent(userId: 'u1', walletId: 'w1');
      const e2 = LoadBudgetsEvent(userId: 'u1', walletId: 'w1');
      expect(e1, e2);
      expect(e1.props, ['u1', 'w1']);
    });

    test('SaveBudgetEvent props', () {
      final e1 = SaveBudgetEvent(budget);
      final e2 = SaveBudgetEvent(budget);
      expect(e1, e2);
      expect(e1.props, [budget]);
    });

    test('DeleteBudgetEvent props', () {
      const e1 = DeleteBudgetEvent('Market');
      const e2 = DeleteBudgetEvent('Market');
      expect(e1, e2);
      expect(e1.props, ['Market']);
    });
  });

  group('PendingRecurringEvent', () {
    final template = RecurringTransactionEntity(
      id: 'rt1',
      userId: 'u1',
      walletId: 'w1',
      title: 'Salary',
      tag: 'Salary',
      amount: 10000,
      type: TransactionTypeModel.income,
      frequency: RecurringFrequency.monthly,
      nextExecutionDate: DateTime(2026, 2, 1),
    );

    test('LoadPendingTransactionsEvent props', () {
      const e = LoadPendingTransactionsEvent();
      expect(e.props, <Object>[false]);
      // suppressNudge farkı eşitliği bozmalı: bildirimden gelen yükleme,
      // normal yüklemeyle aynı sayılıp yutulmamalı.
      expect(e, isNot(const LoadPendingTransactionsEvent(suppressNudge: true)));
    });

    test('ApproveAllOccurrencesEvent props', () {
      final e1 = ApproveAllOccurrencesEvent(template);
      final e2 = ApproveAllOccurrencesEvent(template);
      expect(e1, e2);
      expect(e1.props, [template]);
    });

    test('ApproveTransactionEvent props', () {
      final e1 = ApproveTransactionEvent(template, overrideAmount: 11000);
      final e2 = ApproveTransactionEvent(template, overrideAmount: 11000);
      expect(e1, e2);
      expect(e1.props, [template, 11000.0]);
    });

    test('SkipTransactionEvent props', () {
      final e1 = SkipTransactionEvent(template);
      final e2 = SkipTransactionEvent(template);
      expect(e1, e2);
      expect(e1.props, [template]);
    });

    test('DeleteTransactionEvent props', () {
      const e1 = DeleteTransactionEvent('rt1');
      const e2 = DeleteTransactionEvent('rt1');
      expect(e1, e2);
      expect(e1.props, ['rt1']);
    });
  });

  group('InvestmentEvent', () {
    final investment = InvestmentEntity(
      id: 'i1',
      userId: 'u1',
      walletId: 'w1',
      name: 'Gold',
      amount: 5000,
      currentValue: 5500,
      type: InvestmentType.gold,
      color: Colors.yellow,
      dateAdded: DateTime(2026, 1, 1),
    );

    test('GetInvestmentsEvent props', () {
      const e1 = GetInvestmentsEvent(userId: 'u1', walletId: 'w1');
      const e2 = GetInvestmentsEvent(userId: 'u1', walletId: 'w1');
      expect(e1, e2);
      expect(e1.props, ['u1', 'w1']);
    });

    test('CreateInvestmentEvent props', () {
      final e1 = CreateInvestmentEvent(
          investment: investment, userId: 'u1', walletId: 'w1');
      final e2 = CreateInvestmentEvent(
          investment: investment, userId: 'u1', walletId: 'w1');
      expect(e1, e2);
      expect(e1.props, [investment, 'u1', 'w1']);
    });

    test('UpdateInvestmentEvent props', () {
      final e1 = UpdateInvestmentEvent(
        investment: investment,
        userId: 'u1',
        walletId: 'w1',
        prevAmount: 5000,
        newAmount: 5500,
      );
      final e2 = UpdateInvestmentEvent(
        investment: investment,
        userId: 'u1',
        walletId: 'w1',
        prevAmount: 5000,
        newAmount: 5500,
      );
      expect(e1, e2);
      expect(e1.props, [investment, 'u1', 'w1']);
    });

    test('RefreshPricesEvent props', () {
      const e1 =
          RefreshPricesEvent(userId: 'u1', walletId: 'w1', investmentId: 'i1');
      const e2 =
          RefreshPricesEvent(userId: 'u1', walletId: 'w1', investmentId: 'i1');
      expect(e1, e2);
      expect(e1.props, ['u1', 'w1', 'i1']);
    });

    test('DeleteInvestmentEvent props', () {
      const e1 = DeleteInvestmentEvent(
        id: 'i1',
        userId: 'u1',
        walletId: 'w1',
        amount: 5000,
        currentValue: 5500,
        recordSale: true,
      );
      const e2 = DeleteInvestmentEvent(
        id: 'i1',
        userId: 'u1',
        walletId: 'w1',
        amount: 5000,
        currentValue: 5500,
        recordSale: true,
      );
      expect(e1, e2);
      expect(e1.props, ['i1', 'u1', 'w1', true]);
    });
  });

  group('ThemeEvent', () {
    test('instantiates ThemeChangeEvent and ThemeLoadEvent', () {
      final t1 = ThemeData.light();
      final t2 = ThemeData.dark();
      final e1 = ThemeChangeEvent(themeName: t1);
      final e2 = ThemeLoadEvent(themeName: t2);
      expect(e1.themeName, t1);
      expect(e2.themeName, t2);
    });
  });
}
