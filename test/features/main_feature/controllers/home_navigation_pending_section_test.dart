import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bildirime dokunarak soğuk açılış: ana sayfa henüz bağlanmamışken gelen
/// bölüm isteği kaybolmamalı (tahmin bildirimi Gelecek sayfasını açar).
void main() {
  test('işleyici yokken istek bekletilir ve BİR KEZ tüketilir', () {
    final requests = HomeNavigationRequests();
    requests.openSection(TransactionsSection.forecast);

    expect(requests.takePendingSection(), TransactionsSection.forecast);
    expect(requests.takePendingSection(), isNull);
  });

  test('işleyici varsa doğrudan iletilir, bekletilmez', () {
    final requests = HomeNavigationRequests();
    TransactionsSection? got;
    requests.sectionHandler = (s) => got = s;

    requests.openSection(TransactionsSection.report);

    expect(got, TransactionsSection.report);
    expect(requests.takePendingSection(), isNull);
  });

  group('Gelecek odak isteği (tahmin bildirimi)', () {
    final at = DateTime(2026, 10, 23, 9);

    test('gün taşır ve BİR KEZ tüketilir', () {
      final requests = HomeNavigationRequests();
      requests.focusForecast(day: DateTime(2026, 11, 3), now: at);

      final f = requests.takeForecastFocus(now: at);
      expect(f?.day, DateTime(2026, 11, 3));
      expect(requests.takeForecastFocus(now: at), isNull);
    });

    test('açık sayfa dinleyiciyle haber alır', () {
      final requests = HomeNavigationRequests();
      var heard = 0;
      requests.forecastFocus.addListener(() => heard++);
      requests.focusForecast(now: at);
      expect(heard, 1);
    });

    test('bayat istek düşer: sonraki elle açılış tahmini açmaz', () {
      final requests = HomeNavigationRequests();
      requests.focusForecast(now: at);
      expect(
          requests.takeForecastFocus(
              now: at.add(HomeNavigationRequests.forecastFocusTtl +
                  const Duration(seconds: 1))),
          isNull);
      expect(requests.takeForecastFocus(now: at), isNull);
    });
  });
}
