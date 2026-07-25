import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cunehat/core/constants/prefs_keys.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';

/// Bildirim metinleri usecase/servis katmanında, widget ağacının dışında
/// üretilir — `context.l10n` yoktur. Bu servis kayıtlı dil tercihinden
/// **senkron** bir [AppLocalizations] çözer.
///
/// Sınır: planlanmış (zamanlanmış) bir bildirimin metni planlandığı andaki
/// dilde donar. Dil değiştiğinde metinlerin de değişmesi için
/// `ReminderSyncService.syncAll()` yeniden çalıştırılır (bkz. LanguageBloc).
@lazySingleton
class NotificationLocalizer {
  final SharedPreferences _prefs;

  NotificationLocalizer(this._prefs);

  AppLocalizations get l10n {
    final code = _prefs.getString(PrefsKeys.language);
    final supported = AppLocalizations.supportedLocales
        .any((locale) => locale.languageCode == code);
    return lookupAppLocalizations(
      supported ? Locale(code!) : const Locale('tr'),
    );
  }
}
