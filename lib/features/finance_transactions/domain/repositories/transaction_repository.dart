import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:dartz/dartz.dart';

/// Base interface for transaction data sources
abstract class TransactionsRepository {
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionTypeModel? type,
  });

  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>>
      getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionTypeModel? type,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, TransactionEntity>> getTransactionById(String id);
  Future<Either<Failure, String>> addTransaction(TransactionEntity transaction);

  /// Birden çok işlemi TEK yazımda ekler (bkz. `WalletMetricsService`
  /// mutabakat akışları). Ya hepsi yazılır ya hiçbiri.
  Future<Either<Failure, void>> addTransactions(
      List<TransactionEntity> transactions);
  Future<Either<Failure, void>> updateTransaction(
      TransactionEntity transaction);

  /// [tags]'ten birini taşıyan işlem sayısı — TÜM cüzdanlarda.
  ///
  /// Kategori silme akışı "bu kategoride kaç işlem var?" sorusunu buradan
  /// sorar; kategoriler cüzdana bağlı olmadığı için sayım da öyle.
  Future<Either<Failure, int>> countByTags(Set<String> tags);

  /// [from] etiketlerini [to]'ya çevirir, değişen kayıt sayısını döner.
  /// Bkz. `DeleteCategoryUseCase` — silinen kategorinin işlemleri yetim kalmaz.
  Future<Either<Failure, int>> retagTransactions(Set<String> from, String to);

  /// [keepReceiptFile] true ise iliştirilmiş fiş görseli diskte BIRAKILIR.
  /// "Geri al" akışı bunu kullanır: unlink tek yönlüdür, geri alınan işlem
  /// eki kopmuş halde geri dönerdi. Dosyayı silme sorumluluğu o durumda
  /// `DeletionUndoService.commit`e geçer.
  Future<Either<Failure, void>> deleteTransaction(
    String id, {
    bool keepReceiptFile = false,
  });
}
