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
}
