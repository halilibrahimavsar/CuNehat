import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/core/texts/local_auth_texts.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import '../../support/fake_local_auth_repository.dart';
import '../../support/real_font.dart';

void main() {
  // Cihazda ölçülen taşma (sdk gphone64, 8 Eylül 2026): kilit ekranı
  // 411,4 × 603,4dp alanda 53dp taşıyordu. İçerik 656dp:
  // 16 + kart 192 + noktalar 20 + tuş takımı 360 + 8 + kurtarma 48 + 12.
  // Kurtarma bağlantısı EKLENMEDEN ÖNCE de 628dp ile 25dp taşıyordu.
  setUpAll(loadRealRoboto);

  Widget host(Widget child) => MaterialApp(
        theme: ThemeData(fontFamily: kRealFontFamily),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: child,
      );

  Future<void> pumpAt(
    WidgetTester tester,
    Widget page, {
    required Size logical,
    double textScale = 1.0,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = logical;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: host(page),
    ));
    await tester.pumpAndSettle();
  }

  Widget lockScreen(FakeLocalAuthRepository repo) => BlocProvider(
        create: (_) => LocalAuthLoginBloc(repository: repo),
        child: BiometricAuthPage(
          onSuccess: () {},
          showLogoutButton: false,
          onForgotPin: () {},
          texts: const LocalAuthTexts(),
        ),
      );

  testWidgets('kilit ekranı 411×603dp cihazda taşmaz', (tester) async {
    final repo = FakeLocalAuthRepository(bioAvailable: false, bioEnabled: false);
    await pumpAt(tester, lockScreen(repo),
        logical: const Size(411, 660));

    expect(tester.takeException(), isNull);
    // Sığmadığında KAYAR; içerik kırpılmaz.
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('kilit ekranı dar ve kısa ekranda da taşmaz', (tester) async {
    final repo = FakeLocalAuthRepository(bioAvailable: false, bioEnabled: false);
    await pumpAt(tester, lockScreen(repo), logical: const Size(320, 480));

    expect(tester.takeException(), isNull);
  });

  testWidgets('büyük yazı ölçeğinde de taşmaz', (tester) async {
    final repo = FakeLocalAuthRepository(bioAvailable: false, bioEnabled: false);
    await pumpAt(tester, lockScreen(repo),
        logical: const Size(411, 660), textScale: 1.6);

    expect(tester.takeException(), isNull);
  });

  testWidgets('kurtarma bağlantısı içerik kaydırılınca erişilebilir',
      (tester) async {
    final repo = FakeLocalAuthRepository(bioAvailable: false, bioEnabled: false);
    await pumpAt(tester, lockScreen(repo), logical: const Size(411, 660));

    await tester.drag(
        find.byType(SingleChildScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(find.text('Forgot PIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
