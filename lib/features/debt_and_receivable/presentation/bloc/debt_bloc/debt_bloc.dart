import 'package:bloc/bloc.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_debt_sync_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';

part 'debt_event.dart';
part 'debt_state.dart';

class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final GetDebtsUseCase getDebtsUseCase;
  final AddDebtUseCase addDebtUseCase;
  final UpdateDebtUseCase updateDebtUseCase;
  final DeleteDebtUseCase deleteDebtUseCase;
  final WalletDebtSyncUsecase walletDebtSyncUsecase;

  DebtBloc({
    required this.getDebtsUseCase,
    required this.addDebtUseCase,
    required this.updateDebtUseCase,
    required this.deleteDebtUseCase,
    required this.walletDebtSyncUsecase,
  }) : super(DebtInitial()) {
    on<GetDebtsEvent>(_onGetDebts);
    on<AddDebtEvent>(_onAddDebt);
    on<UpdateDebtEvent>(_onUpdateDebt);
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
      await walletDebtSyncUsecase.addDebt(
        userId: event.debt.userId,
        walletId: event.debt.walletId,
        amount: event.debt.principalAmount,
      );

      emit(const DebtOperationSuccess("Borç başarıyla eklendi."));
      // Listeyi güncellemek için tekrar çekiyoruz
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
      await walletDebtSyncUsecase.updateDebt(
        userId: event.debt.userId,
        walletId: event.debt.walletId,
        prevAmount: event.debt.principalAmount,
        newAmount: event.debt.principalAmount,
      );
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
      await walletDebtSyncUsecase.deleteDebt(
        userId: event.userId,
        walletId: event.walletId,
        amount: event.amount,
      );
      emit(const DebtOperationSuccess("Borç silindi."));
      add(GetDebtsEvent(event.walletId));
    } catch (e) {
      emit(DebtError(e.toString()));
    }
  }
}
