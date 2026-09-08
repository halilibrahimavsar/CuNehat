import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/routes/gorouting.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:cunehat/features/settings/presentation/page/pin_recovery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import '../../support/fake_local_auth_repository.dart';

void main() {
  late FakeLocalAuthRepository repo;
  late SharedPreferences prefs;
  late AppAuthBloc authBloc;

  setUpAll(() => getIt.allowReassignment = true);

  Future<void> lockApp() async {
    authBloc = AppAuthBloc(
      localAuthRepository: repo,
      sharedPreferences: prefs,
      systemActivityGuard: SystemActivityGuard(),
    );
    // Kilit durumu GERÇEK zamanda otursun. `testWidgets` gövdesi FakeAsync
    // içinde çalışır; orada beklenen bir "gerçek zaman" Future'ı asla
    // tamamlanmaz ve test sonsuza kilitlenir.
    if (authBloc.state is! AppAuthLocked) {
      await authBloc.stream.firstWhere((s) => s is AppAuthLocked);
    }
  }

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    repo = FakeLocalAuthRepository(
      pinSet: true,
      bioEnabled: false,
      bioAvailable: false,
      backgroundTimeout: 0,
    );
    getIt.registerSingleton<LocalAuthRepository>(repo);
    getIt.registerFactory<LocalAuthLoginBloc>(
      () => LocalAuthLoginBloc(repository: repo),
    );

    await lockApp();
  });

  tearDown(() async {
    await authBloc.close();
    await getIt.reset();
  });

  Future<void> pumpLockedApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: createAppRouter(authBloc),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> enterPin(WidgetTester tester, List<String> digits) async {
    for (final digit in digits) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('kilit ekranında ölü "Çıkış Yap" yerine kurtarma girişi var',
      (tester) async {
    await pumpLockedApp(tester);

    expect(find.byType(BiometricAuthPage), findsOneWidget);
    // Eski düğme hiçbir şey yapmıyordu; PIN'ini unutan kullanıcı ona basıyordu.
    expect(find.text('Çıkış Yap'), findsNothing);
    expect(find.byIcon(Icons.logout_rounded), findsNothing);
    expect(find.text("PIN'imi unuttum"), findsOneWidget);
  });

  testWidgets('kurtarma girişi kilitliyken de açılır (router geri atmaz)',
      (tester) async {
    await pumpLockedApp(tester);

    await tester.tap(find.text("PIN'imi unuttum"));
    await tester.pumpAndSettle();

    // Router kilitliyken TÜM konumları /lock'a yönlendirdiği için kurtarma
    // sayfası bir GoRouter rotası DEĞİL; imperatif açılır.
    expect(find.byType(PinRecoveryPage), findsOneWidget);
    expect(find.text('Telefon kilidiyle doğrula'), findsOneWidget);
  });

  testWidgets('cihaz kilidiyle doğrulayan kullanıcı yeni PIN belirleyebilir',
      (tester) async {
    await pumpLockedApp(tester);
    await tester.tap(find.text("PIN'imi unuttum"));
    await tester.pumpAndSettle();

    // Doğrulamadan önce sıfırlama düğmesi YOK.
    expect(find.text('Yeni PIN belirle'), findsNothing);

    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yeni PIN belirle'));
    await tester.pumpAndSettle();

    await enterPin(tester, ['9', '8', '7', '6', '5', '4']);
    await enterPin(tester, ['9', '8', '7', '6', '5', '4']);

    expect(repo.savedPin, '987654');
    expect(find.byType(PinRecoveryPage), findsNothing);
    // Kurtarma yalnız kimlik bilgisini değiştirir: kilit hâlâ açılmadı.
    expect(find.byType(BiometricAuthPage), findsOneWidget);
  });

  testWidgets('cihaz kilidi doğrulanmazsa PIN yazılmaz', (tester) async {
    repo.deviceCredentialResult = false;
    await pumpLockedApp(tester);
    await tester.tap(find.text("PIN'imi unuttum"));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();

    expect(find.text('Yeni PIN belirle'), findsNothing);
    expect(repo.savedPin, isNull);
  });

  testWidgets('ekran kilidi olmayan cihazda gecikmeli sıfırlama sunulur',
      (tester) async {
    repo.deviceCredentialAvailable = false;
    await pumpLockedApp(tester);
    await tester.tap(find.text("PIN'imi unuttum"));
    await tester.pumpAndSettle();

    expect(find.text('Doğrula'), findsNothing);

    await tester.tap(find.text('Sıfırlama isteği başlat'));
    await tester.pumpAndSettle();

    expect(repo.pinResetRequestedAt, isNotNull);
    // Bekleme dolmadan sıfırlanamaz.
    expect(find.text('Yeni PIN belirle'), findsNothing);
    expect(find.text('İsteği iptal et'), findsOneWidget);
  });
}
