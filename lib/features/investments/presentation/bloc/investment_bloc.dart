import 'package:bloc/bloc.dart';
import 'package:cunehat/core/utils/error_handler.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:equatable/equatable.dart';

part 'investment_event.dart';
part 'investment_state.dart';

class InvestmentBloc extends Bloc<InvestmentEvent, InvestmentState> {
  final GetInvestmentsUseCase getInvestmentsUseCase;
  final AddInvestmentUseCase addInvestmentUseCase;
  final UpdateInvestmentUseCase updateInvestmentUseCase;
  final DeleteInvestmentUseCase deleteInvestmentUseCase;

  InvestmentBloc({
    required this.getInvestmentsUseCase,
    required this.addInvestmentUseCase,
    required this.updateInvestmentUseCase,
    required this.deleteInvestmentUseCase,
  }) : super(InvestmentInitial()) {
    // Yatırımları Getir
    on<GetInvestmentsEvent>((event, emit) async {
      emit(InvestmentLoading());
      try {
        final investments = await getInvestmentsUseCase.call();

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
        emit(const InvestmentOperationSuccess('Yatırım başarıyla eklendi'));
        // Listeyi güncelle
        add(GetInvestmentsEvent());
      } catch (e) {
        emit(InvestmentError(ErrorHandler.handleException(e).message));
      }
    });

    // Yatırım Güncelle
    on<UpdateInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      try {
        await updateInvestmentUseCase.call(event.investment);
        emit(const InvestmentOperationSuccess('Yatırım güncellendi'));
        // Listeyi güncelle
        add(GetInvestmentsEvent());
      } catch (e) {
        emit(InvestmentError(ErrorHandler.handleException(e).message));
      }
    });

    // Yatırım Sil
    on<DeleteInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      try {
        await deleteInvestmentUseCase.call(event.id);
        emit(const InvestmentOperationSuccess('Yatırım silindi'));
        // Listeyi güncelle
        add(GetInvestmentsEvent());
      } catch (e) {
        emit(InvestmentError(ErrorHandler.handleException(e).message));
      }
    });
  }
}
