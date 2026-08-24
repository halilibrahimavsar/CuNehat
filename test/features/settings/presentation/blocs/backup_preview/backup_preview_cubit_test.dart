import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:cunehat/core/services/local_backup_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/settings/presentation/blocs/backup_preview/backup_preview_cubit.dart';
import 'package:cunehat/features/settings/presentation/blocs/backup_preview/backup_preview_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDrive extends Mock implements GoogleDriveBackupService {}

class MockData extends Mock implements DataSerializationService {}

class MockLocalBackup extends Mock implements LocalBackupService {}

DriveBackupFile _file({String id = 'f1'}) => DriveBackupFile(
      id: id,
      name: 'cunehat_backup_20260730_120000.json',
      sizeBytes: 1024,
      modifiedTime: DateTime(2026, 7, 30, 12),
      md5Checksum: 'abc',
      schemaVersion: 4,
      transactionCount: 42,
      walletCount: 2,
      origin: BackupOrigin.manual,
    );

BackupSummary _summary({int transactionCount = 42}) => BackupSummary(
      schemaVersion: 4,
      createdAt: DateTime(2026, 7, 30),
      walletCount: 2,
      transactionCount: transactionCount,
      investmentCount: 0,
      debtCount: 0,
      receivableCount: 0,
      budgetCount: 0,
      recurringCount: 0,
      categoryCount: 0,
      goalCount: 0,
      wallets: const [],
      firstTransactionDate: null,
      lastTransactionDate: null,
      totalIncome: 0,
      totalExpense: 0,
      transactionsWithReceipt: 0,
    );

