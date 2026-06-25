import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LivePriceQuote', () {
    test('supports value comparisons (Equatable)', () {
      expect(
        const LivePriceQuote(price: 100.0, currency: 'USD', priceTl: 3200.0),
        const LivePriceQuote(price: 100.0, currency: 'USD', priceTl: 3200.0),
      );
    });
  });
}
