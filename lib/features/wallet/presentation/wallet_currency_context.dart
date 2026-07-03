import 'package:cunehat/core/utils/currencies.dart';
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
}
