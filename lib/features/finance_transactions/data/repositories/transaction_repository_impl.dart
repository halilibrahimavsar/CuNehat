import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/features/finance_transactions/data/datasources/transaction_local_datasource.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TransactionsRepository)
class TransactionRepositoryImpl implements TransactionsRepository {
  final TransactionHiveDataSource localDatasource;
  final ReceiptStorageService receiptStorage;

  TransactionRepositoryImpl({
    required this.localDatasource,
    required this.receiptStorage,
  });

  @override
  Future<Either<Failure, String>> addTransaction(
      TransactionEntity transaction) async {
    try {
      final id = await localDatasource
          .addTransaction(TransactionModel.fromEntity(transaction));
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('İşlem eklenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addTransactions(
      List<TransactionEntity> transactions) async {
    try {
      await localDatasource.addTransactions(
        transactions.map(TransactionModel.fromEntity).toList(),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('İşlemler eklenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(
      TransactionEntity transaction) async {
    try {
      // Fiş değiştirilmiş/kaldırılmışsa eski görsel dosyasını temizle.
      final oldReceipt = await _existingReceiptFileName(transaction.id);
      await localDatasource
          .updateTransaction(TransactionModel.fromEntity(transaction));
      if (oldReceipt != null && oldReceipt != transaction.receiptFileName) {
        await receiptStorage.delete(oldReceipt);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('İşlem güncellenemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(
    String id, {
    bool keepReceiptFile = false,
  }) async {
    try {
      // İşlemin fişini de sil (varsa) — önce dosya adını al.
      final receipt =
          keepReceiptFile ? null : await _existingReceiptFileName(id);
      await localDatasource.deleteTransaction(id);
      if (receipt != null) {
        await receiptStorage.delete(receipt);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('İşlem silinemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> countByTags(Set<String> tags) async {
    try {
      return Right(await localDatasource.countByTags(tags));
    } catch (e) {
      return Left(CacheFailure('İşlemler sayılamadı: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> retagTransactions(
      Set<String> from, String to) async {
    try {
      return Right(await localDatasource.retagTransactions(from, to));
    } catch (e) {
      return Left(CacheFailure('İşlemler taşınamadı: ${e.toString()}'));
    }
  }

  /// Kayıtlı işlemin fiş dosya adını döndürür; işlem yoksa/hata olursa null
  /// (dosya temizliği asıl işlemi bloklamamalı).
  Future<String?> _existingReceiptFileName(String? id) async {
    if (id == null) return null;
    try {
      final model = await localDatasource.getTransactionById(id);
      return model.receiptFileName;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(
      String id) async {
    try {
      final model = await localDatasource.getTransactionById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure('İşlem getirilemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  }) async {
    try {
      final models = await localDatasource.getTransactions(
        userId: userId,
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure('İşlemler getirilemedi: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>>
      getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionTypeModel? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final modelsMap = await localDatasource.getTransactionsGroupedByDate(
        userId: userId,
        walletId: walletId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      final Map<DateTime, List<TransactionEntity>> entitiesMap = {};
      modelsMap.forEach((date, models) {
        entitiesMap[date] = models.map((m) => m.toEntity()).toList();
      });

      return Right(entitiesMap);
    } catch (e) {
      return Left(
          CacheFailure('Gruplanmış işlemler getirilemedi: ${e.toString()}'));
    }
  }
}
