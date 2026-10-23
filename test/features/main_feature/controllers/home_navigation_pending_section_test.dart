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

  group('bildirimden Gelecek: o cüzdana geçilir', () {
    final at = DateTime(2026, 10, 23, 9);

    test('açma isteği cüzdanı ve günü taşır, bölümü ister, BİR KEZ tüketilir',
        () {
      final requests = HomeNavigationRequests();
      TransactionsSection? got;
      requests.sectionHandler = (s) => got = s;

      requests.openForecast(
          day: DateTime(2026, 11, 3), walletId: 'savings', now: at);

      expect(got, TransactionsSection.forecast);
      // Ana sayfa önce bakar (cüzdana geçiş sürerken), sonra tüketir.
      expect(requests.peekForecastOpen(now: at)?.walletId, 'savings');
      final f = requests.takeForecastOpen(now: at);
      expect((f?.walletId, f?.day), ('savings', DateTime(2026, 11, 3)));
      expect(requests.takeForecastOpen(now: at), isNull);
      // Sayfaya giden odak isteğini ana sayfa, cüzdan hazır olunca bırakır.
      expect(requests.forecastFocus.value, isNull);
    });

    test('soğuk açılışta bölüm isteği de bekletilir', () {
      final requests = HomeNavigationRequests();
      requests.openForecast(walletId: 'savings', now: at);
      expect(requests.takePendingSection(), TransactionsSection.forecast);
      expect(requests.peekForecastOpen(now: at)?.walletId, 'savings');
    });

    test('bayat açma isteği düşer: sonraki elle cüzdan değişimi Gelecek açmaz',
        () {
      final requests = HomeNavigationRequests();
      requests.openForecast(walletId: 'savings', now: at);
      final late = at.add(
          HomeNavigationRequests.forecastFocusTtl + const Duration(seconds: 1));
      expect(requests.peekForecastOpen(now: late), isNull);
      expect(requests.takeForecastOpen(now: late), isNull);
    });

    test('karar: cüzdanlar yüklenmediyse ya da aktif cüzdan yoksa BEKLE', () {
      expect(
          forecastOpenAction(
              targetWalletId: 'savings', walletIds: null, activeWalletId: null),
          ForecastOpenAction.wait);
      expect(
          forecastOpenAction(
              targetWalletId: null,
              walletIds: const ['main'],
              activeWalletId: null),
          ForecastOpenAction.wait);
    });

    test('karar: bildirimin cüzdanı aktif değilse ÖNCE ona geç', () {
      expect(
          forecastOpenAction(
              targetWalletId: 'savings',
              walletIds: const ['main', 'savings'],
              activeWalletId: 'main'),
          ForecastOpenAction.switchWallet);
    });

    test(
        'karar: cüzdan zaten aktif, cüzdansız (eski) yük ya da silinmiş '
        'cüzdan → AÇ', () {
      for (final target in ['main', null, 'deleted']) {
        expect(
            forecastOpenAction(
                targetWalletId: target,
                walletIds: const ['main', 'savings'],
                activeWalletId: 'main'),
            ForecastOpenAction.open,
            reason: '$target');
      }
    });
  });
}
