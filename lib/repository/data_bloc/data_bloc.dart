import 'package:bloc/bloc.dart';
import 'package:cunehat/repository/data_bloc/data_event.dart';
import 'package:cunehat/repository/data_bloc/data_state.dart';
import 'package:cunehat/repository/models/expense_model.dart';
import 'package:cunehat/repository/models/income_model.dart';
import 'package:cunehat/repository/data_repository.dart';

class DataBloc extends Bloc<DataEvent, DataState> {
  final DataRepository dataRepository;

  DateTime? _lastFilterStart;
  DateTime? _lastFilterEnd;

  DataBloc({required this.dataRepository}) : super(NoDataState()) {
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

  Future<void> _onGetCompare(
      GetCompareEvent event, Emitter<DataState> emit) async {
    emit(LoadingDataState());
    _lastFilterStart = event.filterStart;
    _lastFilterEnd = event.filterEnd;

    try {
      // ✅ DÜZELTME: Artık aktif cüzdana göre filtreleniyor
      final incomeData =
          await _fetchAndGroupIncome(event.filterStart, event.filterEnd);
      final expenseData =
          await _fetchAndGroupExpense(event.filterStart, event.filterEnd);

      emit(SuccessfullyGetCompareState(
          expense: expenseData, income: incomeData));
    } catch (e) {
      emit(ErrorState(err: 'Veri yüklenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onGetExpenseByDateRange(
      GetExpenseByDateRngEvent event, Emitter<DataState> emit) async {
    emit(LoadingDataState());
    _lastFilterStart = event.filterStart;
    _lastFilterEnd = event.filterEnd;

    try {
      // ✅ DÜZELTME: Artık aktif cüzdana göre filtreleniyor
      final expenseData =
          await _fetchAndGroupExpense(event.filterStart, event.filterEnd);

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
      GetIncomeByDateRngEvent event, Emitter<DataState> emit) async {
    emit(LoadingDataState());
    _lastFilterStart = event.filterStart;
    _lastFilterEnd = event.filterEnd;

    try {
      // ✅ DÜZELTME: Artık aktif cüzdana göre filtreleniyor
      final incomeData =
          await _fetchAndGroupIncome(event.filterStart, event.filterEnd);

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
      AddExpenseEvent event, Emitter<DataState> emit) async {
    try {
      await dataRepository.addExpense(expense: event.expense);
      emit(SuccessfullyCreatedItemState(name: event.expense.title));
      await _silentRefresh(emit);
    } catch (e) {
      emit(ErrorState(err: 'Gider eklenirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onAddIncome(
      AddIncomeEvent event, Emitter<DataState> emit) async {
    try {
      await dataRepository.addIncome(income: event.income);
      emit(SuccessfullyCreatedItemState(name: event.income.title));
      await _silentRefresh(emit);
    } catch (e) {
      emit(ErrorState(err: 'Gelir eklenirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onDeleteExpense(
      DeleteExpenseEvent event, Emitter<DataState> emit) async {
    try {
      await dataRepository.deleteExpense(
          id: event.expense.id,
          amount: event.expense.amount,
          walletId: event.expense.walletId);
      emit(SuccessfullyDeletedItemState(name: event.expense.title));
      await _silentRefresh(emit);
    } catch (e) {
      emit(ErrorState(err: 'Gider silinirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onDeleteIncome(
      DeleteIncomeEvent event, Emitter<DataState> emit) async {
    try {
      await dataRepository.deleteIncome(
          id: event.income.id,
          amount: event.income.amount,
          walletId: event.income.walletId);
      emit(SuccessfullyDeletedItemState(name: event.income.title));
      await _silentRefresh(emit);
    } catch (e) {
      emit(ErrorState(err: 'Gelir silinirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onUpdateExpense(
      UpdateExpenseEvent event, Emitter<DataState> emit) async {
    try {
      await dataRepository.updateExpense(expense: event.expense);
      emit(SuccessfullyUpdatedItemState(name: event.expense.title));
      await _silentRefresh(emit);
    } catch (e) {
      emit(ErrorState(err: 'Gider güncellenirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onUpdateIncome(
      UpdateIncomeEvent event, Emitter<DataState> emit) async {
    try {
      await dataRepository.updateIncome(income: event.income);
      emit(SuccessfullyUpdatedItemState(name: event.income.title));
      await _silentRefresh(emit);
    } catch (e) {
      emit(ErrorState(err: 'Gelir güncellenirken hata: ${e.toString()}'));
      await _silentRefresh(emit);
    }
  }

  Future<void> _onSyncData(SyncDataEvent event, Emitter<DataState> emit) async {
    emit(SyncingDataState());

    try {
      final success = await dataRepository.syncNow();
      if (success) {
        emit(SyncSuccessState());
        await _silentRefresh(emit);
      } else {
        emit(SyncFailedState());
      }
    } catch (e) {
      emit(ErrorState(err: 'Senkronizasyon hatası: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshData(
      RefreshDataEvent event, Emitter<DataState> emit) async {
    emit(LoadingDataState());
    final Map<DateTime, List<Income>> incomeData;
    final Map<DateTime, List<Expense>> expenseData;
    bool isFetchedIncome = false;
    bool isFetchedExpense = false;

    try {
      // ✅ DÜZELTME: Artık aktif cüzdana göre filtreleniyor
      incomeData =
          await _fetchAndGroupIncome(event.filterStart, event.filterEnd)
              .whenComplete(
        () {
          isFetchedIncome = true;
        },
      );
      expenseData =
          await _fetchAndGroupExpense(event.filterStart, event.filterEnd)
              .whenComplete(
        () {
          isFetchedExpense = true;
        },
      );

      if (isFetchedExpense && isFetchedIncome) {
        emit(SuccessfullyGetCompareState(
            expense: expenseData, income: incomeData));
      } else {
        emit(LoadingDataState());
      }
    } catch (e) {
      emit(ErrorState(err: 'Yenileme hatası: ${e.toString()}'));
    }
  }

  Future<void> _silentRefresh(Emitter<DataState> emit) async {
    if (_lastFilterStart == null || _lastFilterEnd == null) {
      emit(ErrorState(err: 'Yenileme hatası: Tarihler boş olamaz'));
      return;
    }

    try {
      // ✅ DÜZELTME: Artık aktif cüzdana göre filtreleniyor
      final incomeData =
          await _fetchAndGroupIncome(_lastFilterStart!, _lastFilterEnd!);
      final expenseData =
          await _fetchAndGroupExpense(_lastFilterStart!, _lastFilterEnd!);

      emit(SuccessfullyGetCompareState(
        expense: expenseData,
        income: incomeData,
      ));
    } catch (e) {
      throw Exception('Yenileme hatası: ${e.toString()}');
    }
  }

  /// ✅ DÜZELTME: Artık repository üzerinden aktif cüzdana göre filtreliyor
  Future<Map<DateTime, List<Income>>> _fetchAndGroupIncome(
      DateTime firstDate, DateTime lastDate) async {
    // Repository zaten aktif cüzdana göre filtreliyor
    final incomes = await dataRepository.getIncomeByDateRange(
        firstDate: firstDate, lastDate: lastDate);

    final Map<DateTime, List<Income>> grouped = {};

    for (final income in incomes) {
      final dayKey =
          DateTime(income.date.year, income.date.month, income.date.day);
      grouped.putIfAbsent(dayKey, () => []).add(income);
    }

    return grouped;
  }

  /// ✅ DÜZELTME: Artık repository üzerinden aktif cüzdana göre filtreliyor
  Future<Map<DateTime, List<Expense>>> _fetchAndGroupExpense(
      DateTime firstDate, DateTime lastDate) async {
    // Repository zaten aktif cüzdana göre filtreliyor
    final expenses = await dataRepository.getExpenseByDateRange(
        firstDate: firstDate, lastDate: lastDate);

    final Map<DateTime, List<Expense>> grouped = {};

    for (final expense in expenses) {
      final dayKey =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      grouped.putIfAbsent(dayKey, () => []).add(expense);
    }

    return grouped;
  }
}
