import 'dart:convert';

import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockHttpClient extends Mock implements http.Client {}

class MockDataSerializationService extends Mock
    implements DataSerializationService {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockGoogleSignIn mockGoogleSignIn;
  late MockHttpClient mockHttpClient;
  late MockDataSerializationService mockDataSerializationService;
  late GoogleDriveBackupService service;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    mockHttpClient = MockHttpClient();
    mockDataSerializationService = MockDataSerializationService();
    service = GoogleDriveBackupService.withMocks(
      googleSignIn: mockGoogleSignIn,
      httpClient: mockHttpClient,
      dataSerializationService: mockDataSerializationService,
    );
  });

  group('defaults', () {
    test('default constructor sets up defaults', () {
      final defaultService =
          GoogleDriveBackupService(mockDataSerializationService);
      expect(defaultService.currentUser, isNull);
    });
  });

  group('sign in / sign out', () {
    test('silentSignIn returns true when signInSilently succeeds', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.signInSilently())
          .thenAnswer((_) async => mockAccount);

      final result = await service.silentSignIn();

      expect(result, true);
      expect(service.currentUser, mockAccount);
    });

    test('silentSignIn returns false when signInSilently returns null',
        () async {
      when(() => mockGoogleSignIn.signInSilently())
          .thenAnswer((_) async => null);

      final result = await service.silentSignIn();

      expect(result, false);
      expect(service.currentUser, isNull);
    });

    test('silentSignIn returns false on exception', () async {
      when(() => mockGoogleSignIn.signInSilently())
          .thenThrow(Exception('Network error'));

      final result = await service.silentSignIn();

      expect(result, false);
      expect(service.currentUser, isNull);
    });

    test('signIn returns true on success', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);

      final result = await service.signIn();

      expect(result, true);
      expect(service.currentUser, mockAccount);
    });

    test('signIn returns false on exception', () async {
      when(() => mockGoogleSignIn.signIn())
          .thenThrow(Exception('Network error'));

      final result = await service.signIn();

      expect(result, false);
    });

    test('signOut clears currentUser', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      await service.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
      expect(service.currentUser, isNull);
    });
  });

  group('backup', () {
    void setupAuth() {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authHeaders)
          .thenAnswer((_) async => {'Authorization': 'Bearer test'});
    }

    test('backup returns false when signIn fails', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      final result = await service.backup();

      expect(result, false);
    });

    test('backup delegates JSON export and patches existing Drive file',
        () async {
      setupAuth();
      when(() => mockDataSerializationService.exportDataToJson())
          .thenAnswer((_) async => '{"version":3}');
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'files': [
              {'id': 'file123'}
            ],
          }),
          200,
        ),
      );
      when(() => mockHttpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('', 200));

      final result = await service.backup();

      expect(result, true);
      verify(() => mockDataSerializationService.exportDataToJson()).called(1);
      verify(() => mockHttpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: '{"version":3}',
          )).called(1);
    });

    test('backup creates file when no Drive backup exists', () async {
      setupAuth();
      when(() => mockDataSerializationService.exportDataToJson())
          .thenAnswer((_) async => '{"version":3}');
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'files': []}), 200));
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(jsonEncode({'id': 'newFile456'}), 201),
      );
      when(() => mockHttpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('', 200));

      final result = await service.backup();

      expect(result, true);
      verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).called(1);
    });

    test('backup returns false when patch fails', () async {
      setupAuth();
      when(() => mockDataSerializationService.exportDataToJson())
          .thenAnswer((_) async => '{"version":3}');
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'files': [
              {'id': 'file123'}
            ],
          }),
          200,
        ),
      );
      when(() => mockHttpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('', 500));

      final result = await service.backup();

      expect(result, false);
    });

    test('backup returns false when serialization fails', () async {
      setupAuth();
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'files': [
              {'id': 'file123'}
            ],
          }),
          200,
        ),
      );
      when(() => mockDataSerializationService.exportDataToJson())
          .thenThrow(Exception('Hive corrupt'));

      final result = await service.backup();

      expect(result, false);
    });
  });

  group('restore', () {
    void setupAuth() {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authHeaders)
          .thenAnswer((_) async => {'Authorization': 'Bearer test'});
    }

    test('restore returns false when signIn fails', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      final result = await service.restore();

      expect(result, false);
    });

    test('restore returns false when backup file is not found', () async {
      setupAuth();
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'files': []}), 200));

      final result = await service.restore();

      expect(result, false);
    });

    test('restore returns false when download fails', () async {
      setupAuth();
      final responses = [
        http.Response(
          jsonEncode({
            'files': [
              {'id': 'file123'}
            ],
          }),
          200,
        ),
        http.Response('', 500),
      ];
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => responses.removeAt(0));

      final result = await service.restore();

      expect(result, false);
    });

    test('restore delegates downloaded JSON to serialization service',
        () async {
      setupAuth();
      final responses = [
        http.Response(
          jsonEncode({
            'files': [
              {'id': 'file123'}
            ],
          }),
          200,
        ),
        http.Response('{"version":3}', 200),
      ];
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => responses.removeAt(0));
      when(() => mockDataSerializationService.importDataFromJson(any()))
          .thenAnswer((_) async => const DataRestoreResult.success());

      final result = await service.restore();

      expect(result, true);
      verify(() =>
              mockDataSerializationService.importDataFromJson('{"version":3}'))
          .called(1);
    });

    test('restore returns false when delegated restore fails', () async {
      setupAuth();
      final responses = [
        http.Response(
          jsonEncode({
            'files': [
              {'id': 'file123'}
            ],
          }),
          200,
        ),
        http.Response('bad json', 200),
      ];
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => responses.removeAt(0));
      when(() => mockDataSerializationService.importDataFromJson(any()))
          .thenAnswer(
        (_) async => const DataRestoreResult.invalidFormat('bad json'),
      );

      final result = await service.restore();

      expect(result, false);
    });
  });

  group('deleteBackup', () {
    void setupAuth() {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authHeaders)
          .thenAnswer((_) async => {'Authorization': 'Bearer test'});
    }

    test('returns false when signIn fails', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      final result = await service.deleteBackup();

      expect(result, false);
    });

    test('deletes the file and returns true when backup exists', () async {
      setupAuth();
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'files': [
              {'id': 'file123'}
            ],
          }),
          200,
        ),
      );
      when(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 204));

      final result = await service.deleteBackup();

      expect(result, true);
      verify(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
          .called(1);
    });

    test('returns true (no-op) and does not call delete when no backup exists',
        () async {
      setupAuth();
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode({'files': []}), 200));

      final result = await service.deleteBackup();

      expect(result, true);
      verifyNever(
          () => mockHttpClient.delete(any(), headers: any(named: 'headers')));
    });

    test('returns false when delete request fails', () async {
      setupAuth();
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'files': [
              {'id': 'file123'}
            ],
          }),
          200,
        ),
      );
      when(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 500));

      final result = await service.deleteBackup();

      expect(result, false);
    });
  });
}
