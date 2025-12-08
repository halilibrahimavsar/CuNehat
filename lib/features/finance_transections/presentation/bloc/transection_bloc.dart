// lib/features/finance_transections/presentation/bloc/transection_bloc.dart

import 'package:cunehat/features/finance_transections/data/datasources/transection_data_source.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_event.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_state.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_balance_sync_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionDataSource dataSource;
  final WalletBalanceSyncUseCase walletSyncUseCase;

  TransactionBloc({
    required this.dataSource,
    required this.walletSyncUseCase,
  }) : super(TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    try {
      final transactions = await dataSource.getTransactions(
        userId: event.userId,
        walletId: event.walletId,
        startDate: event.startDate,
        endDate: event.endDate,
        type: event.type,
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

      final allTransactions = grouped.values.expand((list) => list).toList();

      emit(TransactionLoaded(
        groupedTransactions: grouped,
        allTransactions: allTransactions,
      ));
    } catch (e) {
      emit(TransactionError('İşlemler yüklenirken hata oluştu: $e'));
    }
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final previousState = state;

      // 1. Add transaction to database
      final model = TransactionModel.fromEntity(event.transaction);
      await dataSource.addTransaction(model);

      // 2. ✅ NEW: Update wallet balance
      await walletSyncUseCase.applyTransaction(
        walletId: event.transaction.walletId,
        transaction: event.transaction,
      );

      emit(const TransactionActionSuccess('İşlem başarıyla eklendi'));

      // 3. Reload transactions
      if (previousState is TransactionLoaded ||
          previousState is TransactionInitial) {
        add(LoadTransactionsEvent(
          userId: event.transaction.userId,
          walletId: event.transaction.walletId,
        ));
      }
    } catch (e) {
      emit(TransactionError('İşlem eklenirken hata oluştu: $e'));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final previousState = state;

      // 1. Get old transaction for wallet balance calculation
      final oldTransaction =
          await dataSource.getTransactionById(event.transaction.id);

      // 2. Update transaction in database
      final model = TransactionModel.fromEntity(event.transaction);
      await dataSource.updateTransaction(model);

      // 3. ✅ NEW: Update wallet balance (reverse old, apply new)
      await walletSyncUseCase.updateTransaction(
        walletId: event.transaction.walletId,
        oldTransaction: oldTransaction,
        newTransaction: event.transaction,
      );

      emit(const TransactionActionSuccess('İşlem başarıyla güncellendi'));

      // 4. Reload transactions
      if (previousState is TransactionLoaded) {
        add(LoadTransactionsEvent(
          userId: event.transaction.userId,
          walletId: event.transaction.walletId,
        ));
      }
    } catch (e) {
      emit(TransactionError('İşlem güncellenirken hata oluştu: $e'));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      // 1. Get transaction before deleting (for wallet balance update)
      final transaction =
          await dataSource.getTransactionById(event.transactionId);

      // 2. Delete transaction from database
      await dataSource.deleteTransaction(event.transactionId);

      // 3. ✅ NEW: Update wallet balance (reverse transaction)
      await walletSyncUseCase.applyTransaction(
        walletId: transaction.walletId,
        transaction: transaction,
        isReversal: true, // Reverse the transaction
      );

      // 4. Update UI immediately
      if (state is TransactionLoaded) {
        final currentState = state as TransactionLoaded;

        final updatedGrouped = Map<DateTime, List<TransactionEntity>>.from(
          currentState.groupedTransactions,
        );

        updatedGrouped.forEach((date, transactions) {
          transactions.removeWhere((t) => t.id == event.transactionId);
        });

        updatedGrouped
            .removeWhere((date, transactions) => transactions.isEmpty);

        final allTransactions =
            updatedGrouped.values.expand((list) => list).toList();

        emit(TransactionLoaded(
          groupedTransactions: updatedGrouped,
          allTransactions: allTransactions,
        ));
      }

      emit(const TransactionActionSuccess('İşlem başarıyla silindi'));
    } catch (e) {
      emit(TransactionError('İşlem silinirken hata oluştu: $e'));
    }
  }
}
