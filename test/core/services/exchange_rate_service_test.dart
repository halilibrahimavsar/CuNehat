import 'dart:convert';

import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient client;

  final truncgilUri = Uri.parse('https://finans.truncgil.com/today.json');

  setUpAll(() => registerFallbackValue(Uri()));

  Future<ExchangeRateService> makeService(
      {Map<String, Object> prefsSeed = const {}}) async {
    SharedPreferences.setMockInitialValues(prefsSeed);
    final prefs = await SharedPreferences.getInstance();
    return ExchangeRateService(client: client, prefs: prefs);
  }

  void stubResponse(Map<String, dynamic> body, {int status = 200}) {
    when(() => client.get(truncgilUri)).thenAnswer(
      (_) async => http.Response(json.encode(body), status,
          headers: {'content-type': 'application/json; charset=utf-8'}),
    );
  }

  setUp(() {
    client = MockHttpClient();
  });

  test('TRY için ağa çıkmadan 1.0 döner', () async {
    final svc = await makeService();
    expect(await svc.rateToTry('TRY'), 1.0);
    expect(svc.cachedRateToTry('try'), 1.0);
    verifyNever(() => client.get(any()));
  });

  test('desteklenmeyen kod null döner, ağa çıkılmaz', () async {
    final svc = await makeService();
    expect(await svc.rateToTry('GBP'), isNull);
    verifyNever(() => client.get(any()));
  });

  test("'Satış' hem num hem Türkçe string biçiminde ayrıştırılır", () async {
    final svc = await makeService();
    stubResponse({
      'USD': {'Satış': '44,12'},
      'EUR': {'Satış': 47.5},
    });

    expect(await svc.rateToTry('USD'), 44.12);
    expect(await svc.rateToTry('EUR'), 47.5);
  });

  test('TTL içinde bellek önbelleği: tek http çağrısı', () async {
    final svc = await makeService();
    stubResponse({
      'USD': {'Satış': '44,12'},
      'EUR': {'Satış': '47,50'},
    });

    await svc.rateToTry('USD');
    await svc.rateToTry('EUR');
    await svc.rateToTry('usd');

    verify(() => client.get(truncgilUri)).called(1);
  });

  test('ağ hatasında bayat prefs önbelleği döner', () async {
    final svc = await makeService(prefsSeed: {
      'exchange_rates_cache_v1': json.encode({
        'rates': {'USD': 41.0, 'EUR': 44.0},
        'ts': '2026-01-01T00:00:00.000', // çok bayat — yine de kullanılır
      }),
    });
    when(() => client.get(truncgilUri)).thenThrow(Exception('offline'));

    expect(await svc.rateToTry('USD'), 41.0);
    expect(await svc.rateToTry('EUR'), 44.0);
  });

  test('ağ hatası + boş önbellek → null (asla fırlatmaz)', () async {
    final svc = await makeService();
    when(() => client.get(truncgilUri)).thenThrow(Exception('offline'));

    expect(await svc.rateToTry('USD'), isNull);
  });

  test('kısmi yanıt: gelen kur kullanılır, eksik kodun son değeri korunur',
      () async {
    final svc = await makeService(prefsSeed: {
      'exchange_rates_cache_v1': json.encode({
        'rates': {'USD': 41.0, 'EUR': 44.0},
        'ts': '2026-01-01T00:00:00.000',
      }),
    });
    stubResponse({
      'USD': {'Satış': '45,00'}, // EUR alanı yok
    });

    expect(await svc.rateToTry('USD'), 45.0);
    expect(await svc.rateToTry('EUR'), 44.0); // merge ile korunur
  });

  test('cachedRateToTry ağa çıkmaz; prefs varsa onu okur, yoksa null',
      () async {
    final svc = await makeService(prefsSeed: {
      'exchange_rates_cache_v1': json.encode({
        'rates': {'USD': 41.0},
        'ts': '2026-01-01T00:00:00.000',
      }),
    });

    expect(svc.cachedRateToTry('USD'), 41.0);
    expect(svc.cachedRateToTry('EUR'), isNull);
    verifyNever(() => client.get(any()));
  });

  test('HTTP 200 dışı yanıt → önbelleksizken null', () async {
    final svc = await makeService();
    stubResponse({}, status: 500);
    expect(await svc.rateToTry('USD'), isNull);
  });
}
