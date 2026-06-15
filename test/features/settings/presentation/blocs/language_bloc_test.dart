import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/features/settings/presentation/blocs/language_bloc/language_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('LanguageBloc', () {
    blocTest<LanguageBloc, LanguageState>(
      'emits language state with new language code when LanguageChangeEvent is fired',
      build: () => LanguageBloc(),
      act: (bloc) => bloc.add(LanguageChangeEvent('en')),
      expect: () => [
        isA<LanguageState>()
            .having((s) => s.languageCode, 'languageCode', 'en'),
      ],
      verify: (bloc) {
        expect(Intl.defaultLocale, 'en');
      },
    );

    test('preloadLanguage loads saved language code from SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({
        'selected_language': 'tr',
      });

      await LanguageBloc.preloadLanguage();
      expect(Intl.defaultLocale, 'tr');
    });
  });
}
