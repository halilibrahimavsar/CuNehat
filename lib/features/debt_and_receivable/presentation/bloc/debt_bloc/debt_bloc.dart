import 'package:cunehat/core/blocs/cash_coupling_mixin.dart';
import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:injectable/injectable.dart';

part 'debt_event.dart';
part 'debt_state.dart';

@injectable
class DebtBloc extends Bloc<DebtEvent, DebtState> with CashCouplingMixin {
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
        final cashOk = await walletMetricsService.recordCashMovement(
          walletId: event.debt.walletId,
          userId: event.debt.userId,
          amount: event.debt.principalAmount,
          isIncome: true,
          title: event.debt.title,
          tag: CashMovementTags.debt,
        );
        await _safeSyncDebt(event.debt.walletId);

        emit(DebtOperationSuccess(
            'Borç başarıyla eklendi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
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
        final cashOk = await walletMetricsService.recordCashMovement(
          walletId: event.debt.walletId,
          userId: event.debt.userId,
          amount: event.paymentAmount,
          isIncome: false,
          title: 'Ödeme: ${event.debt.title}',
          tag: CashMovementTags.debtPayment,
        );
        await _safeSyncDebt(event.debt.walletId);

        emit(DebtOperationSuccess(
            'Ödeme kaydedildi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetDebtsEvent(event.debt.walletId));
      },
    );
  }

  Future<void> _onUpdateDebt(
      UpdateDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    // Tutar düzenlemesi isPaid'i geçersiz kılabilir (örn. 600 ödenmişken
    // anapara 500'e indirilirse). isPaid yeniden hesaplanmazsa borç ne aktif
    // listede (remaining ≤ 0) ne geçmişte (isPaid=false) görünür.
    final debt = event.debt.copyWith(
      isPaid: event.debt.totalPaidAmount >= event.debt.totalDebtAmount - 0.005,
    );
    final result = await updateDebtUseCase(debt);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
        // Mutabakat: anapara değişimi kadar nakit (borç arttıysa gelir).
        final diff = event.debt.principalAmount - event.prevPrincipal;
        var cashOk = true;
        if (diff != 0) {
          cashOk = await walletMetricsService.recordCashMovement(
            walletId: event.debt.walletId,
            userId: event.debt.userId,
            amount: diff.abs(),
            isIncome: diff > 0,
            title: 'Borç güncellendi: ${event.debt.title}',
            tag: CashMovementTags.debt,
          );
        }
        await _safeSyncDebt(event.debt.walletId);

        emit(DebtOperationSuccess(
            'Borç güncellendi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
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
        var cashOk = true;
        if (reversal != 0) {
          cashOk = await walletMetricsService.recordCashMovement(
            walletId: event.walletId,
            userId: event.userId,
            amount: reversal.abs(),
            isIncome: reversal > 0,
            title: 'Borç silindi',
            tag: CashMovementTags.debt,
          );
        }
        await _safeSyncDebt(event.walletId);

        emit(DebtOperationSuccess(
            'Borç silindi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetDebtsEvent(event.walletId));
      },
    );
  }

  Future<void> _safeSyncDebt(String walletId) =>
      safeSyncMetric(() => walletMetricsService.syncDebt(walletId), 'debt');
}
