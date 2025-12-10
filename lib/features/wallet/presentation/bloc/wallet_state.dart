part of 'wallet_bloc.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object> get props => [];
}

final class WalletLoadedSt extends WalletState {
  final List<WalletModel> wallets;
  final WalletModel? activeWallet;
  const WalletLoadedSt(this.wallets, this.activeWallet);
}

final class WalletErrorSt extends WalletState {
  final String err;
  const WalletErrorSt(this.err);
}

final class WalletLoadingSt extends WalletState {
  const WalletLoadingSt();
}

final class WalletCreatedSt extends WalletState {
  const WalletCreatedSt();
}

final class WalletDeletedSt extends WalletState {
  const WalletDeletedSt();
}

final class WalletUpdatedSt extends WalletState {
  const WalletUpdatedSt();
}

final class NoWalletSt extends WalletState {
  const NoWalletSt();
}
