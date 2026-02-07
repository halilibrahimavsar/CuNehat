part of 'wallet_bloc.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object> get props => [];
}

final class WalletLoadedSt extends WalletState {
  final List<WalletEntity> wallets;
  final WalletEntity? activeWallet;
  const WalletLoadedSt(this.wallets, this.activeWallet);
}

final class WalletErrorSt extends WalletState {
  final String err;
  const WalletErrorSt(this.err);
}

final class WalletLoadingSt extends WalletState {
  const WalletLoadingSt();
}

final class WalletOperationSuccessSt extends WalletState {
  final String message;
  const WalletOperationSuccessSt(this.message);
}

final class NoWalletSt extends WalletState {
  const NoWalletSt();
}
