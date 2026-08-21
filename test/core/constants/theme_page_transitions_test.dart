import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/navigation/predictive_slide_page_transitions_builder.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sayfa geçişleri bir dönem ÖLÜ KODDU: route'lar `CustomTransitionPage`
/// kullandığı için tema builder'ları hiç çağrılmıyordu. Bu testler seçimi
/// kilitler; sessizce kaybolursa düşer.
void main() {
  group('PageTransitionsTheme', () {
    test('her tema sayfa geçişlerini taşır', () {
      expect(ThemeNames.all, isNotEmpty);
      for (final entry in ThemeNames.all.entries) {
        expect(entry.value.pageTransitionsTheme.builders, isNotEmpty,
            reason: '${entry.key} geçiş taşımıyor');
      }
    });

    test('Android sistem jestini süren özel kayma geçişini kullanır', () {
      // Ayrıntılı davranış: predictive_slide_transitions_test.dart
      for (final theme in ThemeNames.all.values) {
        expect(
          theme.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<PredictiveSlidePageTransitionsBuilder>(),
        );
      }
    });

    test('iOS ve masaüstü Cupertino kenar-swipe kullanır', () {
      const cupertinoPlatforms = [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.windows,
      ];
      for (final theme in ThemeNames.all.values) {
        for (final platform in cupertinoPlatforms) {
          expect(
            theme.pageTransitionsTheme.builders[platform],
            isA<CupertinoPageTransitionsBuilder>(),
            reason: '$platform',
          );
        }
      }
    });

    test('tema örneği önbelleklenir (dropdown kimliği örneğe dayanıyor)', () {
      expect(identical(ThemeNames.all, ThemeNames.all), isTrue);
      expect(
        identical(ThemeNames.all[ThemeNames.sysLight],
            ThemeNames.all[ThemeNames.sysLight]),
        isTrue,
      );
    });
  });

  group('rota sayfaları temayı okur', () {
    testWidgets('MaterialPageRoute tema builder\'ını gerçekten çalıştırır',
        (tester) async {
      // `CustomTransitionPage` kullanılsaydı bu geçiş hiç oynamazdı.
      final theme = ThemeNames.all[ThemeNames.sysLight]!;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('İKİNCİ')),
              ),
            ),
            child: const Text('AÇ'),
          ),
        ),
      ));

      await tester.tap(find.text('AÇ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // Geçiş ortasında yeni sayfa ekranda ama henüz yerine oturmamış
      // olmalı: builder çalışıyor demektir.
      final mid = tester.getTopLeft(find.text('İKİNCİ'));
      await tester.pumpAndSettle();
      final settled = tester.getTopLeft(find.text('İKİNCİ'));

      expect(mid.dx, isNot(closeTo(settled.dx, 0.5)),
          reason: 'Sayfa geçiş boyunca hiç hareket etmedi');
    });
  });
}
