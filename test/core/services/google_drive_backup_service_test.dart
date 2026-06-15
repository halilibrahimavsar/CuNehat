import 'dart:convert';

import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockHttpClient extends Mock implements http.Client {}

class MockHiveInterface extends Mock implements HiveInterface {}

class MockBox<T> extends Mock implements Box<T> {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockGoogleSignIn mockGoogleSignIn;
  late MockHttpClient mockHttpClient;
  late MockHiveInterface mockHive;
  late GoogleDriveBackupService service;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    mockGoogleSignIn = MockGoogleSignIn();
    mockHttpClient = MockHttpClient();
    mockHive = MockHiveInterface();
    service = GoogleDriveBackupService(
      googleSignIn: mockGoogleSignIn,
      httpClient: mockHttpClient,
      hive: mockHive,
    );
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
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async {
        return null;
      });

      await service.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
      expect(service.currentUser, isNull);
    });
  });

  group('backup', () {
    MockBox<WalletModel> walletBox() {
      final box = MockBox<WalletModel>();
      when(() => box.values).thenReturn([]);
      return box;
    }

    MockBox<TransactionModel> txBox() {
      final box = MockBox<TransactionModel>();
      when(() => box.values).thenReturn([]);
      return box;
    }

    MockBox<InvestmentModel> invBox() {
      final box = MockBox<InvestmentModel>();
      when(() => box.values).thenReturn([]);
      return box;
    }

    MockBox<DebtModel> debtBox() {
      final box = MockBox<DebtModel>();
      when(() => box.values).thenReturn([]);
      return box;
    }

    MockBox<ReceivableModel> recvBox() {
      final box = MockBox<ReceivableModel>();
      when(() => box.values).thenReturn([]);
      return box;
    }

    MockBox<Map> userBox() {
      final box = MockBox<Map>();
      when(() => box.keys).thenReturn([]);
      return box;
    }

    void setupHiveBoxes() {
      when(() => mockHive.openBox<WalletModel>(any()))
          .thenAnswer((_) async => walletBox());
      when(() => mockHive.openBox<TransactionModel>(any()))
          .thenAnswer((_) async => txBox());
      when(() => mockHive.openBox<InvestmentModel>(any()))
          .thenAnswer((_) async => invBox());
      when(() => mockHive.openBox<DebtModel>(any()))
          .thenAnswer((_) async => debtBox());
      when(() => mockHive.openBox<ReceivableModel>(any()))
          .thenAnswer((_) async => recvBox());
      when(() => mockHive.openBox<Map>(any()))
          .thenAnswer((_) async => userBox());
    }

    test('backup returns false when signIn fails', () async {
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => null);

      final result = await service.backup();

      expect(result, false);
    });

    test('backup succeeds with valid file ID', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authHeaders)
          .thenAnswer((_) async => {'Authorization': 'Bearer test'});

      setupHiveBoxes();

      final findResponse = http.Response(jsonEncode({'files': [
        {'id': 'file123'}
      ]}), 200);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => findResponse);

      final patchResponse = http.Response('', 200);
      when(() => mockHttpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => patchResponse);

      final result = await service.backup();

      expect(result, true);
    });

    test('backup returns false when patch fails', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authHeaders)
          .thenAnswer((_) async => {'Authorization': 'Bearer test'});

      setupHiveBoxes();

      final findResponse = http.Response(jsonEncode({'files': [
        {'id': 'file123'}
      ]}), 200);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => findResponse);

      final patchResponse = http.Response('', 500);
      when(() => mockHttpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => patchResponse);

      final result = await service.backup();

      expect(result, false);
    });

    test('backup creates file when not found then patches', () async {
      final mockAccount = MockGoogleSignInAccount();
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAccount.authHeaders)
          .thenAnswer((_) async => {'Authorization': 'Bearer test'});

      setupHiveBoxes();

      final notFoundResponse = http.Response(jsonEncode({'files': []}), 200);
      final createResponse = http.Response(jsonEncode({'id': 'newFile456'}), 201);
      final patchResponse = http.Response('', 200);

      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => notFoundResponse);
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => createResponse);
      when(() => mockHttpClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => patchResponse);

      final result = await service.backup();

      expect(result, true);
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

    MockBox<WalletModel> walletBox() {
      final box = MockBox<WalletModel>();
      when(() => box.values).thenReturn([]);
      when(() => box.keys).thenReturn([]);
      when(() => box.toMap()).thenReturn({});
      when(() => box.clear()).thenAnswer((_) async => 0);
      return box;
    }

    MockBox<TransactionModel> txBox() {
      final box = MockBox<TransactionModel>();
      when(() => box.values).thenReturn([]);
      when(() => box.keys).thenReturn([]);
      when(() => box.toMap()).thenReturn({});
      when(() => box.clear()).thenAnswer((_) async => 0);
      return box;
    }

    MockBox<InvestmentModel> invBox() {
      final box = MockBox<InvestmentModel>();
      when(() => box.values).thenReturn([]);
      when(() => box.keys).thenReturn([]);
      when(() => box.toMap()).thenReturn({});
      when(() => box.clear()).thenAnswer((_) async => 0);
      return box;
    }

    MockBox<DebtModel> debtBox() {
      final box = MockBox<DebtModel>();
      when(() => box.values).thenReturn([]);
      when(() => box.keys).thenReturn([]);
      when(() => box.toMap()).thenReturn({});
      when(() => box.clear()).thenAnswer((_) async => 0);
      return box;
    }

    MockBox<ReceivableModel> recvBox() {
      final box = MockBox<ReceivableModel>();
      when(() => box.values).thenReturn([]);
      when(() => box.keys).thenReturn([]);
      when(() => box.toMap()).thenReturn({});
      when(() => box.clear()).thenAnswer((_) async => 0);
      return box;
    }

    MockBox<Map> userBox() {
      final box = MockBox<Map>();
      when(() => box.keys).thenReturn([]);
      when(() => box.toMap()).thenReturn({});
      when(() => box.clear()).thenAnswer((_) async => 0);
      return box;
    }

    void setupHiveBoxes() {
      when(() => mockHive.openBox<WalletModel>(any()))
          .thenAnswer((_) async => walletBox());
      when(() => mockHive.openBox<TransactionModel>(any()))
          .thenAnswer((_) async => txBox());
      when(() => mockHive.openBox<InvestmentModel>(any()))
          .thenAnswer((_) async => invBox());
      when(() => mockHive.openBox<DebtModel>(any()))
          .thenAnswer((_) async => debtBox());
      when(() => mockHive.openBox<ReceivableModel>(any()))
          .thenAnswer((_) async => recvBox());
      when(() => mockHive.openBox<Map>(any()))
          .thenAnswer((_) async => userBox());
    }

    test('restore returns false when signIn fails', () async {
      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => null);

      final result = await service.restore();

      expect(result, false);
    });

    test('restore returns false when backup file not found', () async {
      setupAuth();

      final notFoundResponse = http.Response(jsonEncode({'files': []}), 200);
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => notFoundResponse);

      final result = await service.restore();

      expect(result, false);
    });

    test('restore returns false when download fails', () async {
      setupAuth();

      final findResponse = http.Response(jsonEncode({'files': [
        {'id': 'file123'}
      ]}), 200);
      final downloadResponse = http.Response('', 500);

      final getResponses = [findResponse, downloadResponse];
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => getResponses.removeAt(0));

      final result = await service.restore();

      expect(result, false);
    });

    test('restore succeeds with valid backup', () async {
      setupAuth();
      setupHiveBoxes();

      final findResponse = http.Response(jsonEncode({'files': [
        {'id': 'file123'}
      ]}), 200);
      final backupData = {
        'wallets': [],
        'transactions': [],
        'investments': [],
        'debts': [],
        'receivables': [],
        'users': {},
      };
      final downloadResponse = http.Response(jsonEncode(backupData), 200);

      final getResponses = [findResponse, downloadResponse];
      when(() => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => getResponses.removeAt(0));

      final result = await service.restore();

      expect(result, true);
    });
  });
}
