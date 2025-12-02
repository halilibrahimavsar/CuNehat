part of 'wallet_bloc.dart';

// ============ EVENTS ============
sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

/// Load all wallets
class LoadWalletsEvent extends WalletEvent {}

/// Create new wallet
class CreateWalletEvent extends WalletEvent {
  final Wallet wallet;
  const CreateWalletEvent(this.wallet);

  @override
  List<Object> get props => [wallet];
}

/// Update existing wallet
class UpdateWalletEvent extends WalletEvent {
  final Wallet wallet;
  const UpdateWalletEvent(this.wallet);

  @override
  List<Object> get props => [wallet];
}

/// Delete wallet
class DeleteWalletEvent extends WalletEvent {
  final String walletId;
  const DeleteWalletEvent(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Set active wallet
class SetActiveWalletEvent extends WalletEvent {
  final String walletId;
  const SetActiveWalletEvent(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Transfer between wallets
class TransferBetweenWalletsEvent extends WalletEvent {
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String? note;

  const TransferBetweenWalletsEvent({
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    this.note,
  });

  @override
  List<Object?> get props => [fromWalletId, toWalletId, amount, note];
}
