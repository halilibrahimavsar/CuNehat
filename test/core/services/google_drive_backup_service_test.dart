import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:flutter/services.dart';
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

/// Boş olmayan varsayılan cihaz özeti (boş-veri kapısını tetiklemesin).
BackupSummary _summary({int transactionCount = 12, int walletCount = 2}) {
  return BackupSummary(
    schemaVersion: DataSerializationService.schemaVersion,
    createdAt: null,
    walletCount: walletCount,
    transactionCount: transactionCount,
    investmentCount: 0,
    debtCount: 0,
    receivableCount: 0,
    budgetCount: 0,
    recurringCount: 0,
    categoryCount: 0,
    wallets: const [],
    firstTransactionDate: null,
    lastTransactionDate: null,
    totalIncome: 0,
    totalExpense: 0,
    transactionsWithReceipt: 0,
  );
}

BackupSummary _emptySummary() => _summary(transactionCount: 0, walletCount: 0);

Map<String, dynamic> _driveFileJson({
  String id = 'file123',
  String name = 'cunehat_backup_20260730_120000.json',
  int size = 42,
  String modifiedTime = '2026-07-30T12:00:00.000Z',
  String? md5Checksum,
  Map<String, String>? appProperties,
}) {
  return {
    'id': id,
    'name': name,
    'size': '$size',
    'modifiedTime': modifiedTime,
    if (md5Checksum != null) 'md5Checksum': md5Checksum,
    if (appProperties != null) 'appProperties': appProperties,
  };
}

http.Response _errorResponse(int code, String reason) {
  return http.Response(
    jsonEncode({
      'error': {
        'errors': [
          {'reason': reason}
        ],
        'code': code,
      }
    }),
    code,
  );
}

