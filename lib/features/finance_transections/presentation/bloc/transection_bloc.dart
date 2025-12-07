// ==========================================
// PRESENTATION LAYER - BLoC
// ==========================================

// ==========================================
// lib/features/transaction/presentation/bloc/transaction_bloc.dart
import 'package:cunehat/features/finance_transections/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_event.dart';
import 'package:cunehat/features/finance_transections/presentation/bloc/transection_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_transactions_grouped_usecase.dart';
import '../../domain/usecases/add_transaction_usecase.dart';
import '../../domain/usecases/update_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsGroupedUseCase getTransactionsGrouped;
  final AddTransactionUseCase addTransaction;
  final UpdateTransactionUseCase updateTransaction;
  final DeleteTransactionUseCase deleteTransaction;

  TransactionBloc({
    required this.getTransactionsGrouped,
    required this.addTransaction,
    required this.updateTransaction,
    required this.deleteTransaction,
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

    final result = await getTransactionsGrouped(
      GetTransactionsGroupedParams(
        userId: event.userId,
        walletId: event.walletId,
        type: event.type,
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (groupedTransactions) {
        final allTransactions =
            groupedTransactions.values.expand((list) => list).toList();

        emit(TransactionLoaded(
          groupedTransactions: groupedTransactions,
          allTransactions: allTransactions,
        ));
      },
    );
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;
    emit(TransactionLoading());

    final result = await addTransaction(event.transaction);

    result.fold(
      (failure) {
        emit(TransactionError(failure.message));
        if (currentState is TransactionLoaded) {
          emit(currentState);
        }
      },
      (id) {
        emit(const TransactionActionSuccess('İşlem başarıyla eklendi'));
        // Refresh the list
        if (currentState is TransactionLoaded) {
          add(LoadTransactionsEvent(
            userId: event.transaction.userId,
            walletId: event.transaction.walletId,
          ));
        }
      },
    );
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;
    emit(TransactionLoading());

    final result = await updateTransaction(event.transaction);

    result.fold(
      (failure) {
        emit(TransactionError(failure.message));
        if (currentState is TransactionLoaded) {
          emit(currentState);
        }
      },
      (_) {
        emit(const TransactionActionSuccess('İşlem başarıyla güncellendi'));
        // Refresh the list
        if (currentState is TransactionLoaded) {
          add(LoadTransactionsEvent(
            userId: event.transaction.userId,
            walletId: event.transaction.walletId,
          ));
        }
      },
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentState = state;

    final result = await deleteTransaction(event.transactionId);

    result.fold(
      (failure) {
        emit(TransactionError(failure.message));
        if (currentState is TransactionLoaded) {
          emit(currentState);
        }
      },
      (_) {
        if (currentState is TransactionLoaded) {
          // Optimistic update - remove from current list
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
      },
    );
  }
}
