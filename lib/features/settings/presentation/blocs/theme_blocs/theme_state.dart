part of 'theme_bloc.dart';

sealed class ThemeState {
  final ThemeData name;
  final Map<String, ThemeData> names = ThemeNames.all;
  ThemeState(this.name);
}

final class ThemeStateLight extends ThemeState {
  // Dropdown eşleşmesi için cache'lenmiş sysLight örneğini kullan (yeni bir
  // ThemeData.light() örneği item'larla eşleşmez ve dropdown çöker).
  ThemeStateLight() : super(ThemeNames.all[ThemeNames.sysLight]!);
}

final class ThemeSt extends ThemeState {
  ThemeSt(super.name);
}
