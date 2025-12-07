// ==========================================
// UPDATED REPOSITORY IMPLEMENTATION
// ==========================================

// lib/features/transaction/data/repositories/transaction_repository_impl.dart
import 'package:cunehat/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/core/utils/error_handler.dart';
import 'package:cunehat/core/network/network_info.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactions({
    required String userId,
    required String walletId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  }) async {
    // Check network connection
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('İnternet bağlantısı yok'));
    }

    try {
      final transactions = await remoteDataSource.getTransactions(
        userId: userId,
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      return Right(transactions);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> getTransactionById(
      String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('İnternet bağlantısı yok'));
    }

    try {
      final transaction = await remoteDataSource.getTransactionById(id);
      return Right(transaction);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> addTransaction(
      TransactionEntity transaction) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('İnternet bağlantısı yok'));
    }

    try {
      final model = TransactionModel.fromEntity(transaction);
      final id = await remoteDataSource.addTransaction(model);
      return Right(id);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateTransaction(
      TransactionEntity transaction) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('İnternet bağlantısı yok'));
    }

    try {
      final model = TransactionModel.fromEntity(transaction);
      await remoteDataSource.updateTransaction(model);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('İnternet bağlantısı yok'));
    }

    try {
      await remoteDataSource.deleteTransaction(id);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>>
      getTransactionsGroupedByDate({
    required String userId,
    required String walletId,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('İnternet bağlantısı yok'));
    }

    try {
      final transactions = await remoteDataSource.getTransactions(
        userId: userId,
        walletId: walletId,
        startDate: startDate,
        endDate: endDate,
        type: type,
      );

      // Group by date
      final Map<DateTime, List<TransactionEntity>> grouped = {};
      for (var transaction in transactions) {
        final dateKey = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );

        if (grouped.containsKey(dateKey)) {
          grouped[dateKey]!.add(transaction);
        } else {
          grouped[dateKey] = [transaction];
        }
      }

      return Right(grouped);
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }
}

// ==========================================
// UPDATED DATA SOURCE WITH BETTER ERROR HANDLING
// ==========================================

// ==========================================
// UPDATED DEPENDENCY INJECTION
// ==========================================


// ==========================================
// UPDATED PUBSPEC.YAML
// ==========================================

/*
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^7.6.4
  
  # Functional Programming
  dartz: ^0.10.1
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  
  # Network
  connectivity_plus: ^5.0.2
  
  # Localization & Formatting
  intl: ^0.19.0
  
  # UI
  go_router: ^12.1.3
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  bloc_test: ^9.1.5
*/