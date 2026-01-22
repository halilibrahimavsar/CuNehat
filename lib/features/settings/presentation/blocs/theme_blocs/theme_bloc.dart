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

  ThemeBloc() : super(ThemeStateLight()) {
    // Uygulama açıldığında kaydedilmiş temayı yükle
    _loadSavedTheme();

    on<ThemeChangeEvent>((event, emit) async {
      // Temayı kaydet
      await _saveTheme(event.themeName);
      emit(ThemeSt(event.themeName));
    });

    on<ThemeLoadEvent>((event, emit) {
      emit(ThemeSt(event.themeName));
    });
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeName = prefs.getString(_themeKey);

    if (savedThemeName != null && ThemeNames.all.containsKey(savedThemeName)) {
      add(ThemeLoadEvent(themeName: ThemeNames.all[savedThemeName]!));
    }
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
