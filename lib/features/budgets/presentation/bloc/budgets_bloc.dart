import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:cunehat/features/budgets/domain/usecases/save_budget_usecase.dart';
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'budgets_event.dart';
import 'budgets_state.dart';

@injectable
class BudgetsBloc extends Bloc<BudgetsEvent, BudgetsState> {
  final GetBudgetsUsecase _getBudgetsUsecase;
  final SaveBudgetUsecase _saveBudgetUsecase;
  final DeleteBudgetUsecase _deleteBudgetUsecase;

  BudgetsBloc(
    this._getBudgetsUsecase,
    this._saveBudgetUsecase,
    this._deleteBudgetUsecase,
  ) : super(BudgetsInitial()) {
    on<LoadBudgetsEvent>(_onLoadBudgets);
    on<SaveBudgetEvent>(_onSaveBudget);
    on<DeleteBudgetEvent>(_onDeleteBudget);
  }

  String? _currentUserId;
  String? _currentWalletId;

  Future<void> _onLoadBudgets(
    LoadBudgetsEvent event,
    Emitter<BudgetsState> emit,
  ) async {
    _currentUserId = event.userId;
    _currentWalletId = event.walletId;
    emit(BudgetsLoading());
    final result = await _getBudgetsUsecase(event.userId, event.walletId);
    result.fold(
      (failure) => emit(BudgetsError(failure)),
      (budgets) => emit(BudgetsLoaded(budgets)),
    );
  }

  Future<void> _onSaveBudget(
    SaveBudgetEvent event,
    Emitter<BudgetsState> emit,
  ) async {
    final result = await _saveBudgetUsecase(event.budget);
    result.fold(
      (failure) => emit(BudgetsError(failure)),
      (_) {
        // Yeniden yükle
        if (_currentUserId != null && _currentWalletId != null) {
          add(LoadBudgetsEvent(
            userId: _currentUserId!,
            walletId: _currentWalletId!,
          ));
        }
      },
    );
  }

  Future<void> _onDeleteBudget(
    DeleteBudgetEvent event,
    Emitter<BudgetsState> emit,
  ) async {
    final result = await _deleteBudgetUsecase(event.categoryId);
    result.fold(
      (failure) => emit(BudgetsError(failure)),
      (_) {
        if (_currentUserId != null && _currentWalletId != null) {
          add(LoadBudgetsEvent(
            userId: _currentUserId!,
            walletId: _currentWalletId!,
          ));
        }
      },
    );
  }
}
