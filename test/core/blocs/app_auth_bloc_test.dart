import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/models/local_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

class MockLocalAuthRepository extends Mock implements LocalAuthRepository {}

void main() {
  late MockLocalAuthRepository mockAuthRepo;
  late SharedPreferences prefs;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    mockAuthRepo = MockLocalAuthRepository();
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
