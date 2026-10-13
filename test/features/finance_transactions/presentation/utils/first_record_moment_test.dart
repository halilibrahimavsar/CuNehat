import 'package:cunehat/features/finance_transactions/presentation/utils/first_record_moment.dart';
import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRecords extends Mock implements SectionRecords {}

void main() {
  late SharedPreferences prefs;
  late _MockRecords records;
  late FirstRecordMoment moment;

  Future<void> build({Map<String, Object> initial = const {}}) async {
    SharedPreferences.setMockInitialValues(initial);
    prefs = await SharedPreferences.getInstance();
    records = _MockRecords();
    moment = FirstRecordMoment(prefs, records);
  }

  test('defter boşken ilk kayıt fark edilir — bir kez', () async {
    await build();
    when(() => records.transactionCount).thenReturn(0);

    expect(moment.takeIfFirst(), isTrue);
    expect(moment.takeIfFirst(), isFalse);
    expect(prefs.getBool(FirstRecordMoment.notedKey), isTrue);
  });

  test(
      'defteri dolu kullanıcıya (güncelleme, geri yükleme) "ilk kaydın" '
      'denmez; bir daha da sorulmaz', () async {
    await build();
    when(() => records.transactionCount).thenReturn(271);

    expect(moment.takeIfFirst(), isFalse);
    expect(prefs.getBool(FirstRecordMoment.notedKey), isTrue);

    // Sonradan defterini boşaltsa bile.
    when(() => records.transactionCount).thenReturn(0);
    expect(moment.takeIfFirst(), isFalse);
  });

  test('bayrak yazılıysa defter sayılmaz', () async {
    await build(initial: {FirstRecordMoment.notedKey: true});

    expect(moment.takeIfFirst(), isFalse);
    verifyNever(() => records.transactionCount);
  });

  group('ilk kayıt cümlesi', () {
    final t0 = DateTime(2026, 10, 13, 17);
    tearDown(FirstRecordMoment.cancelAnnouncement);

    test('kuyruğa alınan cümle bir kez verilir', () {
      expect(FirstRecordMoment.takeAnnouncement(now: t0), isFalse);

      FirstRecordMoment.queueAnnouncement(now: t0);

      expect(
        FirstRecordMoment.takeAnnouncement(
          now: t0.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(FirstRecordMoment.takeAnnouncement(now: t0), isFalse,
          reason: 'ikinci kayıtta sıradan "eklendi" bildirimi döner');
    });

    test(
        'bayatlayan cümle söylenmez: dakikalar sonraki bir silmenin '
        'bildiriminin yerine çıkmamalı', () {
      FirstRecordMoment.queueAnnouncement(now: t0);

      expect(
        FirstRecordMoment.takeAnnouncement(
          now: t0.add(const Duration(minutes: 3)),
        ),
        isFalse,
      );
    });

    test('kayıt hata verirse cümle iptal edilir', () {
      FirstRecordMoment.queueAnnouncement(now: t0);
      FirstRecordMoment.cancelAnnouncement();

      expect(FirstRecordMoment.takeAnnouncement(now: t0), isFalse);
    });
  });
}
