part of 'wallet_bloc.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object> get props => [];
}

final class WalletInitialSt extends WalletState {
  const WalletInitialSt();
}

final class WalletLoadedSt extends WalletState {
  final List<WalletModel> wallets;
  const WalletLoadedSt(this.wallets);
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
