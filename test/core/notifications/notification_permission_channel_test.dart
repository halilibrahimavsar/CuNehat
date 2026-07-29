import 'package:cunehat/core/notifications/notification_permission_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kanal yalnızca Android'de sorgulanır; testlerde platformu taklit ediyoruz.
const _channel =
    MethodChannel('dev.halilibrahim.cunehat/notification_permission');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  final calls = <MethodCall>[];

  /// Yerel taraftan dönecek durum haritası.
  Map<String, Object?>? nativeStatus;
  bool openSettingsResult = true;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    calls.clear();
    nativeStatus = null;
    openSettingsResult = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'status' => nativeStatus,
        'openSettings' => openSettingsResult,
        _ => null,
      };
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  NotificationPermissionChannel build() => NotificationPermissionChannel(prefs);

  group('canPrompt', () {
    test('hiç sorulmadıysa sorulabilir', () async {
      nativeStatus = {
        'sdkInt': 34,
        'granted': false,
        'shouldShowRationale': false,
      };

      expect(await build().canPrompt(), isTrue);
    });

    test('bir kez reddedildi ama sistem gerekçe istiyorsa yine sorulabilir',
        () async {
      nativeStatus = {
        'sdkInt': 34,
        'granted': false,
        'shouldShowRationale': true,
      };
      await build().markRequested();

      expect(await build().canPrompt(), isTrue);
    });

    test('sorulmuş + gerekçe yok = kalıcı ret, artık sorulamaz', () async {
      nativeStatus = {
        'sdkInt': 34,
        'granted': false,
        'shouldShowRationale': false,
      };
      final channel = build();
      await channel.markRequested();

      expect(await channel.canPrompt(), isFalse);
    });

    test('izin zaten verilmişse (bildirimler ayarlardan kapalı) sorulamaz',
        () async {
      nativeStatus = {
        'sdkInt': 34,
        'granted': true,
        'shouldShowRationale': false,
      };

      // Diyalog açılmadan true dönerdi; kullanıcıyı ayarlara götürmeliyiz.
      expect(await build().canPrompt(), isFalse);
    });

    test('Android 12 ve altında çalışma zamanı izni yok; tek yol ayarlar',
        () async {
      nativeStatus = {
        'sdkInt': 32,
        'granted': true,
        'shouldShowRationale': false,
      };

      expect(await build().canPrompt(), isFalse);
    });

    test('yerel taraf yoksa (eski motor/masaüstü) kayda göre karar verilir',
        () async {
      nativeStatus = null;

      expect(await build().canPrompt(), isTrue);
      await build().markRequested();
      expect(await build().canPrompt(), isFalse);
    });
  });

  test('openSettings yerel tarafa iletilir', () async {
    expect(await build().openSettings(), isTrue);
    expect(calls.map((c) => c.method), contains('openSettings'));
  });

  test('markRequested kalıcıdır', () async {
    await build().markRequested();

    // Yeni örnek aynı prefs'i okur — uygulama yeniden başlasa da bilgi durur.
    nativeStatus = {
      'sdkInt': 34,
      'granted': false,
      'shouldShowRationale': false,
    };
    expect(await build().canPrompt(), isFalse);
  });
}
