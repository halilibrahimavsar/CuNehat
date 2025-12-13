// lib/features/finance_transections/data/datasources/transaction_remote_datasource.dart
// ✅ FIXED: Use transaction.id directly

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_data_repository.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import '../models/transaction_model.dart';

class TransactionFirestoreDataSource implements TransactionDataRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  }) async {
    try {
      Query query = _firestore.collection('transactions');

      // Sunucu tarafında filtreleme
      query = query
          .where('userId', isEqualTo: userId)
          .where('walletId', isEqualTo: walletId);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate);
      }

      // Sıralama
      query = query.orderBy('date', descending: true);

      final snapshot = await query.get();

      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.id, {
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      return transactions;
    } on FirebaseException catch (e) {
      throw ServerException('Firebase hatası: ${e.message}', e);
    } catch (e) {
      throw ServerException('İşlemler alınırken hata oluştu', e);
    }
  }

  @override
  Future<TransactionModel> getTransactionById(String id) async {
    try {
      final doc = await _firestore.collection('transactions').doc(id).get();

      if (!doc.exists) {
        throw NotFoundException('İşlem bulunamadı');
      }

      return TransactionModel.fromJson(doc.id, {
        ...doc.data() as Map<String, dynamic>,
      });
    } on FirebaseException catch (e) {
      throw ServerException('Firebase hatası: ${e.message}', e);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException('İşlem alınırken hata oluştu', e);
    }
  }

  @override
  Future<String> addTransaction(TransactionModel transaction) async {
    try {
      // ✅ FIXED: Use transaction.id (already set by UI layer)
      if (transaction.id.isEmpty) {
        throw ValidationException('Transaction ID boş olamaz');
      }
      final data = transaction.toJson();

      await _firestore.collection('transactions').doc(transaction.id).set(data);
      return transaction.id;
    } on FirebaseException catch (e) {
      throw ServerException('Firebase hatası: ${e.message}', e);
    } catch (e) {
      throw ServerException('İşlem eklenirken hata oluştu', e);
    }
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toJson());
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw NotFoundException('Güncellenecek işlem bulunamadı');
      }
      throw ServerException('Firebase hatası: ${e.message}', e);
    } catch (e) {
      throw ServerException('İşlem güncellenirken hata oluştu', e);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _firestore.collection('transactions').doc(id).delete();
    } on FirebaseException catch (e) {
      throw ServerException('Firebase hatası: ${e.message}', e);
    } catch (e) {
      throw ServerException('İşlem silinirken hata oluştu', e);
    }
  }

  @override
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
        startDate: startDate,
        endDate: endDate,
        type: type,
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
      throw ServerException('İşlemler gruplanırken hata oluştu', e);
    }
  }
}
