import 'dart:async';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/wallet/presentation/widgets/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/real_font.dart';

void main() {
  setUpAll(loadRealRoboto);

  /// Kabuğu taklit eder: 70dp üst çubuk + klavyede küçülen gövde.
  Future<void> pump(
    WidgetTester tester, {
    Future<String?> Function(double)? onStart,
    VoidCallback? onRestore,
    VoidCallback? onPrivacy,
    double textScale = 1.0,
    double keyboard = 0,
    Size size = const Size(360, 800),
    Locale locale = const Locale('tr'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeNames.all[ThemeNames.sysLight]!.copyWith(
          textTheme: ThemeNames.all[ThemeNames.sysLight]!.textTheme.apply(
            fontFamily: kRealFontFamily,
          ),
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
            size: size,
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: Scaffold(
            appBar: const PreferredSize(
              preferredSize: Size.fromHeight(70),
              child: SizedBox(height: 70),
            ),
            body: WelcomeView(
              currency: 'TRY',
              onStart: onStart ?? (_) async => null,
              onRestore: onRestore ?? () {},
              onPrivacyPolicy: onPrivacy ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final startButton = find.byKey(const ValueKey('first-run-start'));
  final balanceField = find.byKey(const ValueKey('first-run-balance'));

  group('içerik', () {
    testWidgets('tek soru, iki çıkış ve gizlilik notu', (tester) async {
      await pump(tester);

      expect(find.text("ÇuHat'a hoş geldin"), findsOneWidget);
      expect(find.text('Şu an ne kadar paran var?'), findsOneWidget);
      expect(find.text('Başla'), findsOneWidget);
      expect(find.text('Yedeğim var'), findsOneWidget);
      expect(find.text('Gizlilik Politikası'), findsOneWidget);
      // Birim, sorulmadan gösterilir.
      expect(find.text('₺'), findsOneWidget);
      // Ad, renk, ikon, kategori SORULMAZ.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('para birimi alana dokunulmadan da görünür', (tester) async {
      await pump(tester);

      // `suffixText` yalnız odakta çizilir; simge her zaman duran yuvada.
      final decoration = tester.widget<TextField>(balanceField).decoration!;
      expect(decoration.suffixText, isNull);
      expect(decoration.suffixIcon, isNotNull);
      expect(
        find.descendant(of: balanceField, matching: find.text('₺')),
        findsOneWidget,
      );
    });

    testWidgets('İngilizce yerelde de çözülür', (tester) async {
      await pump(tester, locale: const Locale('en'));

      expect(find.text('Welcome to ÇuHat'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('I have a backup'), findsOneWidget);
    });

    testWidgets('tutar alanı açılışta odaklanmaz: klavye kendiliğinden açılmaz',
        (tester) async {
      await pump(tester);

      final field = tester.widget<TextField>(balanceField);
      expect(field.autofocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });

  group('"Başla"', () {
    testWidgets('tutar boşken sıfırla başlar', (tester) async {
      final calls = <double>[];
      await pump(tester, onStart: (v) async {
        calls.add(v);
        return null;
      });

      await tester.tap(startButton);
      await tester.pump();

      expect(calls, [0.0]);
    });

    testWidgets('yazılan tutar Türkçe biçimiyle okunur', (tester) async {
      final calls = <double>[];
      await pump(tester, onStart: (v) async {
        calls.add(v);
        return null;
      });

      await tester.enterText(balanceField, '1.500,50');
      await tester.tap(startButton);
      await tester.pump();

      expect(calls, [1500.5]);
    });

    testWidgets('eksi bakiye de geçerli bir başlangıçtır', (tester) async {
      final calls = <double>[];
      await pump(tester, onStart: (v) async {
        calls.add(v);
        return null;
      });

      await tester.enterText(balanceField, '-250');
      await tester.tap(startButton);
      await tester.pump();

      expect(calls, [-250.0]);
    });

    testWidgets('klavyenin "bitti" tuşu da başlatır', (tester) async {
      final calls = <double>[];
      await pump(tester, onStart: (v) async {
        calls.add(v);
        return null;
      });

      await tester.enterText(balanceField, '100');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(calls, [100.0]);
    });

    testWidgets('kurulum sürerken düğmeler kilitlenir, ikinci dokunuş yutulur',
        (tester) async {
      final pending = Completer<String?>();
      var calls = 0;
      await pump(tester, onStart: (_) {
        calls++;
        return pending.future;
      });

      await tester.tap(startButton);
      await tester.pump();
      await tester.tap(startButton, warnIfMissed: false);
      await tester.pump();

      expect(calls, 1);
      expect(tester.widget<FilledButton>(startButton).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('first-run-restore')))
            .onPressed,
        isNull,
      );

      pending.complete(null);
      await tester.pump();
    });

    testWidgets('hata dönerse gösterilir ve yeniden denenebilir',
        (tester) async {
      var attempt = 0;
      await pump(tester, onStart: (_) async {
        attempt++;
        return attempt == 1 ? 'Cüzdan kurulamadı. Yeniden dene.' : null;
      });

      await tester.tap(startButton);
      await tester.pump();
      await tester.pump();

      expect(find.text('Cüzdan kurulamadı. Yeniden dene.'), findsOneWidget);
      expect(tester.widget<FilledButton>(startButton).onPressed, isNotNull);

      await tester.tap(startButton);
      await tester.pump();

      expect(attempt, 2);
    });
  });

  group('öteki çıkışlar', () {
    testWidgets('"Yedeğim var" geri yüklemeyi açar, cüzdan KURMAZ',
        (tester) async {
      var restores = 0;
      var starts = 0;
      await pump(
        tester,
        onRestore: () => restores++,
        onStart: (_) async {
          starts++;
          return null;
        },
      );

      await tester.tap(find.byKey(const ValueKey('first-run-restore')));
      await tester.pump();

      expect(restores, 1);
      expect(starts, 0);
    });

    testWidgets('gizlilik politikası bağlantısı çalışır', (tester) async {
      var opened = 0;
      await pump(tester, onPrivacy: () => opened++);

      await tester.tap(find.byKey(const ValueKey('first-run-privacy')));
      await tester.pump();

      expect(opened, 1);
    });
  });

  group('sığma', () {
    /// [action] boyunca çıkan düzen hatalarını toplar.
    Future<void> expectNoLayoutError(
      WidgetTester tester,
      String phase,
      Future<void> Function() action,
    ) async {
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        await action();
      } finally {
        FlutterError.onError = previous;
      }
      if (errors.isNotEmpty) fail('$phase: ${errors.first.exception}');
    }

    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('360dp, yazı ölçeği $scale: taşma yok', (tester) async {
        await expectNoLayoutError(
          tester,
          'ölçek $scale',
          () => pump(tester, textScale: scale),
        );
      });

      testWidgets(
          '360dp, yazı ölçeği $scale, klavye açık: "Başla" klavyenin üstünde',
          (tester) async {
        const keyboard = 320.0;
        await expectNoLayoutError(
          tester,
          'ölçek $scale + klavye',
          () => pump(tester, textScale: scale, keyboard: keyboard),
        );

        final rect = tester.getRect(startButton);
        expect(rect.bottom, lessThanOrEqualTo(800 - keyboard));
        expect(rect.top, greaterThanOrEqualTo(70));
        expect(rect.height, greaterThanOrEqualTo(48));
      });
    }

    testWidgets('dokunma hedefleri en az 48dp', (tester) async {
      await pump(tester);

      for (final key in const [
        'first-run-start',
        'first-run-restore',
        'first-run-privacy',
      ]) {
        final size = tester.getSize(find.byKey(ValueKey(key)));
        expect(size.height, greaterThanOrEqualTo(48), reason: key);
        expect(size.width, greaterThanOrEqualTo(48), reason: key);
      }
    });
  });
}
