import 'package:bloc/bloc.dart';
import 'package:cunehat/core/utils/error_handler.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_investment_sync_usecase.dart';
import 'package:equatable/equatable.dart';

part 'investment_event.dart';
part 'investment_state.dart';

class InvestmentBloc extends Bloc<InvestmentEvent, InvestmentState> {
  final GetInvestmentsUseCase getInvestmentsUseCase;
  final AddInvestmentUseCase addInvestmentUseCase;
  final UpdateInvestmentUseCase updateInvestmentUseCase;
  final DeleteInvestmentUseCase deleteInvestmentUseCase;
  final WalletInvestmentSyncUsecase
      walletSyncUseCase; // this one is for updating wallet feature

  InvestmentBloc({
    required this.getInvestmentsUseCase,
    required this.addInvestmentUseCase,
    required this.updateInvestmentUseCase,
    required this.deleteInvestmentUseCase,
    required this.walletSyncUseCase,
  }) : super(InvestmentInitial()) {
    // Yatırımları Getir
    on<GetInvestmentsEvent>((event, emit) async {
      emit(InvestmentLoading());
      try {
        final investments = await getInvestmentsUseCase.call(
          userId: event.userId,
          walletId: event.walletId,
        );

        // Toplam tutarı hesapla
        final total =
            investments.fold<double>(0, (sum, item) => sum + item.amount);

        emit(InvestmentLoaded(investments, totalAmount: total));
      } catch (e) {
        emit(InvestmentError(ErrorHandler.handleException(e).message));
      }
    });

    // Yatırım Ekle
    on<CreateInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      try {
        await addInvestmentUseCase.call(event.investment);
        await walletSyncUseCase.addInvestment(
          userId: event.userId,
          amount: event.investment.amount,
        );
        emit(const InvestmentActionSuccess('Yatırım başarıyla eklendi'));
        // Listeyi güncelle

        add(GetInvestmentsEvent(
            userId: event.userId, walletId: event.walletId));
      } catch (e) {
        emit(InvestmentError(ErrorHandler.handleException(e).message));
      }
    });

    // Yatırım Güncelle
    on<UpdateInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      try {
        await updateInvestmentUseCase.call(event.investment);
        await walletSyncUseCase.updateInvestment(
          userId: event.userId,
          prevAmount: event.prevAmount,
          newAmount: event.newAmount,
        );
        emit(const InvestmentActionSuccess('Yatırım güncellendi'));
        // Listeyi güncelle
        add(GetInvestmentsEvent(
            userId: event.userId, walletId: event.walletId));
      } catch (e) {
        emit(InvestmentError(ErrorHandler.handleException(e).message));
      }
    });

    // Yatırım Sil
    on<DeleteInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      try {
        await deleteInvestmentUseCase.call(event.id);
        await walletSyncUseCase.deleteInvestment(
          userId: event.userId,
          amount: event.amount,
        );
        emit(const InvestmentActionSuccess('Yatırım silindi'));
        // Listeyi güncelle
        add(GetInvestmentsEvent(
            userId: event.userId, walletId: event.walletId));
      } catch (e) {
        emit(InvestmentError(ErrorHandler.handleException(e).message));
      }
    });
  }
}
