part of 'theme_bloc.dart';

sealed class ThemeEvent {
  const ThemeEvent();
}

class ThemeChangeEvent implements ThemeEvent {
  final ThemeData themeName;
  ThemeChangeEvent({required this.themeName});
}

// Yeni event: Kaydedilmiş temayı yüklemek için
class ThemeLoadEvent implements ThemeEvent {
  final ThemeData themeName;
  ThemeLoadEvent({required this.themeName});
}
