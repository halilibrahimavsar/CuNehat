part of 'theme_bloc.dart';

sealed class ThemeState {
  final ThemeData name;
  final Map<String, ThemeData> names = {
    "Sistem [Acık]": ThemeData.light(),
    "Sistem [Kapalı]": ThemeData.dark(),
    "Glass Morphism": CustomeAppThemes.glassTheme,
    "Neo Morphism": CustomeAppThemes.neoTheme,
  };
  ThemeState(this.name);
}

final class ThemeStateLight extends ThemeState {
  ThemeStateLight() : super(ThemeData.light());
}

final class ThemeSt extends ThemeState {
  ThemeSt(super.name);
}
