import 'package:bloc/bloc.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_event.dart';
import 'package:cunehat/data_layer/shared_data_bloc/data_state.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/data_layer/firestore/firestore_models/income_model.dart';
import 'package:cunehat/data_layer/data_repository.dart';

class DataBloc extends Bloc<DataEvent, DataState> {
  // Artık FirestoreService değil, DataRepository alıyor
  final DataRepository dataRepository;

  DataBloc({required this.dataRepository}) : super(NoDataState()) {
    // --- VERİ ÇEKME ---
    on<GetCompareEvent>((event, emit) async {
      emit(LoadingDataState());
      try {
        Map<DateTime, List<Income>> allIncomeData = {};
        Map<DateTime, List<Expense>> allExpenseData = {};

        // Hiçbir değişiklik yok! BLoC sadece repository'yi çağırır.
        await dataRepository
            .getIncomeByDateRange(
          firstDate: event.filterStart,
          lastDate: event.filterEnd,
        )
            .then((values) {
          for (var val in values) {
            DateTime keyDaily = DateTime(
              val.date.year,
              val.date.month,
              val.date.day,
            );
            if (allIncomeData.containsKey(keyDaily)) {
              allIncomeData[keyDaily]?.add(val);
            } else {
              allIncomeData[keyDaily] = [val];
            }
          }
        });

        // Aynı şekilde Expense için de .toDate() kalkar
        await dataRepository
            .getExpenseByDateRange(
          firstDate: event.filterStart,
          lastDate: event.filterEnd,
        )
            .then((values) {
          for (var val in values) {
            DateTime keyDaily = DateTime(
              val.date.year,
              val.date.month,
              val.date.day,
            );
            if (allExpenseData.containsKey(keyDaily)) {
              allExpenseData[keyDaily]?.add(val);
            } else {
              allExpenseData[keyDaily] = [val];
            }
          }
        });
        emit(SuccessfullyGetCompareState(
          expense: allExpenseData,
          income: allIncomeData,
        ));
      } catch (e) {
        emit(ErrorState(err: e.toString()));
      }
    });

    on<GetExpenseByDateRngEvent>((event, emit) async {
      emit(LoadingDataState());
      try {
        Map<DateTime, List<Expense>> allData = {};

        await dataRepository
            .getExpenseByDateRange(
          firstDate: event.filterStart,
          lastDate: event.filterEnd,
        )
            .then((values) {
          for (var val in values) {
            DateTime keyDaily = DateTime(
              val.date.year,
              val.date.month,
              val.date.day,
            );
            if (allData.containsKey(keyDaily)) {
              allData[keyDaily]?.add(val);
            } else {
              allData[keyDaily] = [val];
            }
          }
        });

        if (allData.isEmpty) {
          emit(NoDataState());
        } else {
          emit(SuccessfullyGetExpenseState(data: allData));
        }
      } catch (e) {
        emit(ErrorState(err: e.toString()));
      }
    });

    on<GetIncomeByDateRngEvent>((event, emit) async {
      emit(LoadingDataState());
      try {
        Map<DateTime, List<Income>> allData = {};

        await dataRepository
            .getIncomeByDateRange(
          firstDate: event.filterStart,
          lastDate: event.filterEnd,
        )
            .then((values) {
          for (var val in values) {
            DateTime keyDaily = DateTime(
              val.date.year,
              val.date.month,
              val.date.day,
            );
            if (allData.containsKey(keyDaily)) {
              allData[keyDaily]?.add(val);
            } else {
              allData[keyDaily] = [val];
            }
          }
        });

        if (allData.isEmpty) {
          emit(NoDataState());
        } else {
          emit(SuccessfullyGetIncomeState(data: allData));
        }
      } catch (e) {
        emit(ErrorState(err: e.toString()));
      }
    });

    // --- VERİ İŞLEME (EKLEME, SİLME, GÜNCELLEME) ---

    on<AddExpenseEvent>((event, emit) async {
      emit(LoadingDataState()); // Arayüzde bir yüklenme durumu gösterilebilir
      try {
        await dataRepository.addExpense(expense: event.expense);
        emit(SuccessfullyCreatedItemState());
      } catch (e) {
        emit(ErrorState(err: e.toString()));
      }
    });

    on<AddIncomeEvent>((event, emit) async {
      emit(LoadingDataState());
      try {
        await dataRepository.addIncome(income: event.income);
        emit(SuccessfullyCreatedItemState());
      } catch (e) {
        emit(ErrorState(err: e.toString()));
      }
    });

    on<DeleteExpenseEvent>((event, emit) async {
      // Silme işlemi için "loading" state'i göstermeyebiliriz,
      // arayüzde anlık kaybolması daha iyi bir deneyim olabilir.
      try {
        await dataRepository.deleteExpense(id: event.id);
        emit(SuccessfullyDeletedItemState());
      } catch (e) {
        emit(ErrorState(err: e.toString()));
      }
    });

    on<DeleteIncomeEvent>((event, emit) async {
      try {
        await dataRepository.deleteIncome(id: event.id);
        emit(SuccessfullyDeletedItemState());
      } catch (e) {
        emit(ErrorState(err: e.toString()));
      }
    });

    on<UpdateExpenseEvent>((event, emit) async {
      emit(LoadingDataState());
      try {
        await dataRepository.updateExpense(expense: event.expense);
        emit(SuccessfullyUpdatedItemState());
      } catch (e) {
        emit(ErrorState(err: e.toString()));
      }
    });

    on<UpdateIncomeEvent>((event, emit) async {
      emit(LoadingDataState());
      try {
        await dataRepository.updateIncome(income: event.income);
        emit(SuccessfullyUpdatedItemState());
      } catch (e) {
        emit(ErrorState(err: e.toString()));
      }
    });
  }
}
