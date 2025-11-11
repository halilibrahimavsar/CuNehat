part of 'theme_bloc.dart';

sealed class ThemeEvent {
  const ThemeEvent();
}

class ThemeChangeEvent implements ThemeEvent {
  final String themeName;

  ThemeChangeEvent({required this.themeName});
}
