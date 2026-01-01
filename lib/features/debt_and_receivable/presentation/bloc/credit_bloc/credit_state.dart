part of 'credit_bloc.dart';

sealed class CreditState extends Equatable {
  const CreditState();
  
  @override
  List<Object> get props => [];
}

final class CreditInitial extends CreditState {}
