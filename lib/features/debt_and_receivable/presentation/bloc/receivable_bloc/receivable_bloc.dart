// lib/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

part 'receivable_event.dart';
part 'receivable_state.dart';

@injectable
class ReceivableBloc extends Bloc<ReceivableEvent, ReceivableState> {
  final GetReceivablesUseCase getReceivablesUseCase;
  final AddReceivableUseCase addReceivableUseCase;
  final UpdateReceivableUseCase updateReceivableUseCase;
  final DeleteReceivableUseCase deleteReceivableUseCase;
  final WalletMetricsService walletMetricsService;

  ReceivableBloc({
    required this.getReceivablesUseCase,
    required this.addReceivableUseCase,
    required this.updateReceivableUseCase,
    required this.deleteReceivableUseCase,
    required this.walletMetricsService,
  }) : super(ReceivableInitial()) {
    on<GetReceivablesEvent>(_onGetReceivables);
    on<AddReceivableEvent>(_onAddReceivable);
    on<UpdateReceivableEvent>(_onUpdateReceivable);
    on<DeleteReceivableEvent>(_onDeleteReceivable);
    on<MarkReceivableAsPaidEvent>(_onMarkAsPaid);
  }

  Future<void> _onGetReceivables(
      GetReceivablesEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    try {
      final receivables = await getReceivablesUseCase(event.walletId);
      emit(ReceivableLoaded(receivables));
    } catch (e) {
      emit(ReceivableError(e.toString()));
    }
  }

  Future<void> _onAddReceivable(
      AddReceivableEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    try {
      await addReceivableUseCase(event.receivable);
      await _safeSyncCredit(event.receivable.walletId);

      emit(const ReceivableOperationSuccess("Alacak başarıyla eklendi."));
      add(GetReceivablesEvent(event.receivable.walletId));
    } catch (e) {
      emit(ReceivableError(e.toString()));
    }
  }

  Future<void> _onUpdateReceivable(
      UpdateReceivableEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    try {
      await updateReceivableUseCase(event.receivable);
      await _safeSyncCredit(event.receivable.walletId);

      emit(const ReceivableOperationSuccess("Alacak güncellendi."));
      add(GetReceivablesEvent(event.receivable.walletId));
    } catch (e) {
      emit(ReceivableError(e.toString()));
    }
  }

  Future<void> _onDeleteReceivable(
      DeleteReceivableEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    try {
      await deleteReceivableUseCase(event.id);
      await _safeSyncCredit(event.walletId);

      emit(const ReceivableOperationSuccess("Alacak silindi."));
      add(GetReceivablesEvent(event.walletId));
    } catch (e) {
      emit(ReceivableError(e.toString()));
    }
  }

  /// Alacak ödendiğinde işaretle
  Future<void> _onMarkAsPaid(
      MarkReceivableAsPaidEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    try {
      final updatedReceivable = event.receivable.copyWith(isPaid: true);
      await updateReceivableUseCase(updatedReceivable);
      await _safeSyncCredit(event.receivable.walletId);

      emit(const ReceivableOperationSuccess(
          "Alacak ödendi olarak işaretlendi."));
      add(GetReceivablesEvent(event.receivable.walletId));
    } catch (e) {
      emit(ReceivableError(e.toString()));
    }
  }

  Future<void> _safeSyncCredit(String walletId) async {
    try {
      await walletMetricsService.syncCredit(walletId);
    } catch (e) {
      debugPrint('Wallet credit sync failed: $e');
    }
  }
}
