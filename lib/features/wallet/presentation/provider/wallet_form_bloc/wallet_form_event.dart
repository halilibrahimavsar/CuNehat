part of 'wallet_form_bloc.dart';

// ============ EVENTS ============

sealed class WalletFormEvent extends Equatable {
  const WalletFormEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize form (for editing)
class InitializeFormEvent extends WalletFormEvent {
  final Wallet? wallet;
  const InitializeFormEvent(this.wallet);

  @override
  List<Object?> get props => [wallet];
}

/// Update form fields
class UpdateNameEvent extends WalletFormEvent {
  final String name;
  const UpdateNameEvent(this.name);

  @override
  List<Object> get props => [name];
}

class UpdateBalanceEvent extends WalletFormEvent {
  final String balance;
  const UpdateBalanceEvent(this.balance);

  @override
  List<Object> get props => [balance];
}

class UpdateColorEvent extends WalletFormEvent {
  final String colorHex;
  const UpdateColorEvent(this.colorHex);

  @override
  List<Object> get props => [colorHex];
}

class UpdateIconEvent extends WalletFormEvent {
  final String iconName;
  const UpdateIconEvent(this.iconName);

  @override
  List<Object> get props => [iconName];
}

/// Submit form
class SubmitFormEvent extends WalletFormEvent {}
