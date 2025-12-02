part of 'wallet_bloc.dart';

// ============ STATES ============
sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class WalletInitial extends WalletState {}

/// Loading state
class WalletLoading extends WalletState {}

/// Wallets loaded successfully
class WalletsLoaded extends WalletState {
  final List<Wallet> wallets;
  final String activeWalletId;

  const WalletsLoaded({
    required this.wallets,
    required this.activeWalletId,
  });

  @override
  List<Object> get props => [wallets, activeWalletId];

  /// Helper to get active wallet
  Wallet? get activeWallet {
    try {
      return wallets.firstWhere((w) => w.id == activeWalletId);
    } catch (e) {
      return null;
    }
  }
}

/// Operation successful
class WalletOperationSuccess extends WalletState {
  final String message;
  final WalletOperationType type;

  const WalletOperationSuccess({
    required this.message,
    required this.type,
  });

  @override
  List<Object> get props => [message, type];
}

enum WalletOperationType { create, update, delete, setActive, transfer }

/// Error state
class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object> get props => [message];
}
