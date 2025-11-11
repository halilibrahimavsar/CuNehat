// firestore_bloc.dart dosyanızı data_bloc.dart olarak yeniden adlandırabilirsiniz.
// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:cunehat/firestore/firestore_bloc/data_event.dart';
import 'package:cunehat/firestore/firestore_bloc/data_state.dart';
import 'package:cunehat/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/firestore/firestore_models/income_model.dart';
import 'package:cunehat/firestore/local_storage/data_repository.dart';

// FirestoreBloc yerine DataBloc
class DataBloc extends Bloc<DataEvent, DataState> {
  // Artık FirestoreService değil, DataRepository alıyor
  final DataRepository dataRepository;

  DataBloc({required this.dataRepository}) : super(NoDataState()) {
    // NOT: Event ve State dosyalarınızı da güncellemeniz gerekecek
    // (Örn: FirestoreEvent -> DataEvent)
    // Şimdilik mevcut event isimlerinizi kullandığınızı varsayıyorum.

    on<GetCompareEvent>((event, emit) async {
      emit(LoadingDataState());
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
          // Modelde Timestamp yerine DateTime kullandığımız için
          // .toDate() metoduna gerek kalmadı!
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
    });

    on<GetExpenseByDateRngEvent>((event, emit) async {
      emit(LoadingDataState());
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
      emit(SuccessfullyGetExpenseState(data: allData));
    });

    on<GetIncomeByDateRngEvent>((event, emit) async {
      // ... (GetExpenseByDateRngEvent ile aynı mantık)
    });

    // Diğer event'ler (Add, Delete, Update)
    // Artık 'Expense' veya 'Income' modellerini doğrudan alabilirler.
  }
}
