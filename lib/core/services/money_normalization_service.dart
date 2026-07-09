import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

/// Saf normalizasyon fonksiyonları: para alanlarını kuruşa yuvarlar.
/// Kayıt zaten temizse AYNI örnek döner (identical), yazma kararı buna bakar;
/// ikinci koşu böylece sıfır yazım üretir (idempotent).
///
/// Yuvarlanmayanlar: yatırım adedi (quantity), getiri (returnRate) ve tüm
/// faiz ORANLARI (interestRate/overdueInterestRate) — bunlar para değil.
/// `openingBalance`/`expectedTotalAmount` null ise null KALIR (null-opening
/// backfill'i ve "hesaplanan toplam" semantiği bozulmasın).

WalletModel normalizeWalletMoney(WalletModel m) {
  final balance = roundToCents(m.balance);
  final debt = roundToCents(m.debt);
  final credit = roundToCents(m.credit);
  final investment = roundToCents(m.investment);
  final opening =
      m.openingBalance == null ? null : roundToCents(m.openingBalance!);
  if (balance == m.balance &&
      debt == m.debt &&
      credit == m.credit &&
      investment == m.investment &&
      opening == m.openingBalance) {
    return m;
  }
  return m.copyWith(
    balance: balance,
    debt: debt,
    credit: credit,
    investment: investment,
    // copyWith null'u "koru" sayar; opening null ise zaten null kalır.
    openingBalance: opening,
  );
}

TransactionModel normalizeTransactionMoney(TransactionModel m) {
  final amount = roundToCents(m.amount);
  return amount == m.amount ? m : m.copyWith(amount: amount);
}

DebtModel normalizeDebtMoney(DebtModel m) {
  final principal = roundToCents(m.principalAmount);
  final expected = m.expectedTotalAmount == null
      ? null
      : roundToCents(m.expectedTotalAmount!);

  var paymentsChanged = false;
  final payments = <Payment>[];
  for (final p in m.payments) {
    final rounded = roundToCents(p.amount);
    if (rounded == p.amount) {
      payments.add(p);
    } else {
      paymentsChanged = true;
      payments.add(PaymentModel(date: p.date, amount: rounded, notes: p.notes));
    }
  }

  if (principal == m.principalAmount &&
      expected == m.expectedTotalAmount &&
      !paymentsChanged) {
    return m;
  }
  return m.copyWith(
    principalAmount: principal,
    expectedTotalAmount: expected,
    payments: paymentsChanged ? payments : m.payments,
  );
}

ReceivableModel normalizeReceivableMoney(ReceivableModel m) {
  final amount = roundToCents(m.amount);
  return amount == m.amount ? m : m.copyWith(amount: amount);
}

InvestmentModel normalizeInvestmentMoney(InvestmentModel m) {
  final amount = roundToCents(m.amount);
  final currentValue = roundToCents(m.currentValue);
  final target = m.targetAmount == null ? null : roundToCents(m.targetAmount!);
  if (amount == m.amount &&
      currentValue == m.currentValue &&
      target == m.targetAmount) {
    return m;
  }
  return m.copyWith(
    amount: amount,
    currentValue: currentValue,
    targetAmount: target,
  );
}

BudgetModel normalizeBudgetMoney(BudgetModel m) {
  final limit = roundToCents(m.limitAmount);
  return limit == m.limitAmount
      ? m
      : BudgetModel(categoryId: m.categoryId, limitAmount: limit);
}

RecurringTransactionModel normalizeRecurringMoney(RecurringTransactionModel m) {
  final amount = roundToCents(m.amount);
  if (amount == m.amount) return m;
  return RecurringTransactionModel(
    id: m.id,
    userId: m.userId,
    walletId: m.walletId,
    title: m.title,
    tag: m.tag,
    amount: amount,
    type: m.type,
    frequency: m.frequency,
    nextExecutionDate: m.nextExecutionDate,
    isActive: m.isActive,
  );
}

/// Açılışta koşan tek seferlik (her koşuda idempotent) para normalizasyonu:
/// geçmişte yuvarlanmadan yazılmış tutarları kuruşa çeker. Yeni yazım yolları
/// zaten `parseMoney`/`roundToCents`'ten geçtiğinden bu servis eski veriyi
/// onarır; ikinci koşuda sıfır yazım yapar. Hata asla açılışı bloklamaz.
@lazySingleton
class MoneyNormalizationService {
  final WalletMetricsService walletMetricsService;

  MoneyNormalizationService(this.walletMetricsService);

  Future<void> run() async {
    try {
      // Bakiye defterini etkileyen değişimlerde (cüzdan alanı ya da işlem
      // tutarı) invariant'ı hemen yeniden kur: balance = opening + Σtx.
      final touchedWallets = <String>{};

      await _normalizeBox<WalletModel>('wallets', normalizeWalletMoney,
          onChanged: (m) {
        if (m.id != null) touchedWallets.add(m.id!);
      });
      await _normalizeBox<TransactionModel>(
          'transactions', normalizeTransactionMoney,
          onChanged: (m) => touchedWallets.add(m.walletId));
      await _normalizeBox<DebtModel>('debts', normalizeDebtMoney);
      await _normalizeBox<ReceivableModel>(
          'receivables', normalizeReceivableMoney);
      await _normalizeBox<InvestmentModel>(
          'investments_box', normalizeInvestmentMoney);
      await _normalizeBox<BudgetModel>('budgets_box', normalizeBudgetMoney);
      await _normalizeBox<RecurringTransactionModel>(
          'recurring_transactions_box', normalizeRecurringMoney);

      for (final walletId in touchedWallets) {
        await walletMetricsService.syncBalance(walletId);
      }
    } catch (e, st) {
      debugPrint(
          'MoneyNormalizationService başarısız (açılış engellenmedi): $e\n$st');
    }
  }

  Future<void> _normalizeBox<T>(
    String boxName,
    T Function(T) normalize, {
    void Function(T normalized)? onChanged,
  }) async {
    final box = await _box<T>(boxName);
    for (final key in box.keys.toList()) {
      final model = box.get(key);
      if (model == null) continue;
      final normalized = normalize(model);
      if (identical(normalized, model)) continue;
      await box.put(key, normalized);
      onChanged?.call(normalized);
      debugPrint('MoneyNormalization: $boxName[$key] kuruşa yuvarlandı');
    }
  }

  Future<Box<T>> _box<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return Hive.openBox<T>(name);
  }
}
