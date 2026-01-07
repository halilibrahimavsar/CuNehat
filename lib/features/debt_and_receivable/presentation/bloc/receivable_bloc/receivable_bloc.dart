// lib/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_receivable_sync_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';

part 'receivable_event.dart';
part 'receivable_state.dart';

class ReceivableBloc extends Bloc<ReceivableEvent, ReceivableState> {
  final GetReceivablesUseCase getReceivablesUseCase;
  final AddReceivableUseCase addReceivableUseCase;
  final UpdateReceivableUseCase updateReceivableUseCase;
  final DeleteReceivableUseCase deleteReceivableUseCase;
  final WalletReceivableSyncUsecase walletReceivableSyncUsecase;

  ReceivableBloc({
    required this.getReceivablesUseCase,
    required this.addReceivableUseCase,
    required this.updateReceivableUseCase,
    required this.deleteReceivableUseCase,
    required this.walletReceivableSyncUsecase,
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

      // Wallet'ın credit değerini güncelle
      await walletReceivableSyncUsecase.addReceivable(
        userId: event.receivable.userId,
        walletId: event.receivable.walletId,
        amount: event.receivable.amount,
      );

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
      // Wallet senkronizasyonu için eski tutar gerekli
      await walletReceivableSyncUsecase.updateReceivable(
        userId: event.receivable.userId,
        walletId: event.receivable.walletId,
        prevAmount: event.prevAmount,
        newAmount: event.receivable.amount,
      );

      await updateReceivableUseCase(event.receivable);

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

      // Wallet'ın credit değerini güncelle
      await walletReceivableSyncUsecase.deleteReceivable(
        userId: event.userId,
        walletId: event.walletId,
        amount: event.amount,
      );

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

      // Alacak ödendiğinde credit'ten düş
      await walletReceivableSyncUsecase.deleteReceivable(
        userId: event.receivable.userId,
        walletId: event.receivable.walletId,
        amount: event.receivable.amount,
      );

      emit(const ReceivableOperationSuccess(
          "Alacak ödendi olarak işaretlendi."));
      add(GetReceivablesEvent(event.receivable.walletId));
    } catch (e) {
      emit(ReceivableError(e.toString()));
    }
  }
}
