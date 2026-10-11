import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Widget ağacının DIŞINDA (bloc, cubit) kullanıcıya gösterilecek metinler.
///
/// Bloc'lar hazır cümle yayınlar ve `context.l10n`'a erişemez; bu yüzden
/// başarı/hata mesajları koda gömülü Türkçeydi — uygulamayı İngilizce
/// kullanan kişi her kayıttan sonra Türkçe bir bildirim görüyordu.
///
/// Dil, uygulamanın kendi dil tercihini izleyen `Intl.defaultLocale`'den
/// çözülür: `LanguageBloc` hem açılışta (`preloadLanguage`) hem dil
/// değişiminde onu yazar; tercih yoksa 'tr'. Atanmamış ya da desteklenmeyen
/// dil Türkçeye düşer — `MaterialApp`'in ve `NotificationLocalizer`'ın
/// davranışıyla aynı.
///
/// Yeni kodda tercih edilen desen hâlâ durumun bir KOD taşıması ve metnin
/// widget'ta çözülmesidir (bkz. `InvestmentNotice`); bu erişim, hazır cümle
/// yayınlayan eski bloc'lar içindir.
AppLocalizations get appStrings {
  final code = _languageOf(Intl.defaultLocale);
  return _cache[code] ??= lookupAppLocalizations(Locale(code));
}

final _cache = <String, AppLocalizations>{};

String _languageOf(String? locale) {
  if (locale == null || locale.isEmpty) return 'tr';
  // 'tr_TR', 'en-US' → dil kodu.
  final code = locale.split(RegExp('[_-]')).first.toLowerCase();
  final supported =
      AppLocalizations.supportedLocales.any((l) => l.languageCode == code);
  return supported ? code : 'tr';
}
