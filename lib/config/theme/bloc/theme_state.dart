part of 'theme_bloc.dart';

sealed class ThemeState {
  final String name;
  const ThemeState(this.name);
}

final class ThemeSt extends ThemeState {
  ThemeSt(super.name);
}
