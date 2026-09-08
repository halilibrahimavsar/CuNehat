import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

import '../../support/fake_local_auth_repository.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// [CuNehatApp] kabuğunun kilitle ilgili bileşimi: güvenlik katmanı +
  /// `AppAuthLocked` olduğunda `/lock` rotası (bkz. `createAppRouter`).
  Widget buildShell({
    required AppAuthBloc authBloc,
    required LocalAuthRepository repository,
  }) {
    return BlocProvider<AppAuthBloc>.value(
      value: authBloc,
      child: MaterialApp(
        builder: (context, child) => LocalAuthSecurityLayer(
          repository: repository,
          enableBackgroundLock: false,
          child: child!,
        ),
        home: BlocBuilder<AppAuthBloc, AppAuthState>(
          builder: (context, state) {
            if (state is AppAuthLocked) {
              return BlocProvider<LocalAuthLoginBloc>(
                create: (_) => LocalAuthLoginBloc(repository: repository),
                child: BiometricAuthPage(
                  onSuccess: () =>
                      authBloc.add(AppAuthUnlockRequested(state.user)),
                  showLogoutButton: false,
                ),
              );
            }
            return const Scaffold(body: Center(child: Text('home')));
          },
        ),
      ),
    );
  }

  testWidgets('tek kilit açma turunda biyometrik YALNIZ BİR KEZ sorulur',
      (tester) async {
    // Bildirilen hata (8 Eylül 2026): "iki defa biyometrik istiyor".
    // Kilit İKİ katmanda birden yaşıyordu — paketin `LocalAuthBackgroundLock`i
    // ve uygulamanın `AppAuthBloc` + `/lock` rotası — ve her biri kendi
    // `BiometricAuthPage`ini kuruyordu. Ölçülen: 2 prompt.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final repo = FakeLocalAuthRepository(
      lastBackgroundTime: DateTime.now().millisecondsSinceEpoch -
          const Duration(minutes: 5).inMilliseconds,
    );
    final authBloc = AppAuthBloc(
      localAuthRepository: repo,
      sharedPreferences: prefs,
      systemActivityGuard: SystemActivityGuard(),
    );
    addTearDown(authBloc.close);

    await tester.pumpWidget(buildShell(authBloc: authBloc, repository: repo));
    await tester.pumpAndSettle();

    expect(repo.authenticateCalls, 1);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('kilit ekranı bayat "authenticated" durumuyla açılmaz',
      (tester) async {
    // `LocalAuthLoginBloc` uygulama ömrü boyunca yaşayan ortak bir
    // provider'dan gelirse, bir önceki kilit açma turundan kalan
    // `authenticated`, sayfanın ilk yayınında "başarı" sayılıyor ve kilit hiç
    // sorulmadan açılıyordu.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Kullanıcı biyometriği iptal ediyor: kilit AÇILMAMALI.
    final repo = FakeLocalAuthRepository(
      backgroundTimeout: 0,
      authenticateResult: false,
    );
    final loginBloc = LocalAuthLoginBloc(repository: repo);
    addTearDown(loginBloc.close);

    loginBloc.emit(const LocalAuthLoginState(
      loadStatus: LoginLoadStatus.success,
      authStatus: AuthStatus.authenticated,
      isBiometricEnabled: true,
      isBiometricAvailable: true,
    ));

    var unlocked = false;
    await tester.pumpWidget(
      BlocProvider<LocalAuthLoginBloc>.value(
        value: loginBloc,
        child: MaterialApp(
          home: BiometricAuthPage(
            onSuccess: () => unlocked = true,
            showLogoutButton: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(unlocked, isFalse);
    expect(repo.authenticateCalls, 1, reason: 'gerçekten sorulmalı');
  });
}
