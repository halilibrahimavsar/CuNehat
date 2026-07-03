import 'dart:convert';

import 'package:cunehat/features/budgets/data/models/budget_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/category_service.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DataRestoreStatus {
  success,
  invalidFormat,
  writeFailure,
}

class DataRestoreResult {
  final DataRestoreStatus status;
  final Object? error;

  const DataRestoreResult._(this.status, [this.error]);

  const DataRestoreResult.success() : this._(DataRestoreStatus.success);
  const DataRestoreResult.invalidFormat([Object? error])
      : this._(DataRestoreStatus.invalidFormat, error);
  const DataRestoreResult.writeFailure([Object? error])
      : this._(DataRestoreStatus.writeFailure, error);

  bool get isSuccess => status == DataRestoreStatus.success;
}

class _ParsedBackup {
  final List<WalletModel> wallets;
  final List<TransactionModel> transactions;
  final List<InvestmentModel> investments;
  final List<DebtModel> debts;
  final List<ReceivableModel> receivables;
  final List<BudgetModel> budgets;
  final List<RecurringTransactionModel> recurringTransactions;
  final Map<String, Map> users;
  final Map<String, String> categories;

  const _ParsedBackup({
    required this.wallets,
    required this.transactions,
    required this.investments,
    required this.debts,
    required this.receivables,
    required this.budgets,
    required this.recurringTransactions,
    required this.users,
    required this.categories,
  });
}

@lazySingleton
class DataSerializationService {
  /// v4: cüzdanlara opsiyonel 'currency' anahtarı eklendi (yoksa TRY).
  /// Restore sürüm kapısı içermez; eski yedekler varsayılanlarla açılır.
  static const int schemaVersion = 4;

  final HiveInterface _hive;

  DataSerializationService() : _hive = Hive;

  @visibleForTesting
  DataSerializationService.withHive(this._hive);

  /// Tüm yerel veriyi siler: tüm Hive kutuları (cüzdan/işlem/yatırım/borç/
  /// alacak/bütçe/tekrarlayan/kullanıcı) + yedeklenebilir kategori tercihleri.
  /// "Tüm veriyi sil" gizlilik özelliği içindir. GERİ ALINAMAZ; çağıran onay
  /// almalıdır. Boş yedeği geri yüklemekle aynı temizleme yolunu kullanır.
  Future<void> clearAllLocalData() async {
    await (await _hive.openBox<WalletModel>('wallets')).clear();
    await (await _hive.openBox<TransactionModel>('transactions')).clear();
    await (await _hive.openBox<InvestmentModel>('investments_box')).clear();
    await (await _hive.openBox<DebtModel>('debts')).clear();
    await (await _hive.openBox<ReceivableModel>('receivables')).clear();
    await (await _hive.openBox<BudgetModel>('budgets_box')).clear();
    await (await _hive
            .openBox<RecurringTransactionModel>('recurring_transactions_box'))
        .clear();
    await (await _hive.openBox<Map>('users')).clear();

    final prefs = await SharedPreferences.getInstance();
    for (final key in CategoryService.backupKeys) {
      await prefs.remove(key);
    }
  }

