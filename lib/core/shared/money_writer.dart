/// Widget kuramayan yerler için gizle/göster duyarlı para metni.
///
/// [MoneyText] bir widget'tır ve tutarı `AmountVisibilityObfuscator` ile
/// sarar. Ama grafiklerde para metni bir widget değil, düz `String`'dir:
/// fl_chart'ın tooltip'i (`BarTooltipItem`, `LineTooltipItem`) ve l10n
/// şablonlarına gömülen tutarlar (`"En büyük: {ad} · {tutar}"`) widget
/// kabul etmez. Bu yüzden rapor sayfası uzun süre `formatMoney`'yi doğrudan
/// çağırdı ve gizle/göster anahtarını TAMAMEN es geçti: kullanıcı tutarları
/// gizleyip rapora kaydırdığında her sayı açıktaydı.
///
/// [MoneyWriter] iki kaynağı — aktif cüzdanın birimi ve görünürlük durumu —
/// build başında BİR KEZ okur, sonra tutarları metne çevirir. Aynı karede
/// [MoneyText] ile aynı sonucu verir, çünkü ikisi de aynı iki kaynağa bakar.
library;

import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter/widgets.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

/// Tutar görünürlüğüne widget ağacından erişim.
extension AmountVisibilityContext on BuildContext {
  /// Tutarlar görünür mü? (Uygulama çubuğundaki göz düğmesi.)
  ///
  /// `watch`: görünürlük değişince tutar yazan her şey yeniden çizilmeli.
  /// Cubit sağlanmamış bağlamlarda (yalıtılmış widget testleri) `true`'ya
  /// düşer — gizlilik hiçbir akışı KIRMAMALI, yalnız gizlemeli.
  bool get amountsVisible {
    try {
      return watch<AmountVisibilityCubit>().state;
    } on ProviderNotFoundException {
      return true;
    }
  }
}

@immutable
class MoneyWriter {
  /// Tutarların birimi — aktif cüzdanınki.
  final String currency;

  /// Tutarlar açık mı; false ise her metin maskelenir.
  final bool visible;

  const MoneyWriter({required this.currency, required this.visible});

  /// build İÇİNDEN çağrılır (iki kaynağa da `watch`/`read` ile bakar).
  factory MoneyWriter.of(BuildContext context) => MoneyWriter(
        currency: context.activeWalletCurrency,
        visible: context.amountsVisible,
      );

  /// Tam tutar: `1.234,50 ₺` / gizliyken `**** ₺`.
  String call(double amount) => visible
      ? formatMoney(amount, currency: currency)
      : hiddenMoneyText(currency);

  /// Kısaltılmış tutar (eksen etiketi, rozet): `1,2K ₺`.
  ///
  /// Gizliyken sembolsüz biçim `****` olur; maskede binlik/milyon eki
  /// TAŞINMAZ, yoksa "**K" büyüklüğü ele verirdi.
  String compact(double amount, {bool symbol = true}) {
    if (!visible) return symbol ? hiddenMoneyText(currency) : _mask;
    return formatMoneyCompact(amount, symbol: symbol, currency: currency);
  }

  /// İşaretli tutar: `+1.234,50 ₺` / `−1.234,50 ₺`.
  /// Eksi işareti U+2212 (matematiksel eksi) — tire değil.
  String withSign(double amount) =>
      '${amount >= 0 ? '+' : '−'}${call(amount.abs())}';

  static const String _mask = '****';
}
