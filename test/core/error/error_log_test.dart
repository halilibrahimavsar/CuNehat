import 'dart:convert';

import 'package:cunehat/core/error/error_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _BadToString {
  @override
  String toString() => throw StateError('toString patladı');
}

void main() {
  final log = ErrorLog.instance;
  var tick = 0;

  setUp(() {
    log.resetForTest();
    tick = 0;
    // Her kayıt farklı saniyede: sıralama ve tekrar damgası ölçülebilsin.
    log.clock = () => DateTime(2026, 9, 14, 12, 0, tick++);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(log.resetForTest);

  test('kayıtlar yeniden eskiye listelenir', () {
    log.add('A', StateError('ilk'));
    log.add('B', StateError('ikinci'));

    expect(log.entries.map((e) => e.source), ['B', 'A']);
  });

  test('kapasite aşılınca en eski kayıt düşer', () {
    for (var i = 0; i < ErrorLog.capacity + 10; i++) {
      log.add('kaynak', StateError('hata $i'));
    }

    expect(log.entries, hasLength(ErrorLog.capacity));
    expect(
        log.entries.first.message, contains('hata ${ErrorLog.capacity + 9}'));
    expect(log.entries.last.message, contains('hata 10'));
  });

  test('ardışık aynı hata tek satırda sayılır', () {
    log.add('FlutterError', StateError('aynı'));
    log.add('FlutterError', StateError('aynı'));
    log.add('FlutterError', StateError('aynı'));

    expect(log.entries, hasLength(1));
    expect(log.entries.single.repeat, 3);
  });

  test('aynı hata nesnesi iki kanaldan gelirse bir kez yazılır', () {
    // Bloc handler hatası önce gözlemciye, sonra kök zone'a düşer.
    final error = StateError('bloc');
    log.add('Bloc TestCubit', error);
    log.add('PlatformDispatcher', error);

    expect(log.entries, hasLength(1));
    expect(log.entries.single.source, 'Bloc TestCubit');
  });

  test('uzun mesaj ve stack kırpılır', () {
    log.add(
      'kaynak',
      StateError('x' * 5000),
      StackTrace.fromString('y' * 5000),
    );

    final entry = log.entries.single;
    expect(entry.message.length, ErrorLog.maxMessageLength + 1);
    expect(entry.stack!.length, ErrorLog.maxStackLength + 1);
  });

  test('toString fırlatan hata günlüğü bozmaz', () {
    expect(() => log.add('kaynak', _BadToString()), returnsNormally);
    expect(log.entries.single.type, '_BadToString');
  });

  test('paylaşım metni kaynak, tekrar ve stack içerir', () {
    log.add(
      'FlutterError',
      StateError('aynı'),
      StackTrace.fromString('#0 main'),
    );
    log.add('FlutterError', StateError('aynı'));

    final text = log.formatForShare();
    expect(text, contains('FlutterError (×2)'));
    expect(text, contains('StateError: Bad state: aynı'));
    expect(text, contains('#0 main'));
  });

  test('attach öncesi kayıtlar kalıcı kayıtlarla birleşip yazılır', () async {
    final older = ErrorLogEntry(
      at: DateTime(2026, 9, 1),
      source: 'önceki oturum',
      type: 'StateError',
      message: 'eski',
    );
    SharedPreferences.setMockInitialValues({
      ErrorLog.prefsKey: jsonEncode([older.toJson()]),
    });
    final prefs = await SharedPreferences.getInstance();

    // Açılış hatası DI kurulmadan, yani prefs bağlanmadan önce doğar.
    log.add('açılış', StateError('init'));
    log.attach(prefs);

    expect(log.entries.map((e) => e.source), ['açılış', 'önceki oturum']);
    final stored = jsonDecode(prefs.getString(ErrorLog.prefsKey)!) as List;
    expect(stored, hasLength(2));
  });

  test('kalıcı günlük sonraki oturumda geri okunur', () async {
    final prefs = await SharedPreferences.getInstance();
    log.attach(prefs);
    log.add('kaynak', StateError('kalıcı'));

    log.resetForTest();
    log.attach(prefs);

    expect(log.entries.single.message, contains('kalıcı'));
  });

  test('bozuk kalıcı günlük boş başlar ve yazmaya devam eder', () async {
    SharedPreferences.setMockInitialValues({ErrorLog.prefsKey: 'json değil'});
    final prefs = await SharedPreferences.getInstance();

    expect(() => log.attach(prefs), returnsNormally);
    expect(log.entries, isEmpty);

    log.add('kaynak', StateError('yeni'));
    expect(jsonDecode(prefs.getString(ErrorLog.prefsKey)!), hasLength(1));
  });

  test('biçimi bozuk tek kayıt atlanır, diğerleri okunur', () async {
    final good = ErrorLogEntry(
      at: DateTime(2026, 9, 2),
      source: 'kaynak',
      type: 'StateError',
      message: 'sağlam',
    );
    SharedPreferences.setMockInitialValues({
      ErrorLog.prefsKey: jsonEncode([
        {'source': 3},
        good.toJson(),
      ]),
    });
    final prefs = await SharedPreferences.getInstance();

    log.attach(prefs);

    expect(log.entries.single.message, 'sağlam');
  });

  test('clear kalıcı kaydı da siler', () async {
    final prefs = await SharedPreferences.getInstance();
    log.attach(prefs);
    log.add('kaynak', StateError('silinecek'));

    await log.clear();

    expect(log.entries, isEmpty);
    expect(prefs.getString(ErrorLog.prefsKey), isNull);
  });

  testWidgets('tekrar sayısı kalıcı kayda gecikmeyle yansır', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    log.attach(prefs);

    int storedRepeat() {
      final stored = jsonDecode(prefs.getString(ErrorLog.prefsKey)!) as List;
      return (stored.single as Map)['repeat'] as int;
    }

    log.add('FlutterError', StateError('her karede'));
    log.add('FlutterError', StateError('her karede'));

    expect(storedRepeat(), 1, reason: 'tekrar her seferinde diske yazılmaz');
    await tester.pump(ErrorLog.repeatFlushDelay);
    expect(storedRepeat(), 2);
  });
}
