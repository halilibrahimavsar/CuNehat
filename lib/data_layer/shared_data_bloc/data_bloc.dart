import 'package:bloc/bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_state.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/data_repository.dart';

/// **DataBloc**: Manages all data operations and sync status
///
/// Responsibilities:
/// - CRUD operations for Income/Expense
/// - Date range filtering
/// - Sync status monitoring
/// - Auto-refresh after operations
class DataBloc extends Bloc<DataEvent, DataState> {
  final DataRepository dataRepository;

  DataBloc({required this.dataRepository}) : super(NoDataState()) {
    // ============ DATA FETCHING ============

    /// Fetches both income and expense data for comparison view
    on<GetCompareEvent>(_onGetCompare);

    /// Fetches only expense data
    on<GetExpenseByDateRngEvent>(_onGetExpenseByDateRange);

    /// Fetches only income data
    on<GetIncomeByDateRngEvent>(_onGetIncomeByDateRange);

    // ============ CRUD OPERATIONS ============

    on<AddExpenseEvent>(_onAddExpense);
    on<AddIncomeEvent>(_onAddIncome);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<DeleteIncomeEvent>(_onDeleteIncome);
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<UpdateIncomeEvent>(_onUpdateIncome);

    // ============ SYNC OPERATIONS ============

    /// Triggers manual sync and refreshes data
    on<SyncDataEvent>(_onSyncData);

    /// Refreshes current view after operations
    on<RefreshDataEvent>(_onRefreshData);
  }

  // ============ PRIVATE HANDLERS ============

  Future<void> _onGetCompare(
    GetCompareEvent event,
    Emitter<DataState> emit,
  ) async {
    emit(LoadingDataState());
    try {
      final incomeData = await _fetchAndGroupIncome(
        event.filterStart,
        event.filterEnd,
      );
      final expenseData = await _fetchAndGroupExpense(
        event.filterStart,
        event.filterEnd,
      );

      emit(SuccessfullyGetCompareState(
        expense: expenseData,
        income: incomeData,
      ));
    } catch (e) {
      emit(ErrorState(err: 'Veri yüklenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onGetExpenseByDateRange(
    GetExpenseByDateRngEvent event,
    Emitter<DataState> emit,
  ) async {
    emit(LoadingDataState());
    try {
      final expenseData = await _fetchAndGroupExpense(
        event.filterStart,
        event.filterEnd,
      );

      if (expenseData.isEmpty) {
        emit(NoDataState());
      } else {
        emit(SuccessfullyGetExpenseState(data: expenseData));
      }
    } catch (e) {
      emit(ErrorState(err: 'Gider verileri yüklenemedi: ${e.toString()}'));
    }
  }

  Future<void> _onGetIncomeByDateRange(
    GetIncomeByDateRngEvent event,
    Emitter<DataState> emit,
  ) async {
    emit(LoadingDataState());
    try {
      final incomeData = await _fetchAndGroupIncome(
        event.filterStart,
        event.filterEnd,
      );

      if (incomeData.isEmpty) {
        emit(NoDataState());
      } else {
        emit(SuccessfullyGetIncomeState(data: incomeData));
      }
    } catch (e) {
      emit(ErrorState(err: 'Gelir verileri yüklenemedi: ${e.toString()}'));
    }
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<DataState> emit,
  ) async {
    emit(LoadingDataState());
    try {
      await dataRepository.addExpense(expense: event.expense);
      emit(SuccessfullyCreatedItemState());
    } catch (e) {
      emit(ErrorState(err: 'Gider eklenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onAddIncome(
    AddIncomeEvent event,
    Emitter<DataState> emit,
  ) async {
    emit(LoadingDataState());
    try {
      await dataRepository.addIncome(income: event.income);
      emit(SuccessfullyCreatedItemState());
    } catch (e) {
      emit(ErrorState(err: 'Gelir eklenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<DataState> emit,
  ) async {
    try {
      await dataRepository.deleteExpense(id: event.id);
      emit(SuccessfullyDeletedItemState());
    } catch (e) {
      emit(ErrorState(err: 'Gider silinirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteIncome(
    DeleteIncomeEvent event,
    Emitter<DataState> emit,
  ) async {
    try {
      await dataRepository.deleteIncome(id: event.id);
      emit(SuccessfullyDeletedItemState());
    } catch (e) {
      emit(ErrorState(err: 'Gelir silinirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpenseEvent event,
    Emitter<DataState> emit,
  ) async {
    emit(LoadingDataState());
    try {
      await dataRepository.updateExpense(expense: event.expense);
      emit(SuccessfullyUpdatedItemState());
    } catch (e) {
      emit(ErrorState(err: 'Gider güncellenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateIncome(
    UpdateIncomeEvent event,
    Emitter<DataState> emit,
  ) async {
    emit(LoadingDataState());
    try {
      await dataRepository.updateIncome(income: event.income);
      emit(SuccessfullyUpdatedItemState());
    } catch (e) {
      emit(ErrorState(err: 'Gelir güncellenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onSyncData(
    SyncDataEvent event,
    Emitter<DataState> emit,
  ) async {
    emit(SyncingDataState());
    try {
      final success = await dataRepository.syncNow();
      if (success) {
        emit(SyncSuccessState());
        // Auto-refresh after sync
        if (event.dateRange != null) {
          add(GetCompareEvent(
            filterStart: event.dateRange!['start']!,
            filterEnd: event.dateRange!['end']!,
          ));
        }
      } else {
        emit(SyncFailedState());
      }
    } catch (e) {
      emit(ErrorState(err: 'Senkronizasyon hatası: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshData(
    RefreshDataEvent event,
    Emitter<DataState> emit,
  ) async {
    // Re-fetch data without loading indicator
    add(GetCompareEvent(
      filterStart: event.filterStart,
      filterEnd: event.filterEnd,
    ));
  }

  // ============ HELPER METHODS ============

  /// Groups income data by day
  Future<Map<DateTime, List<Income>>> _fetchAndGroupIncome(
    DateTime firstDate,
    DateTime lastDate,
  ) async {
    final incomes = await dataRepository.getIncomeByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );

    final Map<DateTime, List<Income>> grouped = {};
    for (final income in incomes) {
      final dayKey = DateTime(
        income.date.year,
        income.date.month,
        income.date.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(income);
    }
    return grouped;
  }

  /// Groups expense data by day
  Future<Map<DateTime, List<Expense>>> _fetchAndGroupExpense(
    DateTime firstDate,
    DateTime lastDate,
  ) async {
    final expenses = await dataRepository.getExpenseByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );

    final Map<DateTime, List<Expense>> grouped = {};
    for (final expense in expenses) {
      final dayKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(expense);
    }
    return grouped;
  }
}
