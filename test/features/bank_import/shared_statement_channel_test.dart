import 'package:cunehat/features/bank_import/data/shared_statement_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('dev.halilibrahim.cunehat/shared_statement');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  test('bekleyen paylaşımın önbellek yolunu döner', () async {
    MethodCall? seen;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      seen = call;
      return '/data/cache/bank_import_shared/Hesap Özeti.pdf';
    });

    final path = await SharedStatementChannel().consume();

    expect(seen?.method, 'consume');
    expect(path, '/data/cache/bank_import_shared/Hesap Özeti.pdf');
  });

  test('bekleyen paylaşım yoksa null', () async {
    messenger.setMockMethodCallHandler(_channel, (_) async => null);

    expect(await SharedStatementChannel().consume(), isNull);
  });

  test('native hata FIRLATMAZ, null döner', () async {
    // Sağlayıcı ölmüş / URI izni düşmüş / boyut sınırı aşılmış. Ortada
    // açılmış bir ekran yok: çağıran taraf sessizce vazgeçebilmeli.
    messenger.setMockMethodCallHandler(_channel, (_) async {
      throw PlatformException(code: 'share_read_failed', message: 'boom');
    });

    expect(await SharedStatementChannel().consume(), isNull);
  });

  test('eklenti yoksa (Android dışı platform) null', () async {
    // Kayıtlı işleyici yok → MissingPluginException. Çağıran tarafın platform
    // ayrımı yapması gerekmesin diye burada yutuluyor.
    expect(await SharedStatementChannel().consume(), isNull);
  });
}
