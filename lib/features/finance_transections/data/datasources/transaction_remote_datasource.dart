// lib/features/finance_transections/data/datasources/transaction_remote_datasource.dart
// ✅ FIXED: Use transaction.id directly

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transections/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_type_enum.dart';
import '../models/transaction_model.dart';

class TransactionFirestoreDataSource implements TransactionsRepository {
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

      // Only filter by userId (simple index)
      query = query.where('userId', isEqualTo: userId);

      // Sort by date
      query = query.orderBy('date', descending: true);

      final snapshot = await query.get();

      // Filter in memory (avoids complex Firestore index)
      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.id, {
                ...doc.data() as Map<String, dynamic>,
              }))
          .where((t) {
        // Filter by walletId
        if (t.walletId != walletId) return false;

        // Filter by type
        if (type != null && t.type != type) return false;

        // Filter by date range
        if (startDate != null && t.date.isBefore(startDate)) return false;
        if (endDate != null && t.date.isAfter(endDate)) return false;

        return true;
      }).toList();

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
  Future<Map<DateTime, List<TransactionEntity>>> getTransactionsGroupedByDate(
      {required String userId,
      required String walletId,
      TransactionTypeModel? type,
      DateTime? startDate,
      DateTime? endDate}) {
    // TODO: implement getTransactionsGroupedByDate
    throw UnimplementedError();
  }
}
