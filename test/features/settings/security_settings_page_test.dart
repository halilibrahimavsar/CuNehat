import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/settings/presentation/page/pin_recovery_page.dart';
import 'package:cunehat/features/settings/presentation/page/security_settings_page.dart';
import 'package:cunehat/features/settings/presentation/widgets/security/pin_entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import '../../support/fake_local_auth_repository.dart';

void main() {
  late FakeLocalAuthRepository repo;

  setUpAll(() => getIt.allowReassignment = true);

  setUp(() {
    repo = FakeLocalAuthRepository(
      pinSet: false,
      bioEnabled: false,
      bioAvailable: true,
      backgroundTimeout: 0,
    );
    getIt.registerSingleton<LocalAuthRepository>(repo);
    getIt.registerFactory<LocalAuthSettingsBloc>(
      () => LocalAuthSettingsBloc(repository: repo),
    );
  });

  tearDown(() => getIt.reset());

  Widget host({Locale locale = const Locale('tr')}) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: locale,
        home: const SecuritySettingsPage(),
      );

  Future<void> openPage(WidgetTester tester,
      {Locale locale = const Locale('tr')}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(locale: locale));
    await tester.pumpAndSettle();
  }

  /// Sayfa uzun; alt bölümler katlanmanın altında kalıyor.
  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  testWidgets('ekran tamamen Türkçe: bölümler ve kartlar', (tester) async {
    await openPage(tester);

    expect(find.text('Güvenlik'), findsWidgets);
    expect(find.text('Kilit'), findsOneWidget);
    expect(find.text('PIN kodu'), findsOneWidget);
    expect(find.text('Biyometrik Giriş'), findsOneWidget);

    await scrollToBottom(tester);
    expect(find.text('Gizlilik'), findsOneWidget);
    expect(find.text('Gizlilik perdesi'), findsOneWidget);
    expect(find.text('Arka Plan Kilidi'), findsOneWidget);
    expect(find.text('Kurtarma'), findsOneWidget);
    expect(find.text("PIN'imi unutursam"), findsOneWidget);
  });

  testWidgets('hiçbir görünür yazı İngilizce kalmıyor', (tester) async {
    await openPage(tester);
    await scrollToBottom(tester);

    // Eski pakette koda gömülü kalan etiketler.
    for (final leak in [
      'PIN (6 digits)',
      'Confirm PIN',
      'Current PIN',
      'New PIN',
      'Confirm New PIN',
      'Verify',
      'Background Lock',
      'Privacy Guard',
      'Security Settings',
    ]) {
      expect(find.text(leak), findsNothing, reason: '"$leak" İngilizce kaldı');
    }
  });

  testWidgets('PIN yokken yalnız "PIN Oluştur" sunulur', (tester) async {
    await openPage(tester);

    expect(find.text('PIN Oluştur'), findsOneWidget);
    expect(find.text('PIN Değiştir'), findsNothing);
    expect(find.text('PIN Kaldır'), findsNothing);
  });

  testWidgets('PIN varken değiştir/kaldır sunulur', (tester) async {
    repo.pinSet = true;
    await openPage(tester);

    expect(find.text('PIN Değiştir'), findsOneWidget);
    expect(find.text('PIN Kaldır'), findsOneWidget);
    expect(find.text('PIN Oluştur'), findsNothing);
  });

  testWidgets('PIN yokken biyometrik anahtarı kapalı ve pasif', (tester) async {
    await openPage(tester);

    final toggle = tester.widget<Switch>(find.byType(Switch).first);
    expect(toggle.onChanged, isNull, reason: 'PIN olmadan açılamamalı');
    expect(
        find.text(
            'Biyometrik girişi etkinleştirmek için önce bir PIN oluşturun.'),
        findsOneWidget);
  });

  testWidgets('PIN oluşturma akışı: iki adım, tuş takımıyla', (tester) async {
    await openPage(tester);

    await tester.tap(find.text('PIN Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byType(PinEntryPage), findsOneWidget);
    expect(find.text('Yeni PIN'), findsOneWidget);

    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // İkinci adım: doğrulama
    expect(find.text("PIN'i tekrar gir"), findsOneWidget);
    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(repo.savedPin, '123456');
  });

  testWidgets('eşleşmeyen doğrulama PIN yazmaz ve ilk adıma döner',
      (tester) async {
    await openPage(tester);

    await tester.tap(find.text('PIN Oluştur'));
    await tester.pumpAndSettle();

    for (final digit in ['1', '1', '1', '1', '1', '1']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    for (final digit in ['2', '2', '2', '2', '2', '2']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(repo.savedPin, isNull);
    expect(find.text("PIN'ler eşleşmedi, tekrar dene"), findsOneWidget);
    // Kullanıcı ilk PIN'i göremediği için doğrulama değil, BAŞTAN sorulmalı.
    expect(find.text('Yeni PIN'), findsOneWidget);
  });

  testWidgets('kurtarma kartı kurtarma sayfasını açar', (tester) async {
    await openPage(tester);
    await scrollToBottom(tester);

    await tester.tap(find.text("PIN'imi unutursam"));
    await tester.pumpAndSettle();

    expect(find.byType(PinRecoveryPage), findsOneWidget);
    expect(find.text('Telefon kilidiyle doğrula'), findsOneWidget);
    expect(find.text('Gecikmeli sıfırlama'), findsOneWidget);
  });
}
