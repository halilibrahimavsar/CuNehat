import 'package:cunehat/core/error/error_log.dart';
import 'package:cunehat/features/main_feature/pages/home_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(ErrorLog.instance.resetForTest);
  tearDown(ErrorLog.instance.resetForTest);

  // Kapı, bekleyen düzenli işlem hatırlatmasını ilk açılış diyaloglarının
  // arkasında tutar. Eskiden akış fırlatınca kapı hiç açılmıyor, hatırlatma o
  // oturumda bir daha çıkmıyordu.
  test('ilk açılış akışı fırlatsa da kapı açılır ve hata günlüğe yazılır',
      () async {
    var gateOpened = false;

    await runFirstLaunchThenOpenGate(
      onboarding: () async => throw StateError('özet okunamadı'),
      openGate: () => gateOpened = true,
    );

    expect(gateOpened, isTrue);
    expect(
      ErrorLog.instance.entries.single.source,
      'Ana sayfa · ilk açılış akışı',
    );
  });

  test('akış başarılıysa kapı açılır ve günlüğe bir şey yazılmaz', () async {
    var gateOpened = false;

    await runFirstLaunchThenOpenGate(
      onboarding: () async {},
      openGate: () => gateOpened = true,
    );

    expect(gateOpened, isTrue);
    expect(ErrorLog.instance.entries, isEmpty);
  });
}
