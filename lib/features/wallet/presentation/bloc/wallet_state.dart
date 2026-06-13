part of 'wallet_bloc.dart';

/// Widget katmanında l10n ile çevrilen cüzdan operasyon mesajları.
/// BLoC'ta string yerine typed mesaj kullanılır; dil bağımsızlığı bu şekilde sağlanır.
enum WalletMessageType {
  created,
  updated,
  deleted,
  selected,
  createFailed,
  updateFailed,
  deleteFailed,
  selectFailed,
  activeSetFailed,
}

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
  final WalletMessageType? messageType;
  final String? message;
  final String? error;

  const WalletLoadedSt(
    this.wallets,
    this.activeWallet, {
    this.messageType,
    this.message,
    this.error,
  });

  WalletLoadedSt copyWith({
    List<WalletEntity>? wallets,
    WalletEntity? activeWallet,
    WalletMessageType? messageType,
    String? message,
    String? error,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return WalletLoadedSt(
      wallets ?? this.wallets,
      activeWallet ?? this.activeWallet,
      messageType: clearMessage ? null : (messageType ?? this.messageType),
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [wallets, activeWallet, messageType, message, error];
}

final class NoWalletSt extends WalletState {
  final WalletMessageType? messageType;
  final String? message;
  final String? error;

  const NoWalletSt({this.messageType, this.message, this.error});

  @override
  List<Object?> get props => [messageType, message, error];
}

final class WalletErrorSt extends WalletState {
  final String err;
  const WalletErrorSt(this.err);

  @override
  List<Object?> get props => [err];
}
