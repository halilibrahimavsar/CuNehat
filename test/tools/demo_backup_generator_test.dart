import 'dart:convert';
import 'dart:io';

import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class _MockHive extends Mock implements HiveInterface {}

class _MockNotifications extends Mock implements NotificationService {}

class _MockReminderSync extends Mock implements ReminderSyncService {}

/// `tools/make_demo_backup.py` ŞEMADAN KOPMASIN.
///
/// Üreteç bir kez v7'de kalmışken şema 9'a çıkmıştı; yedek sürüm kapılı
/// olduğu için ürettiği dosya sessizce reddediliyordu ve bu ancak cihazda
/// içe aktarmayı deneyince fark ediliyordu. Bu test betiği gerçekten
/// çalıştırıp çıktısını UYGULAMANIN KENDİ ayrıştırıcısına veriyor.
///
/// `inspectBackup` bilinçli tercih: içe aktarmanın kullandığı ayrıştırıcının
/// aynısını çağırıyor (bkz. servisin doküman yorumu), yani "önizleme geçti
/// ama geri yükleme patladı" durumu olamaz.
void main() {
  late final String? python;
  late final DataSerializationService service;

  setUpAll(() {
    // `inspectBackup` hiçbir instance durumuna dokunmuyor (yalnız ayrıştırır),
    // bağımlılıklar yalnız kurucuyu doyurmak için.
    service = DataSerializationService.withHive(
      _MockHive(),
      ReceiptStorageService.withBaseDir(Directory.systemTemp),
      _MockNotifications(),
      _MockReminderSync(),
    );
    python = ['python3', 'python']
        .cast<String?>()
        .firstWhere(_canRun, orElse: () => null);
  });

  test('üreteç güncel şemada, içe aktarılabilir bir yedek üretir', () async {
    if (python == null) {
      markTestSkipped('python3 bulunamadı');
      return;
    }

    final tempDir =
        await Directory.systemTemp.createTemp('cunehat_demo_backup_');
    final outPath = '${tempDir.path}/demo.json';
    try {
      final run = Process.runSync(
        python!,
        ['tools/make_demo_backup.py', outPath],
        workingDirectory: Directory.current.path,
      );
      expect(run.exitCode, 0, reason: 'üreteç hata verdi: ${run.stderr}');

      final raw = await File(outPath).readAsString();
      final inspection = service.inspectBackup(raw);

      expect(
        inspection.status,
        BackupInspectionStatus.ok,
        reason: 'üretilen yedek geri yüklenemiyor: ${inspection.status}',
      );

      // Ekran görüntüsü seti bu bölümlerin DOLU olmasına dayanıyor; biri
      // boşalırsa ilgili kare "kimse kullanmıyor" izlenimi verir.
      final summary = inspection.summary!;
      expect(summary.walletCount, greaterThanOrEqualTo(2));
      expect(summary.transactionCount, greaterThan(100));
      expect(summary.budgetCount, greaterThan(0));
      expect(summary.debtCount, greaterThan(0));
      expect(summary.investmentCount, greaterThan(0));
      expect(summary.recurringCount, greaterThan(0));
      expect(summary.categoryCount, greaterThan(0));
      // Hedefler yeni vitrin karesi: v9'un ana özelliği.
      expect(summary.goalCount, greaterThan(0));

      // Her yatırım gerçek bir hedefe ya da hiçbirine bağlı olmalı; silinmiş
      // hedefe işaret eden kayıt hiçbir listede görünmez.
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final goalIds = {
        for (final g in decoded['goals'] as List) (g as Map)['id'] as String
      };
      for (final inv in decoded['investments'] as List) {
        final goalId = (inv as Map)['goalId'] as String?;
        if (goalId != null) {
          expect(goalIds, contains(goalId),
              reason: '${inv['name']} var olmayan hedefe bağlı');
        }
      }
    } finally {
      await tempDir.delete(recursive: true);
    }
  });
}

bool _canRun(String? exe) {
  try {
    return Process.runSync(exe!, ['--version']).exitCode == 0;
  } catch (_) {
    return false;
  }
}
