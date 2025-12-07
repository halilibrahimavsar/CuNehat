// lib/features/compare/presentation/bloc/compare_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cunehat/features/compare/domain/models/combine_model.dart';
import 'package:cunehat/features/compare/domain/repository/compare_repository.dart';
import 'package:cunehat/features/compare/domain/usecases/get_transections_usecase.dart';
import 'package:equatable/equatable.dart';

part 'compare_event.dart';
part 'compare_state.dart';

class CompareBloc extends Bloc<CompareEvent, CompareState> {
  final CompareRepository repository;
  StreamSubscription<List<CombinedTransaction>>? _transactionSubscription;

  CompareBloc(this.repository) : super(const CompareInitialSt()) {
    on<GetTransactionsCompareEvent>(_onGetTransactions);
    on<GetExpensesOnlyEvent>(_onGetExpensesOnly);
    on<GetIncomesOnlyEvent>(_onGetIncomesOnly);
    on<_EmitLoadedEvent>(_onEmitLoaded);
    on<_EmitEmptyEvent>(_onEmitEmpty);
    on<_EmitErrorEvent>(_onEmitError);
  }

  Future<void> _onGetTransactions(
    GetTransactionsCompareEvent event,
    Emitter<CompareState> emit,
  ) async {
    emit(const CompareLoadingSt());

    await _transactionSubscription?.cancel();

    try {
      _transactionSubscription = GetTransactionsUseCase(repository)
          .call(
        userId: event.userId,
        walletId: event.walletId,
        startDate: event.startDate,
        endDate: event.endDate,
      )
          .listen(
        (transactions) {
          if (transactions.isEmpty) {
            add(const _EmitEmptyEvent());
          } else {
            add(_EmitLoadedEvent(transactions));
          }
        },
        onError: (error) {
          add(_EmitErrorEvent(error.toString()));
        },
      );
    } catch (e) {
      emit(CompareErrorSt(e.toString()));
    }
  }

  Future<void> _onGetExpensesOnly(
    GetExpensesOnlyEvent event,
    Emitter<CompareState> emit,
  ) async {
    emit(const CompareLoadingSt());

    await _transactionSubscription?.cancel();

    try {
      _transactionSubscription = GetExpensesUseCase(repository)
          .call(
        userId: event.userId,
        walletId: event.walletId,
        startDate: event.startDate,
        endDate: event.endDate,
      )
          .listen(
        (transactions) {
          if (transactions.isEmpty) {
            add(const _EmitEmptyEvent());
          } else {
            add(_EmitLoadedEvent(transactions));
          }
        },
        onError: (error) {
          add(_EmitErrorEvent(error.toString()));
        },
      );
    } catch (e) {
      emit(CompareErrorSt(e.toString()));
    }
  }

  Future<void> _onGetIncomesOnly(
    GetIncomesOnlyEvent event,
    Emitter<CompareState> emit,
  ) async {
    emit(const CompareLoadingSt());

    await _transactionSubscription?.cancel();

    try {
      _transactionSubscription = GetIncomesUseCase(repository)
          .call(
        userId: event.userId,
        walletId: event.walletId,
        startDate: event.startDate,
        endDate: event.endDate,
      )
          .listen(
        (transactions) {
          if (transactions.isEmpty) {
            add(const _EmitEmptyEvent());
          } else {
            add(_EmitLoadedEvent(transactions));
          }
        },
        onError: (error) {
          add(_EmitErrorEvent(error.toString()));
        },
      );
    } catch (e) {
      emit(CompareErrorSt(e.toString()));
    }
  }

  void _onEmitLoaded(_EmitLoadedEvent event, Emitter<CompareState> emit) {
    emit(CompareLoadedSt(event.transactions));
  }

  void _onEmitEmpty(_EmitEmptyEvent event, Emitter<CompareState> emit) {
    emit(const CompareEmptySt());
  }

  void _onEmitError(_EmitErrorEvent event, Emitter<CompareState> emit) {
    emit(CompareErrorSt(event.error));
  }

  @override
  Future<void> close() async {
    await _transactionSubscription?.cancel();
    return super.close();
  }
}
