part of 'theme_bloc.dart';

sealed class ThemeEvent {
  const ThemeEvent();
}

class ThemeChangeEvent implements ThemeEvent {
  final ThemeData themeName;

  ThemeChangeEvent({required this.themeName});
}
