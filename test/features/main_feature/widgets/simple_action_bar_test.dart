import 'dart:math' as math;

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/main_feature/widgets/simple_action_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/real_font.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  setUpAll(loadRealRoboto);

  final income = find.byKey(const ValueKey('simple-bar-income'));
  final expense = find.byKey(const ValueKey('simple-bar-expense'));
  final more = find.byKey(const ValueKey('simple-bar-more'));

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onIncome,
    VoidCallback? onExpense,
    VoidCallback? onMore,
    bool moreActive = false,
    String themeName = ThemeNames.sysLight,
    double textScale = 1.0,
    double width = 360,
    Locale locale = const Locale('tr'),
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final theme = ThemeNames.all[themeName]!;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: kRealFontFamily),
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Column(
              children: [
                const Spacer(),
                SimpleActionBar(
                  onIncome: onIncome ?? () {},
                  onExpense: onExpense ?? () {},
                  onMore: onMore ?? () {},
                  moreActive: moreActive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('jest yok: her düğme ne yaptığını yazıyla söyler', () {
    testWidgets('Gelir ve Gider YAZILI düğmelerdir', (tester) async {
      await pump(tester);

      expect(find.descendant(of: income, matching: find.text('Gelir')),
          findsOneWidget);
      expect(find.descendant(of: expense, matching: find.text('Gider')),
          findsOneWidget);
    });

    testWidgets('her düğme kendi işini yapar', (tester) async {
      final calls = <String>[];
      await pump(
        tester,
        onIncome: () => calls.add('gelir'),
        onExpense: () => calls.add('gider'),
        onMore: () => calls.add('daha'),
      );

      await tester.tap(expense);
      await tester.tap(income);
      await tester.tap(more);

      expect(calls, ['gider', 'gelir', 'daha']);
    });

    testWidgets('üçüncü düğme ekran okuyucuya adını söyler', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(find.bySemanticsLabel('İçgörü ve rapor'), findsWidgets);
      expect(find.byTooltip('İçgörü ve rapor'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('İngilizce yerelde de çözülür', (tester) async {
      await pump(tester, locale: const Locale('en'));

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('alt sayfa açıkken üçüncü düğme dolu çizilir', (tester) async {
      await pump(tester, moreActive: true);
      final scheme = ThemeNames.all[ThemeNames.sysLight]!.colorScheme;

      expect(tester.widget<Material>(more).color, scheme.primary);

      await pump(tester);
      expect(tester.widget<Material>(more).color, isNot(scheme.primary));
    });
  });

  group('erişilebilirlik', () {
    testWidgets('üç dokunma hedefi de en az 48dp (burada 56)', (tester) async {
      await pump(tester);

      for (final finder in [income, expense, more]) {
        final size = tester.getSize(finder);
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
      expect(tester.getSize(expense).height, SimpleActionBar.buttonHeight);
    });

    testWidgets('Gelir ve Gider eşit genişliktedir', (tester) async {
      await pump(tester);

      expect(tester.getSize(income).width, tester.getSize(expense).width);
    });

    for (final themeName in [ThemeNames.sysLight, ThemeNames.sysDark]) {
      test('$themeName: düğme yazısı kendi zemininde okunur (4,5:1)', () {
        final theme = ThemeNames.all[themeName]!;
        final dark = theme.brightness == Brightness.dark;

        Color background(Color tint) => Color.alphaBlend(
              tint.withValues(alpha: SimpleActionBar.tintAlpha),
              theme.colorScheme.surface,
            );

        expect(
          _contrast(
            dark ? AppPalette.incomeOnTintDark : AppPalette.incomeOnTintLight,
            background(AppGradients.savings),
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(
            dark ? AppPalette.expenseOnTintDark : AppPalette.expenseOnTintLight,
            background(AppGradients.debt),
          ),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('sığma', () {
    for (final width in const [320.0, 360.0]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        testWidgets('${width.toInt()}dp, yazı ölçeği $scale: taşma yok',
            (tester) async {
          final errors = <FlutterErrorDetails>[];
          final previous = FlutterError.onError;
          FlutterError.onError = errors.add;
          try {
            await pump(tester, width: width, textScale: scale);
          } finally {
            FlutterError.onError = previous;
          }
          expect(errors, isEmpty,
              reason: errors.isEmpty ? '' : '${errors.first.exception}');
          // Etiketler kırpılsa bile düğmeler yerinde ve dokunulabilir.
          expect(tester.getSize(income).width, greaterThan(48));
        });
      }
    }
  });
}
