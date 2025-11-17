import 'package:bloc/bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_state.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/data_repository.dart';

/// **DataBloc**: WITH DETAILED DEBUG LOGS
class DataBloc extends Bloc<DataEvent, DataState> {
  final DataRepository dataRepository;

  DateTime? _lastFilterStart;
  DateTime? _lastFilterEnd;

  DataBloc({required this.dataRepository}) : super(NoDataState()) {
    print('🟢 [BLOC] DataBloc initialized');

    on<GetCompareEvent>(_onGetCompare);
    on<GetExpenseByDateRngEvent>(_onGetExpenseByDateRange);
    on<GetIncomeByDateRngEvent>(_onGetIncomeByDateRange);
    on<AddExpenseEvent>(_onAddExpense);
    on<AddIncomeEvent>(_onAddIncome);
    on<DeleteExpenseEvent>(_onDeleteExpense);
    on<DeleteIncomeEvent>(_onDeleteIncome);
    on<UpdateExpenseEvent>(_onUpdateExpense);
    on<UpdateIncomeEvent>(_onUpdateIncome);
    on<SyncDataEvent>(_onSyncData);
    on<RefreshDataEvent>(_onRefreshData);
  }

  // ============ DATA FETCHING ============

  Future<void> _onGetCompare(
    GetCompareEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🔵 [BLOC] GetCompareEvent received');
    print('   Date range: ${event.filterStart} → ${event.filterEnd}');

    emit(LoadingDataState());
    print('   State emitted: LoadingDataState');

    _lastFilterStart = event.filterStart;
    _lastFilterEnd = event.filterEnd;

    try {
      print('   Fetching income data...');
      final incomeData = await _fetchAndGroupIncome(
        event.filterStart,
        event.filterEnd,
      );
      print('   ✓ Income data fetched: ${incomeData.length} days');

      print('   Fetching expense data...');
      final expenseData = await _fetchAndGroupExpense(
        event.filterStart,
        event.filterEnd,
      );
      print('   ✓ Expense data fetched: ${expenseData.length} days');

      emit(SuccessfullyGetCompareState(
        expense: expenseData,
        income: incomeData,
      ));
      print('   State emitted: SuccessfullyGetCompareState');
      print(
          '   Total: ${incomeData.values.expand((x) => x).length} incomes, ${expenseData.values.expand((x) => x).length} expenses');
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Veri yüklenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onGetExpenseByDateRange(
    GetExpenseByDateRngEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🔵 [BLOC] GetExpenseByDateRngEvent received');
    emit(LoadingDataState());

    _lastFilterStart = event.filterStart;
    _lastFilterEnd = event.filterEnd;

    try {
      final expenseData = await _fetchAndGroupExpense(
        event.filterStart,
        event.filterEnd,
      );

      if (expenseData.isEmpty) {
        print('   ℹ️  No expense data found');
        emit(NoDataState());
      } else {
        print('   ✓ Expense data found: ${expenseData.length} days');
        emit(SuccessfullyGetExpenseState(data: expenseData));
      }
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Gider verileri yüklenemedi: ${e.toString()}'));
    }
  }

  Future<void> _onGetIncomeByDateRange(
    GetIncomeByDateRngEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🔵 [BLOC] GetIncomeByDateRngEvent received');
    emit(LoadingDataState());

    _lastFilterStart = event.filterStart;
    _lastFilterEnd = event.filterEnd;

    try {
      final incomeData = await _fetchAndGroupIncome(
        event.filterStart,
        event.filterEnd,
      );

      if (incomeData.isEmpty) {
        print('   ℹ️  No income data found');
        emit(NoDataState());
      } else {
        print('   ✓ Income data found: ${incomeData.length} days');
        emit(SuccessfullyGetIncomeState(data: incomeData));
      }
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Gelir verileri yüklenemedi: ${e.toString()}'));
    }
  }

  // ============ CRUD OPERATIONS ============

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🟡 [BLOC] AddExpenseEvent received');
    print(
        '   Expense: ${event.expense.title}, Amount: ${event.expense.amount}');

    try {
      print('   Calling repository.addExpense...');
      await dataRepository.addExpense(expense: event.expense);
      print('   ✓ Expense added to repository');

      emit(SuccessfullyCreatedItemState());
      print('   State emitted: SuccessfullyCreatedItemState');

      print('   Starting silent refresh...');
      await _silentRefresh(emit);
      print('   ✓ Silent refresh completed');
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Gider eklenirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onAddIncome(
    AddIncomeEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🟡 [BLOC] AddIncomeEvent received');
    print('   Income: ${event.income.title}, Amount: ${event.income.amount}');

    try {
      print('   Calling repository.addIncome...');
      await dataRepository.addIncome(income: event.income);
      print('   ✓ Income added to repository');

      emit(SuccessfullyCreatedItemState());
      print('   State emitted: SuccessfullyCreatedItemState');

      print('   Starting silent refresh...');
      await _silentRefresh(emit);
      print('   ✓ Silent refresh completed');
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Gelir eklenirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🔴 [BLOC] DeleteExpenseEvent received');
    print('   ID: ${event.id}');

    try {
      await dataRepository.deleteExpense(id: event.id);
      print('   ✓ Expense deleted');

      emit(SuccessfullyDeletedItemState());
      print('   State emitted: SuccessfullyDeletedItemState');

      await _silentRefresh(emit);
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Gider silinirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onDeleteIncome(
    DeleteIncomeEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🔴 [BLOC] DeleteIncomeEvent received');
    print('   ID: ${event.id}');

    try {
      await dataRepository.deleteIncome(id: event.id);
      print('   ✓ Income deleted');

      emit(SuccessfullyDeletedItemState());
      print('   State emitted: SuccessfullyDeletedItemState');

      await _silentRefresh(emit);
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Gelir silinirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpenseEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🟠 [BLOC] UpdateExpenseEvent received');

    try {
      await dataRepository.updateExpense(expense: event.expense);
      print('   ✓ Expense updated');

      emit(SuccessfullyUpdatedItemState());
      print('   State emitted: SuccessfullyUpdatedItemState');

      await _silentRefresh(emit);
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Gider güncellenirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onUpdateIncome(
    UpdateIncomeEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🟠 [BLOC] UpdateIncomeEvent received');

    try {
      await dataRepository.updateIncome(income: event.income);
      print('   ✓ Income updated');

      emit(SuccessfullyUpdatedItemState());
      print('   State emitted: SuccessfullyUpdatedItemState');

      await _silentRefresh(emit);
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Gelir güncellenirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onSyncData(
    SyncDataEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🔄 [BLOC] SyncDataEvent received');
    emit(SyncingDataState());

    try {
      final success = await dataRepository.syncNow();
      if (success) {
        print('   ✓ Sync successful');
        emit(SyncSuccessState());
        await _silentRefresh(emit);
      } else {
        print('   ⚠️  Sync failed');
        emit(SyncFailedState());
      }
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Senkronizasyon hatası: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshData(
    RefreshDataEvent event,
    Emitter<DataState> emit,
  ) async {
    print('🔄 [BLOC] RefreshDataEvent received');
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
      print('   ✓ Refresh completed');
    } catch (e) {
      print('   ❌ ERROR: $e');
      emit(ErrorState(err: 'Yenileme hatası: ${e.toString()}'));
    }
  }

  // ============ HELPER METHODS ============

  /// Silent refresh - NO loading state
  Future<void> _silentRefresh(Emitter<DataState> emit) async {
    print('   🔄 [SILENT REFRESH] Starting...');

    if (_lastFilterStart == null || _lastFilterEnd == null) {
      print('   ⚠️  [SILENT REFRESH] No date range cached, skipping');
      return;
    }

    print('   Date range: $_lastFilterStart → $_lastFilterEnd');

    try {
      print('   Fetching income...');
      final incomeData = await _fetchAndGroupIncome(
        _lastFilterStart!,
        _lastFilterEnd!,
      );
      print(
          '   ✓ Income fetched: ${incomeData.values.expand((x) => x).length} items');

      print('   Fetching expense...');
      final expenseData = await _fetchAndGroupExpense(
        _lastFilterStart!,
        _lastFilterEnd!,
      );
      print(
          '   ✓ Expense fetched: ${expenseData.values.expand((x) => x).length} items');

      emit(SuccessfullyGetCompareState(
        expense: expenseData,
        income: incomeData,
      ));
      print('   ✓ [SILENT REFRESH] State emitted: SuccessfullyGetCompareState');
    } catch (e) {
      print('   ❌ [SILENT REFRESH] Failed: $e');
    }
  }

  Future<Map<DateTime, List<Income>>> _fetchAndGroupIncome(
    DateTime firstDate,
    DateTime lastDate,
  ) async {
    print('      📥 Fetching incomes from repository...');
    final incomes = await dataRepository.getIncomeByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );
    print('      📥 Raw incomes count: ${incomes.length}');

    final Map<DateTime, List<Income>> grouped = {};
    for (final income in incomes) {
      final dayKey = DateTime(
        income.date.year,
        income.date.month,
        income.date.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(income);
    }
    print('      📥 Grouped into ${grouped.length} days');
    return grouped;
  }

  Future<Map<DateTime, List<Expense>>> _fetchAndGroupExpense(
    DateTime firstDate,
    DateTime lastDate,
  ) async {
    print('      📥 Fetching expenses from repository...');
    final expenses = await dataRepository.getExpenseByDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
    );
    print('      📥 Raw expenses count: ${expenses.length}');

    final Map<DateTime, List<Expense>> grouped = {};
    for (final expense in expenses) {
      final dayKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(expense);
    }
    print('      📥 Grouped into ${grouped.length} days');
    return grouped;
  }
}
