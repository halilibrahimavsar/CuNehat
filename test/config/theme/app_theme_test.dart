import 'dart:math' as math;

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/config/theme/app_theme.dart';
import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x göreli parlaklık.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final themes = {
    'açık': ThemeNames.all[ThemeNames.sysLight]!,
    'koyu': ThemeNames.all[ThemeNames.sysDark]!,
  };

  group('tema Flutter varsayılanı değil, uygulamanın kendisi', () {
    test('primary markanın tonudur (eskiden Material varsayılan moruydu)', () {
      expect(
        themes['açık']!.colorScheme.primary,
        AppPalette.brandOnLight,
      );
      expect(themes['koyu']!.colorScheme.primary, AppPalette.brandOnDark);
      // Varsayılan şemanın moru: geri dönerse düşsün.
      expect(
        themes['açık']!.colorScheme.primary,
        isNot(ThemeData.light().colorScheme.primary),
      );
    });

    test('marka mavisi bölüm mavisiyle aynı ailedendir', () {
      expect(AppPalette.brand, AppGradients.transactions);
    });

    for (final entry in themes.entries) {
      test('${entry.key}: yüzey jetonu taşır, kart zemini sayfadan ayrışır',
          () {
        final theme = entry.value;
        final surface = theme.extension<AppSurface>();
        expect(surface, isNotNull);
        expect(surface!.baseColor, isNot(theme.colorScheme.surface));
        expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
        expect(theme.cardColor, surface.baseColor);
      });

      test('${entry.key}: Material 3 yüzey tonlaması kapalı', () {
        expect(entry.value.colorScheme.surfaceTint, Colors.transparent);
      });
    }
  });

  group('okunabilirlik (WCAG AA: metin 4,5:1, arayüz öğesi 3:1)', () {
    for (final entry in themes.entries) {
      final scheme = entry.value.colorScheme;
      final card = entry.value.extension<AppSurface>()!.baseColor;

      test('${entry.key}: gövde metni sayfa ve kart zemininde okunur', () {
        expect(_contrast(scheme.onSurface, scheme.surface), greaterThan(7));
        expect(_contrast(scheme.onSurface, card), greaterThan(7));
      });

      test('${entry.key}: ikincil metin sayfa ve kart zemininde okunur', () {
        expect(
          _contrast(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(scheme.onSurfaceVariant, card),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('${entry.key}: marka rengi metin olarak okunur', () {
        expect(
          _contrast(scheme.primary, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(scheme.primary, card), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: dolu düğmenin yazısı okunur', () {
        expect(
          _contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('${entry.key}: hata metni okunur', () {
        expect(
          _contrast(scheme.error, scheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(scheme.error, card), greaterThanOrEqualTo(4.5));
      });

      test('${entry.key}: çerçeve rengi zeminden ayrışır', () {
        expect(
          _contrast(scheme.outline, scheme.surface),
          greaterThanOrEqualTo(3),
        );
      });
    }
  });

  group('yazı ölçeği', () {
    test('bütün roller altı boyuttan birini kullanır', () {
      const t = AppTheme.textTheme;
      final roles = <String, TextStyle?>{
        'displayLarge': t.displayLarge,
        'displayMedium': t.displayMedium,
        'displaySmall': t.displaySmall,
        'headlineLarge': t.headlineLarge,
        'headlineMedium': t.headlineMedium,
        'headlineSmall': t.headlineSmall,
        'titleLarge': t.titleLarge,
        'titleMedium': t.titleMedium,
        'titleSmall': t.titleSmall,
        'bodyLarge': t.bodyLarge,
        'bodyMedium': t.bodyMedium,
        'bodySmall': t.bodySmall,
        'labelLarge': t.labelLarge,
        'labelMedium': t.labelMedium,
        'labelSmall': t.labelSmall,
      };
      for (final role in roles.entries) {
        expect(role.value, isNotNull, reason: role.key);
        expect(AppType.sizes, contains(role.value!.fontSize), reason: role.key);
        expect(
          [AppType.regular, AppType.medium, AppType.strong],
          contains(role.value!.fontWeight),
          reason: role.key,
        );
      }
    });

    test('tema, roller için ölçeği gerçekten uygular', () {
      final theme = themes['açık']!;
      expect(theme.textTheme.bodyMedium!.fontSize, AppType.body);
      expect(theme.textTheme.titleLarge!.fontSize, AppType.title);
      expect(theme.textTheme.bodyMedium!.color, theme.colorScheme.onSurface);
    });
  });

  group('AppCard nötrdür; renkli zemin açıkça istenir', () {
    Future<BoxDecoration> pumpCard(
      WidgetTester tester, {
      Color? accent,
      bool emphasized = false,
      bool selected = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: themes['açık'],
          home: Scaffold(
            body: AppCard(
              accent: accent,
              emphasized: emphasized,
              selected: selected,
              child: const SizedBox(width: 100, height: 40),
            ),
          ),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AppCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return box.decoration as BoxDecoration;
    }

    testWidgets('accent verilen kart zemini BOYAMAZ', (tester) async {
      final d = await pumpCard(tester, accent: AppGradients.savings);
      expect(d.gradient, isNull);
      expect(d.color, AppSurface.light.baseColor);
      expect((d.border! as Border).top.color, AppSurface.light.borderColor);
      // Tek gölge: ortam gölgesi. Parıltı yok.
      expect(d.boxShadow, hasLength(AppSurface.light.ambientShadow.length));
    });

    testWidgets('emphasized kart accent gradyanı alır', (tester) async {
      final d = await pumpCard(
        tester,
        accent: AppGradients.savings,
        emphasized: true,
      );
      expect(d.gradient, isNotNull);
      expect(d.color, isNull);
    });

    testWidgets('emphasized, accent yoksa etkisizdir', (tester) async {
      final d = await pumpCard(tester, emphasized: true);
      expect(d.gradient, isNull);
      expect(d.color, AppSurface.light.baseColor);
    });

    testWidgets('seçili kart nötr zeminde accent çerçeve taşır',
        (tester) async {
      final d = await pumpCard(
        tester,
        accent: AppGradients.transactions,
        selected: true,
      );
      expect(d.gradient, isNull);
      final border = (d.border! as Border).top;
      expect(border.width, greaterThan(2));
      expect(border.color, isNot(AppSurface.light.borderColor));
    });

    testWidgets('köşe yarıçapı kart jetonudur', (tester) async {
      final d = await pumpCard(tester);
      expect(d.borderRadius, BorderRadius.circular(AppRadius.card));
    });
  });
}
