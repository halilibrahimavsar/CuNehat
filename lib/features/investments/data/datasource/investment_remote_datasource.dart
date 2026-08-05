import 'dart:async';
import 'dart:convert';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/utils/tr_price_parser.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/entities/live_price_quote.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

abstract class InvestmentRemoteDataSource {
  /// Sembol/altın türü için canlı fiyatı para birimiyle birlikte getirir ve
  /// [targetCurrency]'ye (cüzdanın birimi) çevirir. Kaynak birimi hedefe
  /// eşitse çevrim yapılmaz; değilse kur zorunludur — alınamazsa hata verir
  /// ki portföye karışık birim değer yazılmasın.
  Future<LivePriceQuote> getLiveQuote({
    required String symbol,
    required InvestmentType type,
    required String targetCurrency,
  });
}

@LazySingleton(as: InvestmentRemoteDataSource)
class InvestmentRemoteDataSourceImpl implements InvestmentRemoteDataSource {
  final http.Client client;
  final ExchangeRateService exchangeRateService;

  InvestmentRemoteDataSourceImpl({
    required this.client,
    required this.exchangeRateService,
  });

  static const _truncgilUrl = 'https://finans.truncgil.com/today.json';

  /// Fiyat isteğinin üst sınırı; bkz. [ExchangeRateService.requestTimeout].
  /// Zaman aşımı ham `TimeoutException` olarak yukarı sızarsa mesajı
  /// (`TimeoutException after 0:00:15...`) doğrudan kullanıcıya gösterilirdi
  /// — bloc `failure.message`'ı olduğu gibi snackbar'a basıyor.
  static const requestTimeout = Duration(seconds: 15);

  /// Kur servisinin tanıdığı birimler + TRY. Desteklenmeyen birimler
  /// (örn. GBp) hata verir ki portföye karışık birim değer yazılmasın.
  static const _convertible = {'TRY', 'USD', 'EUR'};

  @override
  Future<LivePriceQuote> getLiveQuote({
    required String symbol,
    required InvestmentType type,
    required String targetCurrency,
  }) async {
    try {
      // Altın fiyatı kaynağında TL'dir; hedef TL değilse o da çevrilir.
      final (price, currency) = type == InvestmentType.gold
          ? (await _fetchGoldPrice(symbol), 'TRY')
          : await _fetchStockPrice(symbol);

      return LivePriceQuote(
        price: price,
        currency: currency,
        convertedPrice:
            await _convert(price, from: currency, to: targetCurrency),
        targetCurrency: targetCurrency.toUpperCase(),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  /// [price]'ı [from] biriminden [to] birimine çevirir. Aynı birimde çevrim
  /// yapılmaz (kur servisine hiç gidilmez → çevrimdışı da çalışır).
  Future<double> _convert(
    double price, {
    required String from,
    required String to,
  }) async {
    final source = from.toUpperCase();
    final target = to.toUpperCase();
    if (source == target) return price;

    if (!_convertible.contains(source)) {
      throw ServerException('Desteklenmeyen para birimi: $from');
    }
    if (!_convertible.contains(target)) {
      throw ServerException('Desteklenmeyen para birimi: $to');
    }

    final rate = await exchangeRateService.rateBetween(source, target);
    if (rate == null || rate <= 0) {
      throw ServerException('Kur alınamadı: $source/$target');
    }
    return price * rate;
  }

  /// Zaman aşımını uygulayan ve onu kullanıcıya gösterilebilir bir
  /// [ServerException]'a çeviren tek giriş noktası.
  Future<http.Response> _get(Uri url) async {
    try {
      return await client.get(url).timeout(requestTimeout);
    } on TimeoutException {
      throw ServerException(
        'Fiyat servisi zamanında yanıt vermedi. '
        'Bağlantınızı kontrol edip tekrar deneyin.',
      );
    }
  }

  /// Hissenin ham fiyatı ve kaynağın para birimi (çevrim [_convert]'te).
  Future<(double, String)> _fetchStockPrice(String symbol) async {
    // Sembol tam haliyle kullanılır (BIST: THYAO.IS, ABD: AAPL);
    // koşulsuz .IS eki yabancı sembolleri bozar.
    final response = await _get(
      Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$symbol'),
    );

    if (response.statusCode != 200) {
      throw ServerException('Hisse fiyatı alınamadı: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final meta = data['chart']['result'][0]['meta'];
    final price = (meta['regularMarketPrice'] as num).toDouble();
    final currency = (meta['currency'] as String?)?.toUpperCase() ?? 'TRY';
    return (price, currency);
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
    final response = await _get(Uri.parse(_truncgilUrl));
    if (response.statusCode != 200) {
      throw ServerException('Fiyat servisi yanıt vermedi: '
          '${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
