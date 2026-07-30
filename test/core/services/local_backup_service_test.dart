import 'dart:io';

import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/local_backup_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataSerializationService extends Mock
    implements DataSerializationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const filePickerChannel =
      MethodChannel('miguelruivo.flutter.plugins.filepicker');

  late MockDataSerializationService dataSerializationService;
  late LocalBackupService service;
  final filePickerLog = <MethodCall>[];
  dynamic filePickerResponse;

  setUp(() {
    dataSerializationService = MockDataSerializationService();
    service = LocalBackupService(dataSerializationService);
    filePickerLog.clear();
    filePickerResponse = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(filePickerChannel,
            (MethodCall methodCall) async {
      filePickerLog.add(methodCall);
      return filePickerResponse;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(filePickerChannel, null);
  });

  test('exportToDevice returns cancelled when save dialog is cancelled',
      () async {
    when(() => dataSerializationService.exportDataToJson())
        .thenAnswer((_) async => '{"version":3}');
    filePickerResponse = null;

    final result = await service.exportToDevice();

    expect(result.status, LocalBackupStatus.cancelled);
    expect(filePickerLog.single.method, 'save');
  });

  // REGRESYON: dosya adında gün ile ay yer değişikti (28 Tem 2026 →
  // `..._20262807_...`). Yedekler kronolojik sıralanmıyor ve kullanıcı geri
  // yüklerken yanlış dosyayı seçiyordu.
  test('yedek dosya adı YYYYMMDD sırasında ve bugünün tarihiyle üretilir',
      () async {
    when(() => dataSerializationService.exportDataToJson())
        .thenAnswer((_) async => '{"version":3}');
    filePickerResponse = null;

    await service.exportToDevice();

    final name = filePickerLog.single.arguments['fileName'] as String;
    final match =
        RegExp(r'^cunehat_backup_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})\.json$')
            .firstMatch(name);
    expect(match, isNotNull, reason: 'beklenen biçim dışında: $name');

    final now = DateTime.now();
    expect(int.parse(match!.group(1)!), now.year);
    expect(int.parse(match.group(2)!), now.month);
    expect(int.parse(match.group(3)!), now.day);
  });

  test('importFromDevice returns cancelled when picker is cancelled', () async {
    filePickerResponse = null;

    final result = await service.importFromDevice();

    expect(result.status, LocalBackupStatus.cancelled);
    verifyNever(() => dataSerializationService.importDataFromJson(any()));
  });

  test('importFromDevice delegates selected JSON to restore service', () async {
    final tempFile = File('${Directory.systemTemp.path}/cunehat_test.json');
    await tempFile.writeAsString('{"version":3}');
    filePickerResponse = [
      {
        'path': tempFile.path,
        'name': 'cunehat_test.json',
        'size': await tempFile.length(),
        'bytes': null,
      }
    ];
    when(() => dataSerializationService.importDataFromJson(any()))
        .thenAnswer((_) async => const DataRestoreResult.success());

    final result = await service.importFromDevice();

    expect(result.isSuccess, true);
    verify(() => dataSerializationService.importDataFromJson('{"version":3}'))
        .called(1);

    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  });

  // Cihaz yedeğinde de aynı dürüstlük kuralı: dosya sağlam, sürüm farklı.
  // `failure` deyip ham istisna metnini göstermek kullanıcıyı "yedeğim bozuk"
  // sanısına götürüyordu.
  test('sürüm uyuşmazlığı ayrı durum olarak ve bulunan sürümle döner',
      () async {
    final tempFile = File('${Directory.systemTemp.path}/cunehat_eski.json');
    await tempFile.writeAsString('{"version":2}');
    filePickerResponse = [
      {
        'path': tempFile.path,
        'name': 'cunehat_eski.json',
        'size': await tempFile.length(),
        'bytes': null,
      }
    ];
    when(() => dataSerializationService.importDataFromJson(any()))
        .thenAnswer((_) async => const DataRestoreResult.versionMismatch(2));

    final result = await service.importFromDevice();

    expect(result.status, LocalBackupStatus.versionMismatch);
    expect(result.foundVersion, 2);

    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  });

  group('pickBackupJson (önizleme yolu)', () {
    test('seçilen dosyanın adını ve içeriğini YAZMADAN döner', () async {
      final tempFile = File('${Directory.systemTemp.path}/cunehat_onizle.json');
      // Türkçe karakter: okuma utf8 olmalı, yoksa sessizce mojibake üretir.
      const payload = '{"version":4,"note":"Şişli — İĞÜÖÇ"}';
      await tempFile.writeAsString(payload);
      filePickerResponse = [
        {
          'path': tempFile.path,
          'name': 'cunehat_onizle.json',
          'size': await tempFile.length(),
          'bytes': null,
        }
      ];

      final pick = await service.pickBackupJson();

      expect(pick.isSuccess, isTrue);
      expect(pick.fileName, 'cunehat_onizle.json');
      expect(pick.content, payload);
      verifyNever(() => dataSerializationService.importDataFromJson(any()));

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('seçici kapatılırsa cancelled döner', () async {
      filePickerResponse = null;

      final pick = await service.pickBackupJson();

      expect(pick.status, LocalBackupStatus.cancelled);
      expect(pick.content, isNull);
    });
  });
}
