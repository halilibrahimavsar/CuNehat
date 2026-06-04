import 'package:bloc/bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

@injectable
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'selected_theme';

  /// Kaydedilmiş tema, açılış titremesini önlemek için `runApp` öncesinde
  /// [preloadTheme] ile buraya yüklenir; bloc oluşturulduğunda ilk state olarak
  /// kullanılır.
  static ThemeData? _preloadedTheme;

  /// `runApp` öncesi (app_initialization) çağrılır. SharedPreferences async
  /// olduğundan temayı önceden okuyup statik alana yazar; böylece ilk frame
  /// doğru temayla çizilir (light → dark flaşı olmaz).
  static Future<void> preloadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeName = prefs.getString(_themeKey);
    if (savedThemeName != null && ThemeNames.all.containsKey(savedThemeName)) {
      _preloadedTheme = ThemeNames.all[savedThemeName];
    }
  }

  ThemeBloc()
      : super(_preloadedTheme != null
            ? ThemeSt(_preloadedTheme!)
            : ThemeStateLight()) {
    on<ThemeChangeEvent>((event, emit) async {
      // Temayı kaydet
      await _saveTheme(event.themeName);
      emit(ThemeSt(event.themeName));
    });

    on<ThemeLoadEvent>((event, emit) {
      emit(ThemeSt(event.themeName));
    });
  }

  Future<void> _saveTheme(ThemeData theme) async {
    final prefs = await SharedPreferences.getInstance();
    // Tema adını bul ve kaydet
    final themeName = ThemeNames.all.entries
        .firstWhere((entry) => entry.value == theme,
            orElse: () => MapEntry('light', ThemeData.light()))
        .key;
    await prefs.setString(_themeKey, themeName);
  }
}
