import 'package:cunehat/core/services/auto_backup_service.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDriveService extends Mock implements GoogleDriveBackupService {}

DriveBackupFile _file({String? md5 = 'abc123'}) => DriveBackupFile(
      id: 'f1',
      name: 'cunehat_backup_20260730_120000.json',
      sizeBytes: 100,
      modifiedTime: DateTime(2026, 7, 30, 12),
      md5Checksum: md5,
      schemaVersion: 4,
      transactionCount: 10,
      walletCount: 1,
      origin: BackupOrigin.auto,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(BackupOrigin.manual);
  });

  late MockDriveService drive;
  late SharedPreferences prefs;
  late AutoBackupService service;

  Future<AutoBackupService> build([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    prefs = await SharedPreferences.getInstance();
    return AutoBackupService(drive, prefs);
  }

  setUp(() async {
    drive = MockDriveService();
    when(() => drive.isSignedIn).thenReturn(true);
    when(() => drive.backup(
          origin: any(named: 'origin'),
          interactive: any(named: 'interactive'),
          skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
        )).thenAnswer((_) async => DriveResult.success(_file()));
    service = await build();
  });

  tearDown(() => service.dispose());

  group('kapılar', () {
    test('varsayılan kapalı: hiçbir şey yapılmaz', () async {
      final outcome = await service.maybeRun();

      expect(outcome, isA<AutoBackupSkipped>());
      expect(
          (outcome as AutoBackupSkipped).reason, AutoBackupSkipReason.disabled);
      verifyNever(() => drive.backup(
            origin: any(named: 'origin'),
            interactive: any(named: 'interactive'),
            skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
          ));
    });

    test('bağlı hesap yoksa sessizce atlanır — hesap seçici AÇILMAZ', () async {
      service.dispose();
      service = await build({'auto_backup_frequency': 'daily'});
      when(() => drive.isSignedIn).thenReturn(false);
      when(() => drive.silentSignIn()).thenAnswer(
        (_) async => const DriveResult<GoogleSignInAccount>.failure(
          DriveOperationStatus.notSignedIn,
        ),
      );

      final outcome = await service.maybeRun();

      expect((outcome as AutoBackupSkipped).reason,
          AutoBackupSkipReason.notSignedIn);
      verifyNever(() => drive.signIn());
    });

    test('aralık dolmadıysa atlanır', () async {
      service.dispose();
      service = await build({
        'auto_backup_frequency': 'daily',
        'auto_backup_last_success_at':
            DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      });

      final outcome = await service.maybeRun();

      expect(
          (outcome as AutoBackupSkipped).reason, AutoBackupSkipReason.tooSoon);
    });

    test('aralık dolduysa yedek alınır ve origin=auto damgalanır', () async {
      service.dispose();
      service = await build({
        'auto_backup_frequency': 'daily',
        'auto_backup_last_success_at':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      });

      final outcome = await service.maybeRun();

      expect(outcome, isA<AutoBackupRan>());
      verify(() => drive.backup(
            origin: BackupOrigin.auto,
            interactive: false,
            skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
          )).called(1);
    });

    test('hiç yedek alınmamışsa ilk turda hemen çalışır', () async {
      service.dispose();
      service = await build({'auto_backup_frequency': 'weekly'});

      final outcome = await service.maybeRun();

      expect(outcome, isA<AutoBackupRan>());
    });

    // Üst üste hata genellikle kalıcıdır (yanlış yapılandırma, kapsam reddi);
    // her arka plana geçişte yeniden denemek pil ve ağ israfı olurdu.
    test('eşik aşıldıktan sonra backoff penceresinde beklenir', () async {
      service.dispose();
      service = await build({
        'auto_backup_frequency': 'daily',
        'auto_backup_failure_streak': 3,
        'auto_backup_last_attempt_at':
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      });

      final outcome = await service.maybeRun();

      expect(
          (outcome as AutoBackupSkipped).reason, AutoBackupSkipReason.backoff);
    });

    test('backoff süresi geçince yeniden denenir', () async {
      service.dispose();
      service = await build({
        'auto_backup_frequency': 'daily',
        'auto_backup_failure_streak': 3,
        'auto_backup_last_attempt_at':
            DateTime.now().subtract(const Duration(hours: 7)).toIso8601String(),
      });

      final outcome = await service.maybeRun();

      expect(outcome, isA<AutoBackupRan>());
    });
  });

  group('durum kaydı', () {
    test('başarıda içerik damgası saklanır ve sonraki tur ona bakar', () async {
      service.dispose();
      service = await build({'auto_backup_frequency': 'daily'});

      await service.maybeRun();

      expect(service.lastSuccessAt, isNotNull);
      expect(service.consecutiveFailures, 0);
      expect(prefs.getString('auto_backup_last_content_md5'), 'abc123');
    });

    test('Drive md5 vermezse damga saklanmaz (yanlış atlama olmasın)',
        () async {
      service.dispose();
      service = await build({'auto_backup_frequency': 'daily'});
      when(() => drive.backup(
            origin: any(named: 'origin'),
            interactive: any(named: 'interactive'),
            skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
          )).thenAnswer((_) async => DriveResult.success(_file(md5: null)));

      await service.maybeRun();

      expect(prefs.getString('auto_backup_last_content_md5'), isNull);
    });

    test('unchanged sonucu başarı sayılır, hata serisini artırmaz', () async {
      service.dispose();
      service = await build({
        'auto_backup_frequency': 'daily',
        'auto_backup_failure_streak': 2,
      });
      when(() => drive.backup(
            origin: any(named: 'origin'),
            interactive: any(named: 'interactive'),
            skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
          )).thenAnswer((_) async => const DriveResult<DriveBackupFile>.failure(
            DriveOperationStatus.unchanged,
          ));

      await service.maybeRun();

      expect(service.consecutiveFailures, 0);
      expect(service.lastSuccessAt, isNotNull);
    });

    test('gerçek hata serisi artırır ve eşikte uyarı bayrağı yükselir',
        () async {
      service.dispose();
      service = await build({
        'auto_backup_frequency': 'daily',
        'auto_backup_failure_streak': 2,
      });
      when(() => drive.backup(
            origin: any(named: 'origin'),
            interactive: any(named: 'interactive'),
            skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
          )).thenAnswer((_) async => const DriveResult<DriveBackupFile>.failure(
            DriveOperationStatus.serverError,
          ));

      await service.maybeRun(force: true);

      expect(service.consecutiveFailures, 3);
      expect(service.hasPersistentFailure, isTrue);
      expect(service.lastFailureStatus, DriveOperationStatus.serverError);
    });

    // "Bağlı değilsin" / "veri boş" kullanıcı durumlarıdır; 3 kez tekrarlayınca
    // kartta arıza bandı çıkarsa uyarı anlamını yitirir.
    test('boş veri sonucu hata serisini artırmaz', () async {
      service.dispose();
      service = await build({'auto_backup_frequency': 'daily'});
      when(() => drive.backup(
            origin: any(named: 'origin'),
            interactive: any(named: 'interactive'),
            skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
          )).thenAnswer((_) async => const DriveResult<DriveBackupFile>.failure(
            DriveOperationStatus.emptyLocalData,
          ));

      await service.maybeRun(force: true);

      expect(service.consecutiveFailures, 0);
      expect(service.hasPersistentFailure, isFalse);
    });

    test('clearState hesap değişiminde geçmişi siler', () async {
      service.dispose();
      service = await build({'auto_backup_frequency': 'daily'});
      await service.maybeRun();
      expect(service.lastSuccessAt, isNotNull);

      await service.clearState();

      expect(service.lastSuccessAt, isNull);
      expect(prefs.getString('auto_backup_last_content_md5'), isNull);
      expect(service.consecutiveFailures, 0);
      // Ayarın kendisi korunur: kullanıcı otomatik yedeği kapatmadı.
      expect(service.frequency, AutoBackupFrequency.daily);
    });
  });

  group('ayar', () {
    test('sıklık kalıcı yazılır', () async {
      await service.setFrequency(AutoBackupFrequency.weekly);

      expect(service.frequency, AutoBackupFrequency.weekly);
      expect(service.isEnabled, isTrue);
    });

    test('yeniden açıldığında hata serisi sıfırlanır', () async {
      service.dispose();
      service = await build({'auto_backup_failure_streak': 5});

      await service.setFrequency(AutoBackupFrequency.daily);

      expect(service.consecutiveFailures, 0);
    });
  });
}