  Future<String> exportDataToJson() async {
    final walletBox = await _hive.openBox<WalletModel>('wallets');
    final transactionBox =
        await _hive.openBox<TransactionModel>('transactions');
    final investmentBox =
        await _hive.openBox<InvestmentModel>('investments_box');
    final debtBox = await _hive.openBox<DebtModel>('debts');
    final receivableBox = await _hive.openBox<ReceivableModel>('receivables');
    final budgetBox = await _hive.openBox<BudgetModel>('budgets_box');
    final recurringBox = await _hive
        .openBox<RecurringTransactionModel>('recurring_transactions_box');
    final userBox = await _hive.openBox<Map>('users');

    final users = <String, Map>{};
    for (final key in userBox.keys) {
      final value = userBox.get(key);
      if (value != null) {
        users[key.toString()] = Map<String, dynamic>.from(value);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final categories = <String, String>{
      for (final key in CategoryService.backupKeys)
        if (prefs.getString(key) != null) key: prefs.getString(key)!,
    };

    return jsonEncode({
      'version': schemaVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'wallets': walletBox.values.map((w) => w.toJson()).toList(),
      'transactions': transactionBox.values.map((t) => t.toJson()).toList(),
      'investments': investmentBox.values.map((i) => i.toJson()).toList(),
      'debts': debtBox.values.map((d) => d.toJson()).toList(),
      'receivables': receivableBox.values.map((r) => r.toJson()).toList(),
      'budgets': budgetBox.values.map((b) => b.toJson()).toList(),
      'recurringTransactions':
          recurringBox.values.map((r) => r.toJson()).toList(),
      'users': users,
      'categories': categories,
    });
  }

  Future<DataRestoreResult> importDataFromJson(String jsonString) async {
    final _ParsedBackup parsedBackup;
    try {
      parsedBackup = _parseBackup(jsonString);
    } catch (e, st) {
      debugPrint('DataSerializationService parse error: $e\n$st');
      return DataRestoreResult.invalidFormat(e);
    }

    final walletBox = await _hive.openBox<WalletModel>('wallets');
    final transactionBox =
        await _hive.openBox<TransactionModel>('transactions');
    final investmentBox =
        await _hive.openBox<InvestmentModel>('investments_box');
    final debtBox = await _hive.openBox<DebtModel>('debts');
    final receivableBox = await _hive.openBox<ReceivableModel>('receivables');
    final budgetBox = await _hive.openBox<BudgetModel>('budgets_box');
    final recurringBox = await _hive
        .openBox<RecurringTransactionModel>('recurring_transactions_box');
    final userBox = await _hive.openBox<Map>('users');

    final prefs = await SharedPreferences.getInstance();
    final categorySnapshot = <String, String?>{
      for (final key in CategoryService.backupKeys) key: prefs.getString(key),
    };

    final walletSnapshot = Map.of(walletBox.toMap());
    final transactionSnapshot = Map.of(transactionBox.toMap());
    final investmentSnapshot = Map.of(investmentBox.toMap());
    final debtSnapshot = Map.of(debtBox.toMap());
    final receivableSnapshot = Map.of(receivableBox.toMap());
    final budgetSnapshot = Map.of(budgetBox.toMap());
    final recurringSnapshot = Map.of(recurringBox.toMap());
    final userSnapshot = Map.of(userBox.toMap());

    try {
      await walletBox.clear();
      await transactionBox.clear();
      await investmentBox.clear();
      await debtBox.clear();
      await receivableBox.clear();
      await budgetBox.clear();
      await recurringBox.clear();
      await userBox.clear();

      for (final model in parsedBackup.wallets) {
        final id = model.id;
        if (id == null) throw StateError('Wallet id is missing');
        await walletBox.put(id, model);
      }
      for (final model in parsedBackup.transactions) {
        final id = model.id;
        if (id == null) throw StateError('Transaction id is missing');
        await transactionBox.put(id, model);
      }
      for (final model in parsedBackup.investments) {
        final id = model.id;
        if (id == null) throw StateError('Investment id is missing');
        await investmentBox.put(id, model);
      }
      for (final model in parsedBackup.debts) {
        final id = model.id;
        if (id == null) throw StateError('Debt id is missing');
        await debtBox.put(id, model);
      }
      for (final model in parsedBackup.receivables) {
        final id = model.id;
        if (id == null) throw StateError('Receivable id is missing');
        await receivableBox.put(id, model);
      }
      for (final model in parsedBackup.budgets) {
        await budgetBox.put(model.categoryId, model);
      }
      for (final model in parsedBackup.recurringTransactions) {
        await recurringBox.put(model.id, model);
      }
      for (final entry in parsedBackup.users.entries) {
        await userBox.put(entry.key, entry.value);
      }

      for (final key in CategoryService.backupKeys) {
        final value = parsedBackup.categories[key];
        if (value != null) {
          await prefs.setString(key, value);
        } else {
          await prefs.remove(key);
        }
      }

      return const DataRestoreResult.success();
    } catch (e, st) {
      debugPrint('DataSerializationService write error: $e\n$st');
      try {
        await _rollback(walletBox, walletSnapshot);
        await _rollback(transactionBox, transactionSnapshot);
        await _rollback(investmentBox, investmentSnapshot);
        await _rollback(debtBox, debtSnapshot);
        await _rollback(receivableBox, receivableSnapshot);
        await _rollback(budgetBox, budgetSnapshot);
        await _rollback(recurringBox, recurringSnapshot);
        await _rollback(userBox, userSnapshot);
        for (final entry in categorySnapshot.entries) {
          if (entry.value != null) {
            await prefs.setString(entry.key, entry.value!);
          } else {
            await prefs.remove(entry.key);
          }
        }
      } catch (rollbackError, rollbackSt) {
        debugPrint(
          'DataSerializationService rollback FAILED: '
          '$rollbackError\n$rollbackSt',
        );
      }
      return DataRestoreResult.writeFailure(e);
    }
  }

  _ParsedBackup _parseBackup(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup root must be a JSON object');
    }

    final users = <String, Map>{};
    final usersMap = decoded['users'] as Map<String, dynamic>? ?? {};
    for (final entry in usersMap.entries) {
      users[entry.key] = Map<dynamic, dynamic>.from(entry.value as Map);
    }

    final categories = <String, String>{};
    final categoriesMap = decoded['categories'] as Map<String, dynamic>? ?? {};
    for (final entry in categoriesMap.entries) {
      if (entry.value is String) {
        categories[entry.key] = entry.value as String;
      }
    }

    return _ParsedBackup(
      wallets: _list(decoded, 'wallets').map((w) {
        final data = Map<String, dynamic>.from(w as Map);
        return WalletModel.fromJson(data['id'] as String, data);
      }).toList(),
      transactions: _list(decoded, 'transactions').map((t) {
        final data = Map<String, dynamic>.from(t as Map);
        return TransactionModel.fromJson(data['id'] as String, data);
      }).toList(),
      investments: _list(decoded, 'investments').map((i) {
        final data = Map<String, dynamic>.from(i as Map);
        return InvestmentModel.fromJson(data['id'] as String, data);
      }).toList(),
      debts: _list(decoded, 'debts')
          .map((d) => DebtModel.fromJson(Map<String, dynamic>.from(d as Map)))
          .toList(),
      receivables: _list(decoded, 'receivables')
          .map((r) =>
              ReceivableModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(),
      budgets: _list(decoded, 'budgets')
          .map((b) => BudgetModel.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList(),
      recurringTransactions: _list(decoded, 'recurringTransactions')
          .map((r) => RecurringTransactionModel.fromJson(
              Map<String, dynamic>.from(r as Map)))
          .toList(),
      users: users,
      categories: categories,
    );
  }

  List<dynamic> _list(Map<String, dynamic> data, String key) {
    return data[key] as List<dynamic>? ?? const [];
  }

  Future<void> _rollback(Box box, Map snapshot) async {
    await box.clear();
    await box.putAll(snapshot);
  }
}
