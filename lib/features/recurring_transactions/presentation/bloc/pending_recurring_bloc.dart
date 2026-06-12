// lib/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/get_pending_recurring_transactions_usecase.dart';
import '../../domain/usecases/approve_recurring_transaction_usecase.dart';
import '../../domain/usecases/delete_recurring_transaction_usecase.dart';
import 'pending_recurring_event.dart';
import 'pending_recurring_state.dart';

@injectable
class PendingRecurringBloc
    extends Bloc<PendingRecurringEvent, PendingRecurringState> {
  final GetPendingRecurringTransactionsUsecase getPendingUsecase;
  final ApproveRecurringTransactionUsecase approveUsecase;
  final DeleteRecurringTransactionUsecase deleteUsecase;

  PendingRecurringBloc(
    this.getPendingUsecase,
    this.approveUsecase,
    this.deleteUsecase,
  ) : super(PendingRecurringInitial()) {
    on<LoadPendingTransactionsEvent>(_onLoadPendingTransactions);
    on<ApproveTransactionEvent>(_onApproveTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  Future<void> _onLoadPendingTransactions(
    LoadPendingTransactionsEvent event,
    Emitter<PendingRecurringState> emit,
  ) async {
    emit(PendingRecurringLoading());
    final result = await getPendingUsecase();

    result.fold(
      (failure) => emit(PendingRecurringFailure(failure)),
      (transactions) => emit(PendingRecurringLoaded(transactions)),
    );
  }

  Future<void> _onApproveTransaction(
    ApproveTransactionEvent event,
    Emitter<PendingRecurringState> emit,
  ) async {
    // UI'ın anlık tepki vermesi için loading state'e çekebiliriz ama
    // arka planda sessiz yapıp reload da atabiliriz. Sessiz reload daha iyi.
    final result = await approveUsecase(event.template);

    result.fold(
      (failure) => emit(PendingRecurringFailure(failure)),
      (_) {
        // İşlem onaylandığında listeden çıkması için tekrar load eventini tetikle
        add(LoadPendingTransactionsEvent());
      },
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<PendingRecurringState> emit,
  ) async {
    final result = await deleteUsecase(event.id);
    result.fold(
      (failure) => emit(PendingRecurringFailure(failure)),
      (_) {
        add(LoadPendingTransactionsEvent());
      },
    );
  }
}
