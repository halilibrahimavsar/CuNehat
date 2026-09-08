import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/models/local_user.dart';
import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

class MockLocalAuthRepository extends Mock implements LocalAuthRepository {}

void main() {
  late MockLocalAuthRepository mockAuthRepo;
  late SharedPreferences prefs;
  late SystemActivityGuard guard;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    mockAuthRepo = MockLocalAuthRepository();
    guard = SystemActivityGuard();

    // Arka plan kilidi süresi artık kullanıcının ayarından okunuyor.
    when(() => mockAuthRepo.getBackgroundLockTimeoutSeconds())
        .thenAnswer((_) async => 30);
    when(() => mockAuthRepo.setBackgroundLockTimeoutSeconds(any()))
        .thenAnswer((_) async {});
  });

  group('AppAuthBloc initialization', () {
    setUp(() async {
      prefs = await SharedPreferences.getInstance();
    });

    blocTest<AppAuthBloc, AppAuthState>(
      'emits [Loading, Locked] when biometric is enabled',
      setUp: () {
        when(() => mockAuthRepo.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async => false);
      },
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthLocked>(),
      ],
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'emits [Loading, Locked] when pin is set',
      setUp: () {
        when(() => mockAuthRepo.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async => true);
      },
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthLocked>(),
      ],
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'emits [Loading, Authenticated] when neither bio nor pin enabled',
      setUp: () {
        when(() => mockAuthRepo.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async => false);
      },
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
      ],
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'emits [Loading, Error] when repository throws',
      setUp: () {
        when(() => mockAuthRepo.isBiometricEnabled())
            .thenThrow(Exception('Auth error'));
      },
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthError>(),
      ],
    );
  });

  group('AppAuthBloc unlock/lock', () {
    setUp(() async {
      prefs = await SharedPreferences.getInstance();
    });

    blocTest<AppAuthBloc, AppAuthState>(
      'unlock transitions from Locked to Authenticated',
      setUp: () {
        when(() => mockAuthRepo.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async => true);
      },
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(AppAuthUnlockRequested(LocalUser.guest()));
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthLocked>(),
        isA<AppAuthenticated>(),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<AppAuthenticated>());
      },
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'lock transitions from Authenticated to Locked',
      setUp: () {
        when(() => mockAuthRepo.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async => false);
      },
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const AppAuthLockRequested());
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
        isA<AppAuthLocked>(),
      ],
    );
  });

  group('AppAuthBloc app resume', () {
    setUp(() async {
      prefs = await SharedPreferences.getInstance();
    });

    blocTest<AppAuthBloc, AppAuthState>(
      'resume locks when bio enabled',
      setUp: () {
        // Auto-init sees bio=false → Authenticated; resume sees bio=true → Locked
        int bioCallCount = 0;
        when(() => mockAuthRepo.isBiometricEnabled()).thenAnswer((_) async {
          bioCallCount++;
          return bioCallCount > 1;
        });
        when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async => false);
      },
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const AppAuthAppResumed());
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
        isA<AppAuthLocked>(),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<AppAuthLocked>());
      },
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'resume does nothing when bio/pin disabled',
      setUp: () {
        when(() => mockAuthRepo.isBiometricEnabled())
            .thenAnswer((_) async => false);
        when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async => false);
      },
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const AppAuthAppResumed());
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
      ],
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'resume does nothing when already locked',
      setUp: () {
        when(() => mockAuthRepo.isBiometricEnabled())
            .thenAnswer((_) async => true);
        when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async => false);
      },
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      seed: () => AppAuthLocked(LocalUser.guest()),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const AppAuthAppResumed());
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthLocked>(),
      ],
    );
  });

  group('AppAuthBloc lifecycle lock', () {
    // Bildirilen hata (3 Eylül 2026): PIN açıkken banka ekstresi için dosya
    // seçici açılıyor, kullanıcı klasörlerde 30 saniyeden fazla dolaşıyor ve
    // dönüşte kilit ekranı açılıyordu. Router kilitte tüm yığını `/lock`'a
    // yönlendirdiğinden içe aktarma sayfası siliniyor, seçilen dosya hiç
    // ayrıştırılmıyordu.
    late DateTime clock;

    setUp(() async {
      prefs = await SharedPreferences.getInstance();
      clock = DateTime(2026, 9, 3, 12);
      // Muhafız ve bloc AYNI saati okumalı; farklı saatler af penceresini
      // anlamsız kılar.
      guard = SystemActivityGuard.withClock(() => clock);

      // Yapıcı kendi init olayını ekler ve `seed`'i ezer: bloc act anında
      // Authenticated olmalı ki `_onAppResumed` erken dönmesin. Kardeş
      // testlerdeki çağrı-sayacı kalıbı — ilk okuma (init) PIN'i kapalı
      // görür, dönüşteki okuma açık.
      var pinReads = 0;
      when(() => mockAuthRepo.isBiometricEnabled())
          .thenAnswer((_) async => false);
      when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async {
        pinReads++;
        return pinReads > 1;
      });
    });

    AppAuthBloc build() => AppAuthBloc(
          localAuthRepository: mockAuthRepo,
          sharedPreferences: prefs,
          systemActivityGuard: guard,
          now: () => clock,
        );

    blocTest<AppAuthBloc, AppAuthState>(
      'uzun arka plandan dönüş kilitler',
      build: build,
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
        clock = clock.add(const Duration(minutes: 3));
        bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
        isA<AppAuthLocked>(),
      ],
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'AÇIK dosya seçicisinden dönüş kilitlemez',
      build: build,
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        final picked = Completer<String>();
        final picking = guard.run(() => picked.future);

        bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
        clock = clock.add(const Duration(minutes: 3));
        bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);

        picked.complete('/tmp/ekstre.pdf');
        await picking;
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
      ],
      verify: (bloc) => expect(bloc.state, isA<AppAuthenticated>()),
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'seçici sonucu resumed bildiriminden önce gelirse de kilitlemez',
      build: build,
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
        clock = clock.add(const Duration(minutes: 3));

        // onActivityResult → Dart future, resumed bildiriminden ÖNCE.
        await guard.run(() async => '/tmp/ekstre.pdf');
        bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
      ],
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'seçici turu bittikten SONRAKİ arka plan turu yine kilitler',
      build: build,
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await guard.run(() async => '/tmp/ekstre.pdf');

        // Af yalnız o tura verilir: sonraki gerçek arka plan çıkışı kilitler.
        bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
        clock = clock.add(const Duration(minutes: 3));
        bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
        isA<AppAuthLocked>(),
      ],
    );
  });

  group('AppAuthBloc arka plan kilidi süresi', () {
    // Bildirilen hata (8 Eylül 2026): tek kilit açma turunda biyometrik İKİ
    // KEZ soruluyordu. Paketin kendi arka plan kilidi ile uygulamanın kendi
    // kilidi aynı anda açıktı; süre artık TEK yerden, kullanıcının
    // ayarından okunuyor.
    late DateTime clock;

    setUp(() async {
      prefs = await SharedPreferences.getInstance();
      clock = DateTime(2026, 9, 8, 12);
      guard = SystemActivityGuard.withClock(() => clock);

      var pinReads = 0;
      when(() => mockAuthRepo.isBiometricEnabled())
          .thenAnswer((_) async => false);
      when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async {
        pinReads++;
        return pinReads > 1;
      });
    });

    AppAuthBloc build() => AppAuthBloc(
          localAuthRepository: mockAuthRepo,
          sharedPreferences: prefs,
          systemActivityGuard: guard,
          now: () => clock,
        );

    Future<void> background(AppAuthBloc bloc, Duration away) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
      clock = clock.add(away);
      bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
    }

    blocTest<AppAuthBloc, AppAuthState>(
      'ayar "Kapalı" ise uzun arka plandan dönüş kilitlemez',
      setUp: () {
        when(() => mockAuthRepo.getBackgroundLockTimeoutSeconds())
            .thenAnswer((_) async => 0);
      },
      build: build,
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) => background(bloc, const Duration(minutes: 10)),
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
      ],
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'seçilen süre dolmadan dönüş kilitlemez',
      setUp: () {
        when(() => mockAuthRepo.getBackgroundLockTimeoutSeconds())
            .thenAnswer((_) async => 60);
      },
      build: build,
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) => background(bloc, const Duration(seconds: 45)),
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
      ],
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'seçilen süre dolduktan sonra dönüş kilitler',
      setUp: () {
        when(() => mockAuthRepo.getBackgroundLockTimeoutSeconds())
            .thenAnswer((_) async => 60);
      },
      build: build,
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) => background(bloc, const Duration(seconds: 90)),
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
        isA<AppAuthLocked>(),
      ],
    );

    blocTest<AppAuthBloc, AppAuthState>(
      'paused görmeden gelen resumed eski turu yeniden ölçmez',
      build: build,
      seed: () => AppAuthenticated(LocalUser.guest()),
      act: (bloc) async {
        await background(bloc, const Duration(minutes: 10));
        // İlk tur kilitledi; bildirim panelini açıp kapatmak `paused`
        // üretmeden ikinci bir `resumed` verir.
        bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
        isA<AppAuthLocked>(),
      ],
    );

    test('ayara hiç dokunulmamış kurulumda varsayılan süre bir kez yazılır',
        () async {
      when(() => mockAuthRepo.getBackgroundLockTimeoutSeconds())
          .thenAnswer((_) async => 0);

      final bloc = build();
      await bloc.stream.firstWhere((s) => s is! AppAuthLoading);
      verify(() => mockAuthRepo.setBackgroundLockTimeoutSeconds(30)).called(1);
      await bloc.close();

      // İkinci açılış tohumu tekrar yazmaz: kullanıcı "Kapalı" seçtiyse
      // seçimi geri gelmemeli.
      final second = build();
      await second.stream.firstWhere((s) => s is! AppAuthLoading);
      verifyNever(() => mockAuthRepo.setBackgroundLockTimeoutSeconds(any()));
      await second.close();
    });

    test('kullanıcının seçtiği süre tohumla ezilmez', () async {
      when(() => mockAuthRepo.getBackgroundLockTimeoutSeconds())
          .thenAnswer((_) async => 5);

      final bloc = build();
      await bloc.stream.firstWhere((s) => s is! AppAuthLoading);
      verifyNever(() => mockAuthRepo.setBackgroundLockTimeoutSeconds(any()));
      await bloc.close();
    });
  });

  group('AppAuthBloc updateDisplayName', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      when(() => mockAuthRepo.isBiometricEnabled())
          .thenAnswer((_) async => false);
      when(() => mockAuthRepo.isPinSet()).thenAnswer((_) async => false);
    });

    blocTest<AppAuthBloc, AppAuthState>(
      'updateDisplayName saves to prefs and re-initializes',
      build: () => AppAuthBloc(
        localAuthRepository: mockAuthRepo,
        sharedPreferences: prefs,
        systemActivityGuard: guard,
      ),
      act: (bloc) async {
        await bloc.updateDisplayName('New Name');
      },
      expect: () => [
        const AppAuthLoading(),
        isA<AppAuthenticated>(),
      ],
      verify: (bloc) {
        expect(prefs.getString('local_user_display_name'), 'New Name');
        final state = bloc.state;
        expect(state, isA<AppAuthenticated>());
        expect((state as AppAuthenticated).user.displayName, 'New Name');
      },
    );
  });
}
