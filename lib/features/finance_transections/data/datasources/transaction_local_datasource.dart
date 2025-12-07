// ==========================================
// TRANSACTION DATA SOURCES
// ==========================================

// ==========================================
// HIVE IMPLEMENTATION
// ==========================================

// lib/features/transaction/data/datasources/transaction_hive_datasource.dart
import 'package:cunehat/features/finance_transections/data/datasources/transection_data_source.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cunehat/core/error/exceptions.dart';
import '../models/transaction_model.dart';

class TransactionHiveDataSource implements TransactionDataSource {
  static const String _boxName = 'transactions';

  Future<Box<TransactionModel>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<TransactionModel>(_boxName);
    }
    return Hive.box<TransactionModel>(_boxName);
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  }) async {
    try {
      final box = await _getBox();
      var transactions = box.values.where((t) {
        // Filter by userId and walletId
        if (t.userId != userId || t.walletId != walletId) {
          return false;
        }

        // Filter by type
        if (type != null && t.type != type) {
          return false;
        }

        // Filter by date range
        if (startDate != null && t.date.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && t.date.isAfter(endDate)) {
          return false;
        }

        return true;
      }).toList();

      // Sort by date descending
      transactions.sort((a, b) => b.date.compareTo(a.date));

      return transactions;
    } catch (e) {
      throw CacheException('İşlemler alınırken hata oluştu', e);
    }
  }

  @override
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final box = await _getBox();
      final transaction = box.get(id);

      if (transaction == null) {
        throw NotFoundException('İşlem bulunamadı');
      }

      return transaction;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw CacheException('İşlem alınırken hata oluştu', e);
    }
  }

  @override
  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final box = await _getBox();
      final id = transaction.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : transaction.id;

      final transactionWithId = TransactionModel(
        id: id,
        userId: transaction.userId,
        walletId: transaction.walletId,
        title: transaction.title,
        tag: transaction.tag,
        amount: transaction.amount,
        date: transaction.date,
        time: transaction.time,
        type: transaction.type,
      );

      await box.put(id, transactionWithId);
      return id;
    } catch (e) {
      throw CacheException('İşlem eklenirken hata oluştu', e);
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      final box = await _getBox();

      if (!box.containsKey(transaction.id)) {
        throw NotFoundException('Güncellenecek işlem bulunamadı');
      }

      await box.put(transaction.id, transaction);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw CacheException('İşlem güncellenirken hata oluştu', e);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      final box = await _getBox();

      if (!box.containsKey(id)) {
        throw NotFoundException('Silinecek işlem bulunamadı');
      }

      await box.delete(id);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw CacheException('İşlem silinirken hata oluştu', e);
    }
  }
}
