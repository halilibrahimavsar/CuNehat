import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Aktif cüzdanın para birimine widget ağacından erişim.
///
/// Uygulama tek aktif cüzdan üzerinden çalıştığından görünümdeki tüm
/// tutarlar bu birimdedir. WalletBloc app-genelinde sağlanır; sayfalar
/// cüzdan değişiminde ValueKey('..-walletId') ile yeniden kurulduğundan
/// ve birim yalnız boş cüzdanda değiştirilebildiğinden `read` yeterlidir
/// (dinlemeye gerek yok).
extension ActiveWalletCurrencyX on BuildContext {
  /// Aktif cüzdanın para birimi; cüzdan yüklü değilse TRY.
  /// WalletBloc sağlanmamış bağlamlarda (ör. yalıtılmış widget testleri)
  /// TRY'ye düşer — birim gösterimi hiçbir akışı kırmamalı.
  String get activeWalletCurrency {
    try {
      final s = read<WalletBloc>().state;
      return s is WalletLoadedSt
          ? (s.activeWallet?.currency ?? kDefaultCurrency)
          : kDefaultCurrency;
    } on ProviderNotFoundException {
      return kDefaultCurrency;
    }
  }

  /// Aktif birimin sembolü ('₺' | '\$' | '€').
  String get activeWalletCurrencySymbol => currencySymbol(activeWalletCurrency);

  /// [walletId]'nin CANLI bakiyesi; cüzdan (ya da WalletBloc) yoksa null.
  ///
  /// Birimin aksine bakiye her para mutasyonunda değişir — bu yüzden `read`
  /// değil `watch`: bakiyeye çapalanan hesaplar (defterdeki "işlem sonrası
  /// bakiye") işlem eklendiğinde/silindiğinde yeniden çizilmeli. Yalnız
  /// `build` içinden çağrılabilir.
  double? watchWalletBalance(String walletId) {
    try {
      final s = watch<WalletBloc>().state;
      if (s is! WalletLoadedSt) return null;
      for (final w in s.wallets) {
        if (w.id == walletId) return w.balance;
      }
      return null;
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// id'ye göre cüzdan. Cüzdanlar-arası (global) listelerde — ör. düzenli
  /// işlem şablonları — kaydın ait olduğu cüzdanın adını/birimini göstermek
  /// için. Cüzdan bulunamazsa veya WalletBloc yüklü değilse null.
  WalletEntity? walletById(String walletId) {
    try {
      final s = read<WalletBloc>().state;
      if (s is! WalletLoadedSt) return null;
      for (final w in s.wallets) {
        if (w.id == walletId) return w;
      }
      return null;
    } on ProviderNotFoundException {
      return null;
    }
  }
}
