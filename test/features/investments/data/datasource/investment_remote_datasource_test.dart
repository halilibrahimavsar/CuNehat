import 'dart:convert';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/features/investments/data/datasource/investment_remote_datasource.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InvestmentRemoteDataSourceImpl dataSource;
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() async {
    mockClient = MockHttpClient();
    // Kur servisi aynı mock http istemcisini kullanır; prefs temiz başlar
    // ki bayat-önbellek yedeği testlere sızmasın.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = InvestmentRemoteDataSourceImpl(
      client: mockClient,
      exchangeRateService:
          ExchangeRateService(client: mockClient, prefs: prefs),
    );
  });

  group('InvestmentRemoteDataSourceImpl', () {
    const goldResponse = {
      'Update_Date': '2026-06-13',
      'Gram Altın': {'Alış': '2.500,50', 'Satış': '2.550,75'},
    };

    const yahooResponseTry = {
      'chart': {
        'result': [
          {
            'meta': {
              'regularMarketPrice': 100.0,
              'currency': 'TRY',
            }
          }
        ]
      }
    };

    const yahooResponseUsd = {
      'chart': {
        'result': [
          {
            'meta': {
              'regularMarketPrice': 150.0,
              'currency': 'USD',
            }
          }
        ]
      }
    };

    const truncgilFxResponse = {
      'USD': {'Satış': '32,50'},
    };

    test('getLiveQuote gold returns priceTl correctly', () async {
      when(() => mockClient
              .get(Uri.parse('https://finans.truncgil.com/today.json')))
          .thenAnswer((_) async => http.Response(json.encode(goldResponse), 200,
              headers: {'content-type': 'application/json; charset=utf-8'}));

      final quote = await dataSource.getLiveQuote(
          symbol: 'Gram Altın', type: InvestmentType.gold);

      expect(quote.price, 2550.75);
      expect(quote.currency, 'TRY');
      expect(quote.priceTl, 2550.75);
    });

    test('getLiveQuote gold throws ServerException when goldType not found',
        () async {
      when(() => mockClient
              .get(Uri.parse('https://finans.truncgil.com/today.json')))
          .thenAnswer((_) async => http.Response(json.encode(goldResponse), 200,
              headers: {'content-type': 'application/json; charset=utf-8'}));

      expect(
        () => dataSource.getLiveQuote(
            symbol: 'Çeyrek Altın', type: InvestmentType.gold),
        throwsA(isA<ServerException>()),
      );
    });

    test('getLiveQuote stock in TRY returns quote correctly', () async {
      when(() => mockClient.get(Uri.parse(
              'https://query1.finance.yahoo.com/v8/finance/chart/THYAO.IS')))
          .thenAnswer(
              (_) async => http.Response(json.encode(yahooResponseTry), 200));

      final quote = await dataSource.getLiveQuote(
          symbol: 'THYAO.IS', type: InvestmentType.stock);

      expect(quote.price, 100.0);
      expect(quote.currency, 'TRY');
      expect(quote.priceTl, 100.0);
    });

    test(
        'getLiveQuote stock in USD converts currency and returns quote correctly',
        () async {
      when(() => mockClient.get(Uri.parse(
              'https://query1.finance.yahoo.com/v8/finance/chart/AAPL')))
          .thenAnswer(
              (_) async => http.Response(json.encode(yahooResponseUsd), 200));
      when(() => mockClient
              .get(Uri.parse('https://finans.truncgil.com/today.json')))
          .thenAnswer((_) async => http.Response(
              json.encode(truncgilFxResponse), 200,
              headers: {'content-type': 'application/json; charset=utf-8'}));

      final quote = await dataSource.getLiveQuote(
          symbol: 'AAPL', type: InvestmentType.stock);

      expect(quote.price, 150.0);
      expect(quote.currency, 'USD');
      expect(quote.priceTl, 150.0 * 32.50); // 4875.0
    });

    test('getLiveQuote stock throws ServerException on unsupported currency',
        () async {
      final yahooResponseGbp = {
        'chart': {
          'result': [
            {
              'meta': {
                'regularMarketPrice': 150.0,
                'currency': 'GBP',
              }
            }
          ]
        }
      };

      when(() => mockClient.get(Uri.parse(
              'https://query1.finance.yahoo.com/v8/finance/chart/AAPL')))
          .thenAnswer(
              (_) async => http.Response(json.encode(yahooResponseGbp), 200));

      expect(
        () =>
            dataSource.getLiveQuote(symbol: 'AAPL', type: InvestmentType.stock),
        throwsA(isA<ServerException>()),
      );
    });

    test('getFxRateToTry throws ServerException when rate is invalid/missing',
        () async {
      final invalidFxResponse = {
        'USD': {'Satış': '0.0'},
      };

      when(() => mockClient.get(Uri.parse(
              'https://query1.finance.yahoo.com/v8/finance/chart/AAPL')))
          .thenAnswer(
              (_) async => http.Response(json.encode(yahooResponseUsd), 200));
      when(() => mockClient
              .get(Uri.parse('https://finans.truncgil.com/today.json')))
          .thenAnswer((_) async => http.Response(
              json.encode(invalidFxResponse), 200,
              headers: {'content-type': 'application/json; charset=utf-8'}));

      expect(
        () =>
            dataSource.getLiveQuote(symbol: 'AAPL', type: InvestmentType.stock),
        throwsA(isA<ServerException>()),
      );
    });

    test('throws ServerException when response status is not 200', () async {
      when(() => mockClient.get(Uri.parse(
              'https://query1.finance.yahoo.com/v8/finance/chart/AAPL')))
          .thenAnswer((_) async => http.Response('Error', 500));

      expect(
        () =>
            dataSource.getLiveQuote(symbol: 'AAPL', type: InvestmentType.stock),
        throwsA(isA<ServerException>()),
      );
    });

    test(
        'getLiveQuote gold throws ServerException when gold API fails (non-200)',
        () async {
      when(() => mockClient
              .get(Uri.parse('https://finans.truncgil.com/today.json')))
          .thenAnswer((_) async => http.Response('Error', 500));

      expect(
        () => dataSource.getLiveQuote(
            symbol: 'Gram Altın', type: InvestmentType.gold),
        throwsA(isA<ServerException>()),
      );
    });

    test(
        'getLiveQuote gold throws ServerException when gold price cannot be parsed',
        () async {
      final invalidGoldResponse = {
        'Gram Altın': {'Alış': '2.500,50'}
      };
      when(() => mockClient
              .get(Uri.parse('https://finans.truncgil.com/today.json')))
          .thenAnswer((_) async => http.Response(
              json.encode(invalidGoldResponse), 200,
              headers: {'content-type': 'application/json; charset=utf-8'}));

      expect(
        () => dataSource.getLiveQuote(
            symbol: 'Gram Altın', type: InvestmentType.gold),
        throwsA(isA<ServerException>()),
      );
    });

    test(
        'getLiveQuote throws ServerException on generic exception in stock flow',
        () async {
      when(() => mockClient.get(Uri.parse(
              'https://query1.finance.yahoo.com/v8/finance/chart/AAPL')))
          .thenThrow(Exception('Socket Exception or generic error'));

      expect(
        () =>
            dataSource.getLiveQuote(symbol: 'AAPL', type: InvestmentType.stock),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
