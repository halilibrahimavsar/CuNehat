part of 'theme_bloc.dart';

sealed class ThemeState {
  final ThemeData name;
  final Map<String, ThemeData> names = ThemeNames.all;
  ThemeState(this.name);
}

final class ThemeStateLight extends ThemeState {
  ThemeStateLight() : super(ThemeData.light());
}

final class ThemeSt extends ThemeState {
  ThemeSt(super.name);
}
