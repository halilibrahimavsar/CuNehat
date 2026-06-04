import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

part 'debt_event.dart';
part 'debt_state.dart';

@injectable
class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final GetDebtsUseCase getDebtsUseCase;
  final AddDebtUseCase addDebtUseCase;
  final UpdateDebtUseCase updateDebtUseCase;
  final DeleteDebtUseCase deleteDebtUseCase;
  final WalletMetricsService walletMetricsService;

  DebtBloc({
    required this.getDebtsUseCase,
    required this.addDebtUseCase,
    required this.updateDebtUseCase,
    required this.deleteDebtUseCase,
    required this.walletMetricsService,
  }) : super(DebtInitial()) {
    on<GetDebtsEvent>(_onGetDebts);
    on<AddDebtEvent>(_onAddDebt);
    on<UpdateDebtEvent>(_onUpdateDebt);
    on<PayDebtEvent>(_onPayDebt);
    on<DeleteDebtEvent>(_onDeleteDebt);
  }

  Future<void> _onGetDebts(GetDebtsEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    try {
      final debts = await getDebtsUseCase(event.walletId);

      emit(DebtLoaded(debts));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _onAddDebt(AddDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    try {
      await addDebtUseCase(event.debt);
      // Nakit kuplajı: borç alındı → anapara kadar gelir.
      await walletMetricsService.recordCashMovement(
        walletId: event.debt.walletId,
        userId: event.debt.userId,
        amount: event.debt.principalAmount,
        isIncome: true,
        title: event.debt.title,
        tag: CashMovementTags.debt,
      );
      await _safeSyncDebt(event.debt.walletId);

      emit(const DebtOperationSuccess("Borç başarıyla eklendi."));
      // Listeyi güncellemek için tekrar çekiyoruz
      add(GetDebtsEvent(event.debt.walletId));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _onPayDebt(PayDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    try {
      await updateDebtUseCase(event.debt);
      // Nakit kuplajı: borç ödendi → ödeme kadar gider.
      await walletMetricsService.recordCashMovement(
        walletId: event.debt.walletId,
        userId: event.debt.userId,
        amount: event.paymentAmount,
        isIncome: false,
        title: 'Ödeme: ${event.debt.title}',
        tag: CashMovementTags.debtPayment,
      );
      await _safeSyncDebt(event.debt.walletId);

      emit(const DebtOperationSuccess("Ödeme kaydedildi."));
      add(GetDebtsEvent(event.debt.walletId));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _onUpdateDebt(
      UpdateDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    try {
      await updateDebtUseCase(event.debt);
      await _safeSyncDebt(event.debt.walletId);

      emit(const DebtOperationSuccess("Borç güncellendi."));
      add(GetDebtsEvent(event.debt.walletId));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _onDeleteDebt(
      DeleteDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    try {
      await deleteDebtUseCase(event.id);
      await _safeSyncDebt(event.walletId);

      emit(const DebtOperationSuccess("Borç silindi."));
      add(GetDebtsEvent(event.walletId));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }

  Future<void> _safeSyncDebt(String walletId) async {
    try {
      await walletMetricsService.syncDebt(walletId);
    } catch (e) {
      debugPrint('Wallet debt sync failed: $e');
    }
  }
}
