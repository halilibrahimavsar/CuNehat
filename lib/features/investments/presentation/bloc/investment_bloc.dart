import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

part 'investment_event.dart';
part 'investment_state.dart';

@injectable
class InvestmentBloc extends Bloc<InvestmentEvent, InvestmentState> {
  final GetInvestmentsUseCase getInvestmentsUseCase;
  final AddInvestmentUseCase addInvestmentUseCase;
  final UpdateInvestmentUseCase updateInvestmentUseCase;
  final DeleteInvestmentUseCase deleteInvestmentUseCase;
  final WalletMetricsService walletMetricsService;

  InvestmentBloc({
    required this.getInvestmentsUseCase,
    required this.addInvestmentUseCase,
    required this.updateInvestmentUseCase,
    required this.deleteInvestmentUseCase,
    required this.walletMetricsService,
  }) : super(InvestmentInitial()) {
    // Yatırımları Getir
    on<GetInvestmentsEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await getInvestmentsUseCase.call(
        userId: event.userId,
        walletId: event.walletId,
      );

      result.fold(
        (failure) => emit(InvestmentError(failure.message)),
        (investments) {
          final total =
              investments.fold<double>(0, (sum, item) => sum + item.amount);
          emit(InvestmentLoaded(investments, totalAmount: total));
        },
      );
    });

    // Yatırım Ekle
    on<CreateInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await addInvestmentUseCase.call(event.investment);

      await result.fold(
        (failure) async => emit(InvestmentError(failure.message)),
        (_) async {
          await _safeSyncInvestment(event.walletId);
          emit(const InvestmentActionSuccess('Yatırım başarıyla eklendi'));
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
    });

    // Yatırım Güncelle
    on<UpdateInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await updateInvestmentUseCase.call(event.investment);

      await result.fold(
        (failure) async => emit(InvestmentError(failure.message)),
        (_) async {
          await _safeSyncInvestment(event.walletId);
          emit(const InvestmentActionSuccess('Yatırım güncellendi'));
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
    });

    // Yatırım Sil
    on<DeleteInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await deleteInvestmentUseCase.call(event.id);

      await result.fold(
        (failure) async => emit(InvestmentError(failure.message)),
        (_) async {
          await _safeSyncInvestment(event.walletId);
          emit(const InvestmentActionSuccess('Yatırım silindi'));
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
    });
  }

  Future<void> _safeSyncInvestment(String walletId) async {
    try {
      await walletMetricsService.syncInvestment(walletId);
    } catch (e) {
      debugPrint('Wallet investment sync failed: $e');
    }
  }
}
