part of 'wallet_bloc.dart';

/// Her event'in kendi ihtiyacına göre parametresi olmalı
sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object> get props => [];
}

/// Kullanıcının cüzdanlarını getir
final class GetWalletsEvent extends WalletEvent {
  final String userId;

  const GetWalletsEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Yeni cüzdan oluştur
final class CreateWalletEvent extends WalletEvent {
  final WalletEntity wallet;

  const CreateWalletEvent(this.wallet);

  @override
  List<Object> get props => [wallet];
}

/// Cüzdan güncelle
final class UpdateWalletEvent extends WalletEvent {
  final WalletEntity wallet;

  const UpdateWalletEvent(this.wallet);

  @override
  List<Object> get props => [wallet];
}

/// Cüzdan sil
final class DeleteWalletEvent extends WalletEvent {
  final String walletId;

  const DeleteWalletEvent(this.walletId);

  @override
  List<Object> get props => [walletId];
}

/// Aktif cüzdanı değiştir
final class SetActiveWalletEvent extends WalletEvent {
  final String userId;
  final String walletId;

  const SetActiveWalletEvent({
    required this.userId,
    required this.walletId,
  });

  @override
  List<Object> get props => [userId, walletId];
}
