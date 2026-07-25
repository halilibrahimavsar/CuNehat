// lib/features/recurring_transactions/data/datasources/recurring_transaction_local_datasource.dart

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../domain/services/recurring_occurrences.dart';
import '../models/recurring_transaction_model.dart';

abstract class RecurringTransactionLocalDataSource {
  Future<void> saveTemplate(RecurringTransactionModel template);
  Future<void> deleteTemplate(String id);
  Future<List<RecurringTransactionModel>> getAllTemplates();
  Future<List<RecurringTransactionModel>> getPendingTransactions();
}

@LazySingleton(as: RecurringTransactionLocalDataSource)
class RecurringTransactionLocalDataSourceImpl
    implements RecurringTransactionLocalDataSource {
  final String boxName = 'recurring_transactions_box';

  Box<RecurringTransactionModel> get _box =>
      Hive.box<RecurringTransactionModel>(boxName);

  @override
  Future<void> saveTemplate(RecurringTransactionModel template) async {
    await _box.put(template.id, template);
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _box.delete(id);
  }

  @override
  Future<List<RecurringTransactionModel>> getAllTemplates() async {
    return _box.values.toList();
  }

  @override
  Future<List<RecurringTransactionModel>> getPendingTransactions() async {
    final now = DateTime.now();
    // Kural [isRecurringDue]'da; takip sayfası da aynı tanımı kullanır.
    return _box.values
        .where((t) => isRecurringDue(
              isActive: t.isActive,
              nextExecutionDate: t.nextExecutionDate,
              now: now,
            ))
        .toList();
  }
}
