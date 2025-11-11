// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:cunehat/firestore/firestore_models/expense_model.dart';
import 'package:cunehat/firestore/firestore_models/income_model.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/firestore/firestore_service.dart';

part 'firestore_event.dart';
part 'firestore_state.dart';

class FirestoreBloc extends Bloc<FirestoreEvent, FirestoreState> {
  final FirestoreService firestoreService;
  FirestoreBloc({required this.firestoreService}) : super(NoDataState()) {
    on<FirestoreEvent>((event, emit) {});
    on<GetCompareEvent>((event, emit) async {
      emit(LoadingDataState());
      Map<DateTime, List<Income>> allIncomeData = {};
      Map<DateTime, List<Expense>> allExpenseData = {};

      await firestoreService
          .getIncomeByDateRange(
        firstDate: event.filterStart,
        lastDate: event.filterEnd,
      )
          .then((values) {
        for (var val in values) {
          DateTime keyDaily = DateTime(
            val.date.toDate().year,
            val.date.toDate().month,
            val.date.toDate().day,
          );
          if (allIncomeData.containsKey(keyDaily)) {
            allIncomeData[keyDaily]?.add(val);
          } else {
            allIncomeData[keyDaily] = [val];
          }
        }
      });
      await firestoreService
          .getExpenseByDateRange(
        firstDate: event.filterStart,
        lastDate: event.filterEnd,
      )
          .then((values) {
        for (var val in values) {
          DateTime keyDaily = DateTime(
            val.date.toDate().year,
            val.date.toDate().month,
            val.date.toDate().day,
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

      await firestoreService
          .getExpenseByDateRange(
        firstDate: event.filterStart,
        lastDate: event.filterEnd,
      )
          .then((values) {
        for (var val in values) {
          DateTime keyDaily = DateTime(
            val.date.toDate().year,
            val.date.toDate().month,
            val.date.toDate().day,
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
      emit(LoadingDataState());
      Map<DateTime, List<Income>> allData = {};

      await firestoreService
          .getIncomeByDateRange(
        firstDate: event.filterStart,
        lastDate: event.filterEnd,
      )
          .then((values) {
        for (var val in values) {
          DateTime keyDaily = DateTime(
            val.date.toDate().year,
            val.date.toDate().month,
            val.date.toDate().day,
          );
          if (allData.containsKey(keyDaily)) {
            allData[keyDaily]?.add(val);
          } else {
            allData[keyDaily] = [val];
          }
        }
      });
      emit(SuccessfullyGetIncomeState(data: allData));
    });
    on<AddExpenseEvent>((event, emit) {});
    on<AddIncomeEvent>((event, emit) {});
    on<DeleteExpenseEvent>((event, emit) {});
    on<DeleteIncomeEvent>((event, emit) {});
    on<UpdateExpenseEvent>((event, emit) {});
    on<UpdateIncomeEvent>((event, emit) {});
  }
}
