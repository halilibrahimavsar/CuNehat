import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

@singleton
class TransactionHiveDataSource {
  static const String _boxName = 'transactions';

  final HiveInterface _hive;

  @visibleForTesting
  TransactionHiveDataSource(this._hive);

  @factoryMethod
  static TransactionHiveDataSource create() => TransactionHiveDataSource(Hive);

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<Box<TransactionModel>> _getBox() async {
    if (!_hive.isBoxOpen(_boxName)) {
      return await _hive.openBox<TransactionModel>(_boxName);
    }
    return _hive.box<TransactionModel>(_boxName);
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

        // Tarih aralığı gün hassasiyetli ve uçları DAHİL: endDate günün
        // hangi saatiyle gelirse gelsin (00:00 dahil) o günün işlemleri kalır.
        final day = _dayOf(t.date);
        if (startDate != null && day.isBefore(_dayOf(startDate))) {
          return false;
        }
        if (endDate != null && day.isAfter(_dayOf(endDate))) {
          return false;
        }

        return true;
      }).toList();

      // Tarih desc; eş tarihte UUIDv7 id (kronolojik) ile kararlı sıralama.
      transactions.sort((a, b) {
        final c = b.date.compareTo(a.date);
        if (c != 0) return c;
        return (b.id ?? '').compareTo(a.id ?? '');
      });

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

  /// Birden çok işlemi TEK Hive yazımında ekler.
  ///
  /// Borç silme gibi mutabakat akışları ödeme başına bir ters kayıt üretir.
  /// Bunları tek tek [addTransaction] ile yazmak her kayıt için ayrı bir await
  /// turu ve disk flush'ı demekti: 36 taksitli bir borçta 37 ardışık yazım,
  /// üstelik silme diyaloğu bloklu beklerken.
  Future<void> addTransactions(List<TransactionModel> transactions) async {
    if (transactions.isEmpty) return;
    try {
      final box = await _getBox();

      final entries = <String, TransactionModel>{};
      for (final transaction in transactions) {
        if (transaction.id == null) {
          throw ValidationException('Transaction ID boş olamaz');
        }
        if (transaction.userId.isEmpty) {
          throw ValidationException('Kullanıcı ID boş olamaz');
        }
        entries[transaction.id!] = transaction;
      }

      await box.putAll(entries);
    } catch (e) {
      throw CacheException('İşlemler eklenirken hata oluştu', e);
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
