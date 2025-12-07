// ==========================================
// FIRESTORE IMPLEMENTATION
// ==========================================

// lib/features/transaction/data/datasources/transaction_firestore_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/finance_transections/data/datasources/transection_data_source.dart';
import '../models/transaction_model.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionFirestoreDataSource implements TransactionDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  }) async {
    try {
      Query query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('walletId', isEqualTo: walletId);

      if (type != null) {
        query = query.where('type',
            isEqualTo: type == TransactionType.income ? 'income' : 'expense');
      }

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        query =
            query.where('date', isLessThanOrEqualTo: endDate.toIso8601String());
      }

      final snapshot = await query.orderBy('date', descending: true).get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
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

      return TransactionModel.fromJson({
        'id': doc.id,
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
      final data = transaction.toJson()..remove('id');
      final docRef = await _firestore.collection('transactions').add(data);
      return docRef.id;
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
}
