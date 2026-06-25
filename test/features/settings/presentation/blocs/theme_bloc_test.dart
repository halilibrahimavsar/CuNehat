import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  final lightTheme = ThemeNames.all[ThemeNames.sysLight]!;
  final darkTheme = ThemeNames.all[ThemeNames.sysDark]!;

  group('ThemeBloc', () {
    blocTest<ThemeBloc, ThemeState>(
      'emits ThemeSt with new theme when ThemeChangeEvent is fired',
      build: () => ThemeBloc(),
      act: (bloc) => bloc.add(ThemeChangeEvent(themeName: darkTheme)),
      expect: () => [
        isA<ThemeSt>().having((s) => s.name, 'name', darkTheme),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'emits ThemeSt with loaded theme when ThemeLoadEvent is fired',
      build: () => ThemeBloc(),
      act: (bloc) => bloc.add(ThemeLoadEvent(themeName: lightTheme)),
      expect: () => [
        isA<ThemeSt>().having((s) => s.name, 'name', lightTheme),
      ],
    );

    test('preloadTheme loads saved theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'selected_theme': ThemeNames.sysDark,
      });

      await ThemeBloc.preloadTheme();
      // ThemeBloc should use the preloaded static field
      final bloc = ThemeBloc();
      expect(bloc.state.name, darkTheme);
      bloc.close();
    });
  });
}