void main() {
  late MockGoogleSignIn mockGoogleSignIn;
  late MockGoogleSignInAccount mockAccount;
  late MockHttpClient mockHttpClient;
  late MockDataSerializationService mockData;
  late GoogleDriveBackupService service;

  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  setUp(() {
    mockGoogleSignIn = MockGoogleSignIn();
    mockAccount = MockGoogleSignInAccount();
    mockHttpClient = MockHttpClient();
    mockData = MockDataSerializationService();
    service = GoogleDriveBackupService.withMocks(
      googleSignIn: mockGoogleSignIn,
      httpClient: mockHttpClient,
      dataSerializationService: mockData,
      shortTimeout: const Duration(milliseconds: 200),
      transferTimeout: const Duration(milliseconds: 400),
    );

    when(() => mockAccount.authHeaders)
        .thenAnswer((_) async => {'Authorization': 'Bearer test'});
    when(() => mockAccount.clearAuthCache()).thenAnswer((_) async {});
    when(() => mockData.currentDataSummary())
        .thenAnswer((_) async => _summary());
  });

  /// Sessiz oturumun başarılı olduğu varsayılan kurulum.
  void signedIn() {
    when(() => mockGoogleSignIn.signInSilently(
        suppressErrors: any(named: 'suppressErrors'))).thenAnswer(
      (_) async => mockAccount,
    );
  }

  void signedOut() {
    when(() => mockGoogleSignIn.signInSilently(
            suppressErrors: any(named: 'suppressErrors')))
        .thenAnswer((_) async => null);
  }

  /// Tek bir GET stub'ı: URL'e bakarak liste / indirme yanıtını verir.
  void stubGet({
    http.Response? list,
    http.Response? download,
  }) {
    when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer((invocation) async {
      final uri = invocation.positionalArguments[0] as Uri;
      if (uri.queryParameters['alt'] == 'media') {
        return download ?? http.Response('{}', 200);
      }
      return list ?? http.Response(jsonEncode({'files': <dynamic>[]}), 200);
    });
  }

  void stubUpload(http.Response response) {
    when(() => mockHttpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => response);
  }

  void stubDelete([int code = 204]) {
    when(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('', code));
  }

  // =========================================================== oturum / tanı

  group('oturum ve tanı', () {
    test('sessiz giriş başarılıysa hesabı taşır', () async {
      signedIn();

      final result = await service.silentSignIn();

      expect(result.status, DriveOperationStatus.success);
      expect(service.currentUser, mockAccount);
      expect(service.isSignedIn, isTrue);
    });

    test('hiç bağlanmamış kullanıcı notSignedIn döner', () async {
      signedOut();

      final result = await service.silentSignIn();

      expect(result.status, DriveOperationStatus.notSignedIn);
    });

    // REGRESYON: `signInSilently` varsayılan olarak `suppressErrors: true` ile
    // çağrılıyordu; DEVELOPER_ERROR dahil HER istisna yutulup null dönüyor ve
    // kart yalnızca "bağlı değil" diyebiliyordu. OAuth istemcisi yanlış
    // yapılandırıldığında sebebi görmenin hiçbir yolu yoktu.
    test('DEVELOPER_ERROR (ApiException: 10) configError olarak yüzeye çıkar',
        () async {
      when(() => mockGoogleSignIn.signInSilently(
          suppressErrors: any(named: 'suppressErrors'))).thenThrow(
        PlatformException(
          code: 'sign_in_failed',
          message: 'com.google.android.gms.common.api.ApiException: 10: ',
        ),
      );

      final result = await service.silentSignIn();

      expect(result.status, DriveOperationStatus.configError);
    });

    test('sessiz girişte ağ hatası noNetwork olarak sınıflandırılır', () async {
      when(() => mockGoogleSignIn.signInSilently(
              suppressErrors: any(named: 'suppressErrors')))
          .thenThrow(PlatformException(code: 'network_error'));

      final result = await service.silentSignIn();

      expect(result.status, DriveOperationStatus.noNetwork);
    });

    // Kullanıcı hesap seçiciyi kapattığında eskiden "bağlantı başarısız"
    // hatası gösteriliyordu; iptal bir arıza değildir.
    test('etkileşimli girişte iptal, hata değil cancelled döner', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      final result = await service.signIn();

      expect(result.status, DriveOperationStatus.cancelled);
      expect(result.isCancelled, isTrue);
    });

    test('signOut currentUser temizler', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      await service.signOut();

      expect(service.currentUser, isNull);
    });
  });

  // ================================================================== listeme

  group('listBackups', () {
    test('metadata ve appProperties çözülür, yeniden eskiye sıralanır',
        () async {
      signedIn();
      stubGet(
        list: http.Response(
          jsonEncode({
            'files': [
              _driveFileJson(
                id: 'yeni',
                size: 2048,
                modifiedTime: '2026-07-30T10:00:00.000Z',
                appProperties: {
                  'schemaVersion': '4',
                  'transactionCount': '389',
                  'walletCount': '3',
                  'origin': 'auto',
                },
              ),
              _driveFileJson(id: 'eski'),
            ],
          }),
          200,
        ),
      );

      final result = await service.listBackups();

      expect(result.status, DriveOperationStatus.success);
      final files = result.data!;
      expect(files, hasLength(2));
      expect(files.first.id, 'yeni');
      expect(files.first.sizeBytes, 2048);
      expect(files.first.transactionCount, 389);
      expect(files.first.walletCount, 3);
      expect(files.first.schemaVersion, 4);
      expect(files.first.origin, BackupOrigin.auto);
      // appProperties olmayan eski kopya: sayım uydurulmaz, null kalır.
      expect(files.last.transactionCount, isNull);
      expect(files.last.origin, BackupOrigin.unknown);
    });

    test('yedek yoksa latestBackup notFound döner', () async {
      signedIn();
      stubGet();

      final result = await service.latestBackup();

      expect(result.status, DriveOperationStatus.notFound);
    });

    test('oturum yoksa ve etkileşim kapalıysa notSignedIn döner', () async {
      signedOut();

      final result = await service.listBackups();

      expect(result.status, DriveOperationStatus.notSignedIn);
      verifyNever(() => mockGoogleSignIn.signIn());
    });
  });

  // =================================================================== yedek

  group('backup', () {
    // A1 REGRESYON: yeni kurulumda "Yedekle"ye basmak, Drive'daki dolu tek
    // kopyayı boş veriyle eziyordu — sessiz bir veri kaybı yolu.
    test('yerel veri boşken yükleme yapılmaz', () async {
      when(() => mockData.currentDataSummary())
          .thenAnswer((_) async => _emptySummary());

      final result = await service.backup();

      expect(result.status, DriveOperationStatus.emptyLocalData);
      verifyNever(() => mockHttpClient.post(any(),
          headers: any(named: 'headers'), body: any(named: 'body')));
      verifyNever(() => mockData.exportDataToJson());
    });

    test('allowEmpty ile boş veri bilerek yedeklenebilir', () async {
      signedIn();
      when(() => mockData.currentDataSummary())
          .thenAnswer((_) async => _emptySummary());
      const payload = '{"version":4}';
      when(() => mockData.exportDataToJson()).thenAnswer((_) async => payload);
      stubGet();
      stubUpload(http.Response(
        jsonEncode(_driveFileJson(
          md5Checksum: md5.convert(utf8.encode(payload)).toString(),
        )),
        200,
      ));

      final result = await service.backup(allowEmpty: true);

      expect(result.status, DriveOperationStatus.success);
    });

    test('tek multipart istekle yükler ve md5 ile doğrular', () async {
      signedIn();
      const payload = '{"version":4,"note":"Şişli — İĞÜÖÇ"}';
      when(() => mockData.exportDataToJson()).thenAnswer((_) async => payload);
      stubGet();
      stubUpload(http.Response(
        jsonEncode(_driveFileJson(
          size: utf8.encode(payload).length,
          md5Checksum: md5.convert(utf8.encode(payload)).toString(),
        )),
        200,
      ));

      final result = await service.backup();

      expect(result.status, DriveOperationStatus.success);
      expect(result.data!.id, 'file123');

      // A3 REGRESYON: eski akış önce boş dosya yaratıp içeriği ayrı PATCH ile
      // yolluyordu; ikinci adım koparsa Drive'da 0 baytlı "yedek" kalıyordu.
      verifyNever(() => mockHttpClient.patch(any(),
          headers: any(named: 'headers'), body: any(named: 'body')));

      final captured = verify(() => mockHttpClient.post(
            captureAny(),
            headers: captureAny(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      final uri = captured[0] as Uri;
      final headers = captured[1] as Map<String, String>;
      final body = utf8.decode(captured[2] as List<int>);

      expect(uri.queryParameters['uploadType'], 'multipart');
      expect(headers['Content-Type'], contains('multipart/related'));
      expect(body, contains('appDataFolder'));
      expect(body, contains('"transactionCount":"12"'));
      expect(body, contains('"origin":"manual"'));
      expect(body, contains(payload));
    });

    test('otomatik yedek origin=auto olarak damgalanır', () async {
      signedIn();
      const payload = '{"version":4}';
      when(() => mockData.exportDataToJson()).thenAnswer((_) async => payload);
      stubGet();
      stubUpload(http.Response(
        jsonEncode(_driveFileJson(
          md5Checksum: md5.convert(utf8.encode(payload)).toString(),
        )),
        200,
      ));

      await service.backup(origin: BackupOrigin.auto, interactive: false);

      final body = utf8.decode(verify(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured.single as List<int>);
      expect(body, contains('"origin":"auto"'));
    });

    // A4: Drive'ın sakladığı içeriğin md5'i bizimkiyle uyuşmuyorsa yükleme
    // yarım demektir; o kopya "en yeni yedek" olarak seçilirse kullanıcıyı
    // bozuk veriye götürür.
    test('md5 uyuşmazsa yüklenen kopya geri alınır', () async {
      signedIn();
      when(() => mockData.exportDataToJson())
          .thenAnswer((_) async => '{"version":4}');
      stubGet();
      stubUpload(http.Response(
        jsonEncode(_driveFileJson(md5Checksum: 'bambaska-bir-ozet')),
        200,
      ));
      stubDelete();

      final result = await service.backup();

      expect(result.status, DriveOperationStatus.verificationFailed);
      verify(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
          .called(1);
    });

    test('md5 yoksa boyut karşılaştırmasına düşer', () async {
      signedIn();
      const payload = '{"version":4}';
      when(() => mockData.exportDataToJson()).thenAnswer((_) async => payload);
      stubGet();
      stubUpload(http.Response(
        jsonEncode(_driveFileJson(size: utf8.encode(payload).length)),
        200,
      ));

      final result = await service.backup();

      expect(result.status, DriveOperationStatus.success);
    });

    // A2: jenerasyon penceresi. Beşten fazlası kalırsa eski kopyalar sonsuza
    // kadar birikir; azı kalırsa "dün iyiydi" senaryosu kaybolur.
    test('son 5 kopya korunur, fazlası budanır', () async {
      signedIn();
      const payload = '{"version":4}';
      when(() => mockData.exportDataToJson()).thenAnswer((_) async => payload);
      stubUpload(http.Response(
        jsonEncode(_driveFileJson(
          md5Checksum: md5.convert(utf8.encode(payload)).toString(),
        )),
        200,
      ));
      stubGet(
        list: http.Response(
          jsonEncode({
            'files': [
              for (var i = 0; i < 7; i++) _driveFileJson(id: 'f$i'),
            ],
          }),
          200,
        ),
      );
      stubDelete();

      final result = await service.backup();

      expect(result.status, DriveOperationStatus.success);
      // 7 kopya listelendi → 5'i tutulur, 2'si silinir.
      verify(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
          .called(2);
    });

    test('veri değişmediyse yükleme atlanır (unchanged)', () async {
      signedIn();
      const payload = '{"version":4}';
      when(() => mockData.exportDataToJson()).thenAnswer((_) async => payload);

      final result = await service.backup(
        skipIfContentMd5Matches: md5.convert(utf8.encode(payload)).toString(),
      );

      expect(result.status, DriveOperationStatus.unchanged);
      verifyNever(() => mockHttpClient.post(any(),
          headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('kota dolu 403 quotaExceeded olarak ayrışır', () async {
      signedIn();
      when(() => mockData.exportDataToJson())
          .thenAnswer((_) async => '{"version":4}');
      stubGet();
      stubUpload(_errorResponse(403, 'storageQuotaExceeded'));

      final result = await service.backup();

      expect(result.status, DriveOperationStatus.quotaExceeded);
    });

    test('ağ kesintisi noNetwork olarak sınıflandırılır', () async {
      signedIn();
      when(() => mockData.exportDataToJson())
          .thenAnswer((_) async => '{"version":4}');
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(const SocketException('bağlantı yok'));

      final result = await service.backup();

      expect(result.status, DriveOperationStatus.noNetwork);
    });

    test('serileştirme çökerse serverError döner, istisna sızmaz', () async {
      signedIn();
      when(() => mockData.exportDataToJson())
          .thenThrow(Exception('Hive bozuk'));

      final result = await service.backup();

      expect(result.status, DriveOperationStatus.serverError);
    });
  });

  // ============================================================== yetkilendirme

  group('yetkilendirme yeniden denemeleri', () {
    // B4 REGRESYON: paketin dokümanı 401 alan istemcinin `clearAuthCache`
    // çağırıp `authHeaders`'ı yeniden almasını şart koşuyor. Bu yapılmadığı
    // için token süresi dolduğunda yedekleme sessizce başarısız oluyordu.
    test('401 sonrası token tazelenir ve istek bir kez yinelenir', () async {
      signedIn();
      var attempt = 0;
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        attempt++;
        if (attempt == 1) return http.Response('', 401);
        return http.Response(jsonEncode({'files': <dynamic>[]}), 200);
      });

      final result = await service.listBackups();

      expect(result.status, DriveOperationStatus.success);
      expect(attempt, 2);
      verify(() => mockAccount.clearAuthCache()).called(1);
    });

    test('tazeleme de 401 alırsa authExpired döner', () async {
      signedIn();
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 401));

      final result = await service.listBackups();

      expect(result.status, DriveOperationStatus.authExpired);
    });

    // B5: `canAccessScopes` Android'de UnimplementedError fırlatır, bu yüzden
    // kapsam önden sorulamaz — 403 gelince istenir.
    test('403 kapsam hatasında requestScopes çağrılır ve yinelenir', () async {
      signedIn();
      when(() => mockGoogleSignIn.requestScopes(any()))
          .thenAnswer((_) async => true);
      var attempt = 0;
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async {
        attempt++;
        if (attempt == 1) return _errorResponse(403, 'insufficientPermissions');
        return http.Response(jsonEncode({'files': <dynamic>[]}), 200);
      });

      final result = await service.listBackups();

      expect(result.status, DriveOperationStatus.success);
      verify(() =>
              mockGoogleSignIn.requestScopes(GoogleDriveBackupService.scopes))
          .called(1);
    });

    // Drive API'nin projede kapalı olması da 403 döner. Bunu kapsam eksikliği
    // sanmak kullanıcıyı, verebileceği bir izin olmadığı halde izin ekranı
    // aramaya gönderiyordu.
    test('API kapalıysa apiNotEnabled döner ve kapsam İSTENMEZ', () async {
      signedIn();
      when(() => mockGoogleSignIn.requestScopes(any()))
          .thenAnswer((_) async => true);
      stubGet(list: _errorResponse(403, 'accessNotConfigured'));

      final result = await service.listBackups();

      expect(result.status, DriveOperationStatus.apiNotEnabled);
      verifyNever(() => mockGoogleSignIn.requestScopes(any()));
    });

    test('SERVICE_DISABLED de apiNotEnabled sayılır', () async {
      signedIn();
      stubGet(list: _errorResponse(403, 'SERVICE_DISABLED'));

      final result = await service.listBackups();

      expect(result.status, DriveOperationStatus.apiNotEnabled);
    });

    // Teşhis için ham Drive sebebi sonuçta taşınır (cihaz günlüğüne düşer).
    test('hata detayı gerçek Drive sebebini içerir', () async {
      signedIn();
      stubGet(list: _errorResponse(403, 'accessNotConfigured'));

      final result = await service.listBackups();

      expect('${result.error}', contains('accessnotconfigured'));
    });

    test('kapsam reddedilirse scopeDenied döner', () async {
      signedIn();
      when(() => mockGoogleSignIn.requestScopes(any()))
          .thenAnswer((_) async => false);
      stubGet(list: _errorResponse(403, 'insufficientPermissions'));

      final result = await service.listBackups();

      expect(result.status, DriveOperationStatus.scopeDenied);
    });

    // B6: eskiden hiçbir istekte timeout yoktu; ağ takılınca kart sonsuza
    // kadar dönüyordu ve iptal yolu yoktu.
    test('yanıt gelmezse timeout döner', () async {
      signedIn();
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) => Completer<http.Response>().future);

      final result = await service.listBackups().timeout(
            const Duration(seconds: 5),
            onTimeout: () =>
                throw StateError('servis kendi zaman aşımını uygulamadı'),
          );

      expect(result.status, DriveOperationStatus.timeout);
    });
  });

  // ============================================================== geri yükleme

  group('restore', () {
    test('yedek yoksa notFound döner (bozuk/başarısız değil)', () async {
      signedIn();
      stubGet();

      final result = await service.restoreLatest();

      expect(result.status, DriveOperationStatus.notFound);
    });

    // B1 REGRESYON: eskiden "yedek yok", "bozuk dosya", "şema uyuşmuyor",
    // "ağ yok" ve "kapsam reddi" tek `false`'a katlanıyor, kart hepsine
    // "Yedek dosyası bulunamadı" diyordu.
    test('şema uyuşmazlığı ayrı durum olarak ve bulunan sürümle döner',
        () async {
      signedIn();
      stubGet(
        list: http.Response(
            jsonEncode({
              'files': [_driveFileJson()]
            }),
            200),
        download: http.Response('{"version":99}', 200),
      );
      when(() => mockData.importDataFromJson(any())).thenAnswer(
        (_) async => const DataRestoreResult.versionMismatch(99),
      );

      final result = await service.restoreLatest();

      expect(result.status, DriveOperationStatus.versionMismatch);
      expect(result.foundSchemaVersion, 99);
    });

    test('ayrıştırılamayan içerik corrupt döner', () async {
      signedIn();
      stubGet(
        list: http.Response(
            jsonEncode({
              'files': [_driveFileJson()]
            }),
            200),
        download: http.Response.bytes(utf8.encode('bu json değil'), 200),
      );
      when(() => mockData.importDataFromJson(any())).thenAnswer(
        (_) async => const DataRestoreResult.invalidFormat('bozuk'),
      );

      final result = await service.restoreLatest();

      expect(result.status, DriveOperationStatus.corrupt);
    });

    test('yerel yazım hatası writeFailure olarak ayrışır', () async {
      signedIn();
      stubGet(
        list: http.Response(
            jsonEncode({
              'files': [_driveFileJson()]
            }),
            200),
        download: http.Response('{"version":4}', 200),
      );
      when(() => mockData.importDataFromJson(any())).thenAnswer(
        (_) async => const DataRestoreResult.writeFailure('disk dolu'),
      );

      final result = await service.restoreLatest();

      expect(result.status, DriveOperationStatus.writeFailure);
    });

    // REGRESYON: gövde `response.body` ile okunuyordu. package:http, Content-Type
    // başlığında charset yoksa yalnız `application/json` için utf8'e düşer,
    // başka her değerde latin1'e — ve latin1 çözme hata VERMEZ, sessizce
    // mojibake üretir. JSON yine parse olduğu için Drive'dan geri yüklenen her
    // Türkçe başlık/kategori/cüzdan adı fark edilmeden bozulurdu.
    test('indirilen gövde Content-Type ne olursa olsun utf8 çözülür', () async {
      signedIn();
      const payload = '{"version":4,"note":"Bakkal fişi — Şişli, İĞÜÖÇ"}';
      stubGet(
        list: http.Response(
            jsonEncode({
              'files': [_driveFileJson()]
            }),
            200),
        download: http.Response.bytes(
          utf8.encode(payload),
          200,
          headers: const {'content-type': 'application/octet-stream'},
        ),
      );
      when(() => mockData.importDataFromJson(any()))
          .thenAnswer((_) async => const DataRestoreResult.success());

      final result = await service.restoreLatest();

      expect(result.status, DriveOperationStatus.success);
      verify(() => mockData.importDataFromJson(payload)).called(1);
    });

    test('downloadBackup içeriği yazmadan döner (önizleme yolu)', () async {
      signedIn();
      stubGet(download: http.Response('{"version":4}', 200));

      final result = await service.downloadBackup('file123');

      expect(result.status, DriveOperationStatus.success);
      expect(result.data, '{"version":4}');
      verifyNever(() => mockData.importDataFromJson(any()));
    });
  });

  // =================================================================== silme

  group('silme', () {
    test('tek kopya silinir', () async {
      signedIn();
      stubDelete();

      final result = await service.deleteBackup('file123');

      expect(result.status, DriveOperationStatus.success);
      verify(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
          .called(1);
    });

    test('404 zaten silinmiş sayılır', () async {
      signedIn();
      stubDelete(404);

      final result = await service.deleteBackup('file123');

      expect(result.status, DriveOperationStatus.success);
    });

    // Budama bir kez başarısız olduysa Drive'da gösterilen 5 kopyadan fazlası
    // kalmış olabilir; "tümünü sil" geride görünmez dosya bırakmamalı.
    test('deleteAllBackups gösterilen 5 kopyayla sınırlı kalmaz', () async {
      signedIn();
      stubGet(
        list: http.Response(
          jsonEncode({
            'files': [
              for (var i = 0; i < 8; i++) _driveFileJson(id: 'f$i'),
            ],
          }),
          200,
        ),
      );
      stubDelete();

      final result = await service.deleteAllBackups();

      expect(result.status, DriveOperationStatus.success);
      verify(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
          .called(8);

      final listUri = verify(() => mockHttpClient.get(
            captureAny(),
            headers: any(named: 'headers'),
          )).captured.last as Uri;
      expect(int.parse(listUri.queryParameters['pageSize']!),
          greaterThan(GoogleDriveBackupService.maxGenerations));
    });

    test('yedek yokken silme başarı sayılır (no-op)', () async {
      signedIn();
      stubGet();

      final result = await service.deleteAllBackups();

      expect(result.status, DriveOperationStatus.success);
      verifyNever(
          () => mockHttpClient.delete(any(), headers: any(named: 'headers')));
    });

    test('sunucu hatasında silme başarısız raporlanır', () async {
      signedIn();
      stubDelete(500);

      final result = await service.deleteBackup('file123');

      expect(result.status, DriveOperationStatus.serverError);
    });
  });
}
