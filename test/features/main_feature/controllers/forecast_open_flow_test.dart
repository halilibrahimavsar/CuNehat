import 'package:cunehat/features/main_feature/controllers/forecast_open_flow.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:flutter_test/flutter_test.dart';

/// QA O8: bildirim → (gerekirse) cüzdan geçişi → Gelecek akışının testi
/// yoktu. Akış ana sayfadan [ForecastOpenFlow]'a çıkarıldı; burada widget'sız
/// sınanır.
void main() {
  final t0 = DateTime(2026, 11, 10, 9);
  late DateTime now;
  late HomeNavigationRequests requests;
  late List<String> switches;
  late int opens;
  late ForecastOpenFlow flow;

  setUp(() {
    now = t0;
    requests = HomeNavigationRequests();
    switches = [];
    opens = 0;
    flow = ForecastOpenFlow(
      requests,
      switchWallet: switches.add,
      open: () => opens++,
      clock: () => now,
    );
  });

  tearDown(() => requests.dispose());

  void notify({String? walletId, DateTime? day}) =>
      requests.openForecast(walletId: walletId, day: day, now: now);

  test('başka cüzdanın bildirimi: önce BİR KEZ geçilir, geçiş bitince açılır',
      () {
    notify(walletId: 'b', day: DateTime(2026, 11, 20));
    flow.begin(walletIds: ['a', 'b'], activeWalletId: 'a');
    expect(switches, ['b']);
    expect(opens, 0);
    expect(flow.waiting, isTrue);

    // Geçiş sürerken gelen ara kare aynı geçişi yeniden istemez.
    flow.step(walletIds: ['a', 'b'], activeWalletId: 'a');
    expect(switches, ['b']);

    flow.step(walletIds: ['a', 'b'], activeWalletId: 'b');
    expect(opens, 1);
    expect(flow.waiting, isFalse);
    // Odak isteği Gelecek'e bırakılır (tahmin görünür, ufuk bildirimin gününe).
    expect(requests.forecastFocus.value?.day, DateTime(2026, 11, 20));
    expect(requests.peekForecastOpen(now: now), isNull);
  });

  test('bildirim aktif cüzdanınsa hemen açılır, geçiş yok', () {
    notify(walletId: 'a');
    flow.begin(walletIds: ['a', 'b'], activeWalletId: 'a');
    expect(switches, isEmpty);
    expect(opens, 1);
  });

  test('soğuk açılış: cüzdanlar yüklenene kadar bekler', () {
    notify(walletId: 'b');
    flow.begin(walletIds: null, activeWalletId: null);
    expect(switches, isEmpty);
    expect(opens, 0);
    expect(flow.waiting, isTrue);

    flow.step(walletIds: ['a', 'b'], activeWalletId: 'b');
    expect(opens, 1);
  });

  test('bildirimin cüzdanı silinmişse aktif cüzdanda açılır', () {
    notify(walletId: 'gone');
    flow.begin(walletIds: ['a'], activeWalletId: 'a');
    expect(switches, isEmpty);
    expect(opens, 1);
  });

  test('istek ömrünü aşınca düşer: sonraki cüzdan değişimi Gelecek açmaz', () {
    notify(walletId: 'b');
    flow.begin(walletIds: null, activeWalletId: null);

    now = t0.add(
        HomeNavigationRequests.forecastFocusTtl + const Duration(minutes: 1));
    flow.step(walletIds: ['a', 'b'], activeWalletId: 'b');
    expect(opens, 0);
    expect(flow.waiting, isFalse);
  });

  test('geçiş başarısızsa istek düşer', () {
    notify(walletId: 'b');
    flow.begin(walletIds: ['a', 'b'], activeWalletId: 'a');
    expect(flow.switchingTo, 'b');

    flow.fail();
    expect(flow.waiting, isFalse);
    expect(flow.switchingTo, isNull);
    expect(requests.peekForecastOpen(now: now), isNull);

    flow.step(walletIds: ['a', 'b'], activeWalletId: 'b');
    expect(opens, 0);
  });
}
