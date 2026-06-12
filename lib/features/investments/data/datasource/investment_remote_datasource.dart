import 'dart:convert';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/core/utils/tr_price_parser.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

abstract class InvestmentRemoteDataSource {
  /// Sembol/altın türü için canlı fiyatı para birimiyle birlikte getirir;
  /// TRY dışı birimler güncel kurla TL'ye çevrilir.
  Future<LivePriceQuote> getLiveQuote({
    required String symbol,
    required InvestmentType type,
  });
}

@LazySingleton(as: InvestmentRemoteDataSource)
class InvestmentRemoteDataSourceImpl implements InvestmentRemoteDataSource {
  final http.Client client;

  InvestmentRemoteDataSourceImpl({required this.client});

  static const _truncgilUrl = 'https://finans.truncgil.com/today.json';

  /// Truncgil today.json'daki kur anahtarları; desteklenmeyen birimler
  /// (örn. GBp) hata verir ki portföye karışık birim değer yazılmasın.
  static const _fxKeys = {'USD': 'USD', 'EUR': 'EUR'};

  @override
  Future<LivePriceQuote> getLiveQuote({
    required String symbol,
    required InvestmentType type,
  }) async {
    try {
      if (type == InvestmentType.gold) {
        final price = await _fetchGoldPrice(symbol);
        return LivePriceQuote(price: price, currency: 'TRY', priceTl: price);
      }
      return await _fetchStockQuote(symbol);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<LivePriceQuote> _fetchStockQuote(String symbol) async {
    // Sembol tam haliyle kullanılır (BIST: THYAO.IS, ABD: AAPL);
    // koşulsuz .IS eki yabancı sembolleri bozar.
    final response = await client.get(
      Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$symbol'),
    );

    if (response.statusCode != 200) {
      throw ServerException('Hisse fiyatı alınamadı: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final meta = data['chart']['result'][0]['meta'];
    final price = (meta['regularMarketPrice'] as num).toDouble();
    final currency = (meta['currency'] as String?)?.toUpperCase() ?? 'TRY';

    if (currency == 'TRY') {
      return LivePriceQuote(price: price, currency: 'TRY', priceTl: price);
    }

    final rate = await getFxRateToTry(currency);
    return LivePriceQuote(
      price: price,
      currency: currency,
      priceTl: price * rate,
    );
  }

  /// 1 birim [currency] için TL kuru (truncgil 'Satış').
  Future<double> getFxRateToTry(String currency) async {
    final key = _fxKeys[currency.toUpperCase()];
    if (key == null) {
      throw ServerException('Desteklenmeyen para birimi: $currency');
    }

    final data = await _fetchTruncgil();
    final entry = data[key];
    final rate = parseTrPrice(entry is Map ? entry['Satış'] : null);
    if (rate == null || rate <= 0) {
      throw ServerException('Kur alınamadı: $currency');
    }
    return rate;
  }

  Future<double> _fetchGoldPrice(String goldType) async {
    final data = await _fetchTruncgil();
    if (!data.containsKey(goldType)) {
      throw ServerException('Altın türü bulunamadı: $goldType');
    }
    // API sürümüne göre alan num ya da Türkçe biçimli string olabilir;
    // koşulsuz nokta silme "4250.5"i 42505 yapardı. Kullanıcının alacağı
    // fiyat 'Satış'tır; UI ile tutarlı.
    final entry = data[goldType];
    final price = parseTrPrice(entry is Map ? entry['Satış'] : null);
    if (price == null) {
      throw ServerException('Altın fiyatı ayrıştırılamadı: $goldType');
    }
    return price;
  }

  Future<Map<String, dynamic>> _fetchTruncgil() async {
    final response = await client.get(Uri.parse(_truncgilUrl));
    if (response.statusCode != 200) {
      throw ServerException('Fiyat servisi yanıt vermedi: '
          '${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
