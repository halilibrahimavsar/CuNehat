import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'credit_event.dart';
part 'credit_state.dart';

class CreditBloc extends Bloc<CreditEvent, CreditState> {
  CreditBloc() : super(CreditInitial()) {
    on<CreditEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
