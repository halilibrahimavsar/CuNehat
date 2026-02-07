part of 'wallet_bloc.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

final class WalletLoadedSt extends WalletState {
  final List<WalletEntity> wallets;
  final WalletEntity? activeWallet;
  const WalletLoadedSt(this.wallets, this.activeWallet);

  @override
  List<Object?> get props => [wallets, activeWallet];
}

final class WalletErrorSt extends WalletState {
  final String err;
  const WalletErrorSt(this.err);

  @override
  List<Object?> get props => [err];
}

final class WalletLoadingSt extends WalletState {
  const WalletLoadingSt();
}

final class WalletOperationSuccessSt extends WalletState {
  final String message;
  const WalletOperationSuccessSt(this.message);

  @override
  List<Object?> get props => [message];
}

final class NoWalletSt extends WalletState {
  const NoWalletSt();
}
