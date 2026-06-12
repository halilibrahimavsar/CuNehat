import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'language_event.dart';
part 'language_state.dart';

@injectable
class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static const String _languageKey = 'selected_language';

  static String? _preloadedLanguage;

  static Future<void> preloadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);
    if (savedLanguage != null) {
      _preloadedLanguage = savedLanguage;
    }
  }

  LanguageBloc() : super(LanguageState(_preloadedLanguage ?? 'tr')) {
    on<LanguageChangeEvent>((event, emit) async {
      await _saveLanguage(event.languageCode);
      emit(LanguageState(event.languageCode));
    });

    on<LanguageLoadEvent>((event, emit) {
      // Reload logic if needed
    });
  }

  Future<void> _saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
}
