// ==========================================
// UPDATED TRANSACTION BLOC (simplified)
// ==========================================

// lib/features/transaction/presentation/bloc/transaction_bloc.dart

import 'package:cunehat/features/finance_transections/data/datasources/transection_data_source.dart';
import 'package:cunehat/features/finance_transections/data/models/transaction_model.dart';
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_event.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionDataSource dataSource;

  TransactionBloc(this.dataSource) : super(TransactionInitial()) {
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
    final currentState = state;
    emit(TransactionLoading());

    try {
      final model = TransactionModel.fromEntity(event.transaction);
      await dataSource.addTransaction(model);

      emit(const TransactionActionSuccess('İşlem başarıyla eklendi'));

      // Refresh the list
      if (currentState is TransactionLoaded) {
        add(LoadTransactionsEvent(
          userId: event.transaction.userId,
          walletId: event.transaction.walletId,
        ));
      }
    } catch (e) {
      emit(TransactionError('İşlem eklenirken hata oluştu: $e'));
      if (currentState is TransactionLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;
    emit(TransactionLoading());

    try {
      final model = TransactionModel.fromEntity(event.transaction);
      await dataSource.updateTransaction(model);

      emit(const TransactionActionSuccess('İşlem başarıyla güncellendi'));

      // Refresh the list
      if (currentState is TransactionLoaded) {
        add(LoadTransactionsEvent(
          userId: event.transaction.userId,
          walletId: event.transaction.walletId,
        ));
      }
    } catch (e) {
      emit(TransactionError('İşlem güncellenirken hata oluştu: $e'));
      if (currentState is TransactionLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;

    try {
      await dataSource.deleteTransaction(event.transactionId);

      if (currentState is TransactionLoaded) {
        // Optimistic update
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
      if (currentState is TransactionLoaded) {
        emit(currentState);
      }
    }
  }
}