void main() {
  late MockDrive drive;
  late MockData data;
  late MockLocalBackup localBackup;
  late TransactionsChangedNotifier transactionsChanged;
  late CategoriesChangedNotifier categoriesChanged;
  late BackupPreviewCubit cubit;

  setUp(() {
    drive = MockDrive();
    data = MockData();
    localBackup = MockLocalBackup();
    transactionsChanged = TransactionsChangedNotifier();
    categoriesChanged = CategoriesChangedNotifier();
    cubit = BackupPreviewCubit(
      drive,
      data,
      localBackup,
      transactionsChanged,
      categoriesChanged,
    );

    when(() => data.currentDataSummary())
        .thenAnswer((_) async => _summary(transactionCount: 50));
  });

  tearDown(() {
    cubit.close();
    transactionsChanged.dispose();
    categoriesChanged.dispose();
  });

  group('liste', () {
    test('Drive kopyaları listelenir', () async {
      when(() => drive.listBackups(interactive: any(named: 'interactive')))
          .thenAnswer((_) async => DriveResult.success([_file()]));

      await cubit.loadList();

      expect(cubit.state, isA<BackupPreviewListLoaded>());
      expect((cubit.state as BackupPreviewListLoaded).files, hasLength(1));
    });

    test('hata durumu tipiyle birlikte taşınır', () async {
      when(() => drive.listBackups(interactive: any(named: 'interactive')))
          .thenAnswer((_) async =>
              const DriveResult<List<DriveBackupFile>>.failure(
                  DriveOperationStatus.noNetwork));

      await cubit.loadList();

      expect((cubit.state as BackupPreviewListFailed).status,
          DriveOperationStatus.noNetwork);
    });
  });

  group('detay', () {
    test('Drive kopyası indirilip özetlenir; cihaz özeti fark için yüklenir',
        () async {
      const raw = '{"version":4}';
      when(() => drive.downloadBackup(any()))
          .thenAnswer((_) async => const DriveResult<String>.success(raw));
      when(() => data.inspectBackup(raw))
          .thenReturn(BackupInspection.ok(_summary(), 4));

      await cubit.openDriveBackup(_file());

      final state = cubit.state as BackupPreviewDetailLoaded;
      expect(state.source, isA<DriveBackupSource>());
      expect(state.rawJson, raw);
      expect(state.inspection.isRestorable, isTrue);
      expect(state.inspection.summary!.transactionCount, 42);
      // Fark paneli cihazdaki gerçek sayıyı gösterebilmeli.
      expect(state.deviceSummary.transactionCount, 50);
    });

    test('indirme hatası detay hatası olarak yansır', () async {
      when(() => drive.downloadBackup(any())).thenAnswer(
        (_) async =>
            const DriveResult<String>.failure(DriveOperationStatus.corrupt),
      );

      await cubit.openDriveBackup(_file());

      expect((cubit.state as BackupPreviewDetailFailed).status,
          DriveOperationStatus.corrupt);
    });

    test('cihaz dosyası seçimi iptal edilirse durum değişmez', () async {
      when(() => drive.listBackups(interactive: any(named: 'interactive')))
          .thenAnswer((_) async => DriveResult.success([_file()]));
      await cubit.loadList();
      final before = cubit.state;

      when(() => localBackup.pickBackupJson())
          .thenAnswer((_) async => const LocalBackupPick.cancelled());

      await cubit.openDeviceFile();

      expect(cubit.state, same(before));
    });

    test('cihaz dosyası önizlemesi hiçbir şey yazmaz', () async {
      const raw = '{"version":4}';
      when(() => localBackup.pickBackupJson()).thenAnswer(
        (_) async => const LocalBackupPick.success('yedek.json', raw),
      );
      when(() => data.inspectBackup(raw))
          .thenReturn(BackupInspection.ok(_summary(), 4));

      await cubit.openDeviceFile();

      final state = cubit.state as BackupPreviewDetailLoaded;
      expect((state.source as DeviceFileBackupSource).fileName, 'yedek.json');
      verifyNever(() => data.importDataFromJson(any()));
    });
  });

  group('geri yükleme', () {
    Future<void> openDetail({String raw = '{"version":4}'}) async {
      when(() => drive.downloadBackup(any()))
          .thenAnswer((_) async => DriveResult<String>.success(raw));
      when(() => data.inspectBackup(raw))
          .thenReturn(BackupInspection.ok(_summary(), 4));
      await cubit.openDriveBackup(_file());
    }

    // Önizlenen içerik ile yazılan içerik AYNI olmalı: yeniden indirmek,
    // kullanıcının baktığı kopyanın değişmiş olma ihtimalini açar.
    test('önizlenen ham içerik geri yüklenir, dosya yeniden indirilmez',
        () async {
      const raw = '{"version":4,"marker":"onizlenen"}';
      await openDetail(raw: raw);
      clearInteractions(drive);
      when(() => data.importDataFromJson(any()))
          .thenAnswer((_) async => const DataRestoreResult.success());

      final status = await cubit.restoreCurrent(userId: 'u1');

      expect(status, DriveOperationStatus.success);
      verify(() => data.importDataFromJson(raw)).called(1);
      verifyNever(() => drive.downloadBackup(any()));
      verifyNever(() => drive.restoreFrom(any()));
    });

    // C1 REGRESYON: geri yükleme kategori tercihlerini de değiştiriyor ama
    // yalnız işlem kanalı bildiriliyordu; bu yüzden uygulama "lütfen yeniden
    // başlatın" demek zorunda kalıyordu.
    test('başarıda hem işlem hem KATEGORİ kanalı bildirilir', () async {
      await openDetail();
      when(() => data.importDataFromJson(any()))
          .thenAnswer((_) async => const DataRestoreResult.success());

      final transactionEvents = <TransactionsChange>[];
      final categoryEvents = <void>[];
      transactionsChanged.stream.listen(transactionEvents.add);
      categoriesChanged.stream.listen(categoryEvents.add);

      await cubit.restoreCurrent(userId: 'u1');
      await Future<void>.delayed(Duration.zero);

      expect(transactionEvents, hasLength(1));
      expect(transactionEvents.single.userId, 'u1');
      expect(categoryEvents, hasLength(1));
    });

    test('başarısızlıkta hiçbir kanal bildirilmez', () async {
      await openDetail();
      when(() => data.importDataFromJson(any())).thenAnswer(
        (_) async => const DataRestoreResult.writeFailure('disk dolu'),
      );

      final categoryEvents = <void>[];
      categoriesChanged.stream.listen(categoryEvents.add);

      final status = await cubit.restoreCurrent();
      await Future<void>.delayed(Duration.zero);

      expect(status, DriveOperationStatus.writeFailure);
      expect(categoryEvents, isEmpty);
    });

    test('geri yükleme sonrası cihaz özeti tazelenir', () async {
      await openDetail();
      when(() => data.importDataFromJson(any()))
          .thenAnswer((_) async => const DataRestoreResult.success());
      when(() => data.currentDataSummary())
          .thenAnswer((_) async => _summary(transactionCount: 42));

      await cubit.restoreCurrent();

      final state = cubit.state as BackupPreviewDetailLoaded;
      expect(state.deviceSummary.transactionCount, 42);
    });
  });

  group('silme', () {
    test('başarılı silme listeyi tazeler', () async {
      when(() => drive.deleteBackup(any()))
          .thenAnswer((_) async => const DriveResult<void>.success());
      when(() => drive.listBackups(interactive: any(named: 'interactive')))
          .thenAnswer((_) async => DriveResult.success(<DriveBackupFile>[]));

      final status = await cubit.deleteDriveBackup(_file());

      expect(status, DriveOperationStatus.success);
      expect(cubit.state, isA<BackupPreviewListLoaded>());
      expect((cubit.state as BackupPreviewListLoaded).files, isEmpty);
    });

    test('silme başarısızsa liste tazelenmez ve sebep döner', () async {
      when(() => drive.deleteBackup(any())).thenAnswer(
        (_) async => const DriveResult<void>.failure(
          DriveOperationStatus.authExpired,
        ),
      );

      final status = await cubit.deleteDriveBackup(_file());

      expect(status, DriveOperationStatus.authExpired);
      verifyNever(
          () => drive.listBackups(interactive: any(named: 'interactive')));
    });
  });
}
