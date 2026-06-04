part of 'wallet_bloc.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

final class WalletInitialSt extends WalletState {
  const WalletInitialSt();
}

final class WalletLoadingSt extends WalletState {
  const WalletLoadingSt();
}

final class WalletLoadedSt extends WalletState {
  final List<WalletEntity> wallets;
  final WalletEntity? activeWallet;
  final String? message;
  final String? error;

  const WalletLoadedSt(
    this.wallets,
    this.activeWallet, {
    this.message,
    this.error,
  });

  WalletLoadedSt copyWith({
    List<WalletEntity>? wallets,
    WalletEntity? activeWallet,
    String? message,
    String? error,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return WalletLoadedSt(
      wallets ?? this.wallets,
      activeWallet ?? this.activeWallet,
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [wallets, activeWallet, message, error];
}

final class NoWalletSt extends WalletState {
  final String? message;
  final String? error;

  const NoWalletSt({this.message, this.error});

  @override
  List<Object?> get props => [message, error];
}

final class WalletErrorSt extends WalletState {
  final String err;
  const WalletErrorSt(this.err);

  @override
  List<Object?> get props => [err];
}
