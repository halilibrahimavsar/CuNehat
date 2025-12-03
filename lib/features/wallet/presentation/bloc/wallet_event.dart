part of 'wallet_bloc.dart';

sealed class WalletEvent extends Equatable {
  const WalletEvent(this.wallet);
  final WalletModel wallet;

  @override
  List<Object> get props => [wallet];
}

final class DeleteEvent extends WalletEvent {
  final String walletId;

  const DeleteEvent(super.wallet, {required this.walletId});
}

final class UpdateEvent extends WalletEvent {
  const UpdateEvent(super.wallet);
}

final class LoadEvent extends WalletEvent {
  const LoadEvent(super.wallet);
}

final class CreateEvent extends WalletEvent {
  const CreateEvent(super.wallet);
}

final class GetEvent extends WalletEvent {
  const GetEvent(super.wallet);
}
