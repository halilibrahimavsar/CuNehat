part of 'wallet_bloc.dart';

/// Her event'in kendi ihtiyacına göre parametresi olmalı
sealed class WalletEvent extends Equatable {
  const WalletEvent();

  // Object? (Object değil): UpdateWalletEvent.baselineBalance nullable.
  @override
  List<Object?> get props => [];
}

/// Kullanıcının cüzdanlarını getir
final class GetWalletsEvent extends WalletEvent {
  final String userId;

  const GetWalletsEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Cüzdanları dinle
final class WatchWalletsEvent extends WalletEvent {
  final String userId;

  const WatchWalletsEvent(this.userId);

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

  /// Formun AÇILDIĞI andaki bakiye. Bloc, kullanıcının bakiye alanına gerçekten
  /// dokunup dokunmadığını buna göre anlar ve `openingBalance` kaydırmasını
  /// yalnız o zaman uygular (bkz. WalletBloc.UpdateWalletEvent).
  ///
  /// null geçmek "bakiye alanını yönetme" demektir: `wallet.balance` ne ise
  /// aynen yazılır ve opening'e dokunulmaz. Bakiyeyi düzenleyen her form
  /// bunu doldurmalı; aksi halde form açıkken defter değişirse kullanıcı
  /// başka bir alanı düzenlerken cüzdanı sessizce yanlış bakiyeye oturur.
  final double? baselineBalance;

  const UpdateWalletEvent(this.wallet, {this.baselineBalance});

  @override
  List<Object?> get props => [wallet, baselineBalance];
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
