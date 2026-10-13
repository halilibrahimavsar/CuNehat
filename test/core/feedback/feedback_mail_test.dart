import 'package:cunehat/core/feedback/feedback_mail.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.halilibrahim.cunehat/feedback_mail');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  void answer(Future<Object?> Function(MethodCall) handler) {
    messenger.setMockMethodCallHandler(channel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<bool> compose() => FeedbackMail.compose(
        to: 'ornek@example.com',
        subject: 'ÇuHat görüş · v1.0.0',
        body: 'gövde',
      );

  test('alıcı, konu ve gövde yerel tarafa olduğu gibi gider', () async {
    answer((_) async => true);

    expect(await compose(), isTrue);
    expect(calls.single.method, 'compose');
    expect(calls.single.arguments, {
      'to': 'ornek@example.com',
      'subject': 'ÇuHat görüş · v1.0.0',
      'body': 'gövde',
    });
  });

  test('e-posta uygulaması yoksa false: çağıran adresi başka yolla sunar',
      () async {
    answer((_) async => false);

    expect(await compose(), isFalse);
  });

  test('yerel taraf hata verirse fırlatmaz', () async {
    answer((_) async => throw PlatformException(code: 'boom'));

    expect(await compose(), isFalse);
  });

  test('kanal hiç yoksa (eski yerel kabuk) fırlatmaz', () async {
    expect(await compose(), isFalse);
  });

  test('Android dışında kanal çağrılmaz', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    answer((_) async => true);

    expect(await compose(), isFalse);
    expect(calls, isEmpty);
  });
}
