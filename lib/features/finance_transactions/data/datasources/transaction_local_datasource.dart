import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:injectable/injectable.dart';

@singleton
class TransactionHiveDataSource {
  static const String _boxName = 'transactions';

  Future<Box<TransactionModel>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<TransactionModel>(_boxName);
    }
    return Hive.box<TransactionModel>(_boxName);
  }

  Future<List<TransactionModel>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
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

  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      final box = await _getBox();

      // ✅ FIXED: Use transaction.id (already set by UI layer)
      // No need to generate new ID here
      if (transaction.id == null) {
        throw ValidationException('Transaction ID boş olamaz');
      } else if (transaction.userId.isEmpty) {
        throw ValidationException('Kullanıcı ID boş olamaz');
      } else {
        await box.put(transaction.id, transaction);
        return transaction.id!;
      }
    } catch (e) {
      throw CacheException('İşlem eklenirken hata oluştu', e);
    }
  }

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

  Future<Map<DateTime, List<TransactionModel>>> getTransactionsGroupedByDate(
      {required String userId,
      required String walletId,
      TransactionTypeModel? type,
      DateTime? startDate,
      DateTime? endDate}) async {
    try {
      final transactions = await getTransactions(
        userId: userId,
        walletId: walletId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      final groupedTransactions = <DateTime, List<TransactionModel>>{};

      for (final transaction in transactions) {
        final dateWithoutTime = DateTime(transaction.date.year,
            transaction.date.month, transaction.date.day);
        if (groupedTransactions[dateWithoutTime] == null) {
          groupedTransactions[dateWithoutTime] = [];
        }
        groupedTransactions[dateWithoutTime]!.add(transaction);
      }
      return groupedTransactions;
    } catch (e) {
      throw CacheException('İşlemler gruplanırken hata oluştu', e);
    }
  }
}
