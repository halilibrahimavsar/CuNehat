import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cunehat/core/constants/prefs_keys.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';

part 'language_event.dart';
part 'language_state.dart';

@injectable
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static String? _preloadedLanguage;

  final ReminderSyncService _reminderSync;

  static Future<void> preloadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(PrefsKeys.language);
    if (savedLanguage != null) {
      _preloadedLanguage = savedLanguage;
      Intl.defaultLocale = savedLanguage;
    } else {
      Intl.defaultLocale = 'tr';
    }
  }

  LanguageBloc(this._reminderSync)
      : super(LanguageState(_preloadedLanguage ?? 'tr')) {
    on<LanguageChangeEvent>((event, emit) async {
      await _saveLanguage(event.languageCode);
      Intl.defaultLocale = event.languageCode;
      emit(LanguageState(event.languageCode));

      // Planlanmış bildirimlerin metni planlandıkları andaki dilde donar;
      // dil değişince yeniden kurulmaları gerekir. Etkileşimi bloklamasın.
      unawaited(_reminderSync.syncAll());
    });

    on<LanguageLoadEvent>((event, emit) {
      // Reload logic if needed
    });
  }

  Future<void> _saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.language, languageCode);
  }
}
