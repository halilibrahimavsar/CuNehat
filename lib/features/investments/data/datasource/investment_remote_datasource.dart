import 'dart:convert';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

abstract class InvestmentRemoteDataSource {
  /// Fetches the live price for a given symbol or gold type.
  Future<double> getLivePrice({
    required String symbol,
    required InvestmentType type,
  });
}

@LazySingleton(as: InvestmentRemoteDataSource)
class InvestmentRemoteDataSourceImpl implements InvestmentRemoteDataSource {
  final http.Client client;

  InvestmentRemoteDataSourceImpl({required this.client});

  @override
  Future<double> getLivePrice({
    required String symbol,
    required InvestmentType type,
  }) async {
    try {
      if (type == InvestmentType.gold) {
        return await _fetchGoldPrice(symbol);
      } else {
        return await _fetchStockPrice(symbol);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<double> _fetchStockPrice(String symbol) async {
    final response = await client.get(
      Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$symbol.IS'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final price =
          data['chart']['result'][0]['meta']['regularMarketPrice'] as num;
      return price.toDouble();
    } else {
      throw ServerException('Hisse fiyatı alınamadı: ${response.statusCode}');
    }
  }

  Future<double> _fetchGoldPrice(String goldType) async {
    final response = await client.get(
      Uri.parse('https://finans.truncgil.com/today.json'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey(goldType)) {
        final priceStr = data[goldType]['Alış'] as String;
        return double.parse(priceStr.replaceAll('.', '').replaceAll(',', '.'));
      } else {
        throw ServerException('Altın türü bulunamadı: $goldType');
      }
    } else {
      throw ServerException('Altın fiyatı alınamadı: ${response.statusCode}');
    }
  }
}
