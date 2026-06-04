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
    final result = await getDebtsUseCase(event.walletId);
    result.fold(
      (failure) => emit(DebtError(failure.message)),
      (debts) => emit(DebtLoaded(debts)),
    );
  }

  Future<void> _onAddDebt(AddDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    final result = await addDebtUseCase(event.debt);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
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
      },
    );
  }

  Future<void> _onPayDebt(PayDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    final result = await updateDebtUseCase(event.debt);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
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
      },
    );
  }

  Future<void> _onUpdateDebt(
      UpdateDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    final result = await updateDebtUseCase(event.debt);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
        // Mutabakat: anapara değişimi kadar nakit (borç arttıysa gelir).
        final diff = event.debt.principalAmount - event.prevPrincipal;
        if (diff != 0) {
          await walletMetricsService.recordCashMovement(
            walletId: event.debt.walletId,
            userId: event.debt.userId,
            amount: diff.abs(),
            isIncome: diff > 0,
            title: 'Borç güncellendi: ${event.debt.title}',
            tag: CashMovementTags.debt,
          );
        }
        await _safeSyncDebt(event.debt.walletId);

        emit(const DebtOperationSuccess("Borç güncellendi."));
        add(GetDebtsEvent(event.debt.walletId));
      },
    );
  }

  Future<void> _onDeleteDebt(
      DeleteDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    final result = await deleteDebtUseCase(event.id);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
        // Mutabakat: borcun net nakit etkisini geri al.
        // net = +principal (alındı) − Σödeme → geri alma = Σödeme − principal.
        final reversal = event.totalPaidAmount - event.principalAmount;
        if (reversal != 0) {
          await walletMetricsService.recordCashMovement(
            walletId: event.walletId,
            userId: event.userId,
            amount: reversal.abs(),
            isIncome: reversal > 0,
            title: 'Borç silindi',
            tag: CashMovementTags.debt,
          );
        }
        await _safeSyncDebt(event.walletId);

        emit(const DebtOperationSuccess("Borç silindi."));
        add(GetDebtsEvent(event.walletId));
      },
    );
  }

  Future<void> _safeSyncDebt(String walletId) async {
    try {
      await walletMetricsService.syncDebt(walletId);
    } catch (e) {
      debugPrint('Wallet debt sync failed: $e');
    }
  }
}
