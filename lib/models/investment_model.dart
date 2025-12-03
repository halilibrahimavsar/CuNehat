import 'package:hive/hive.dart';

part 'investment_model.g.dart'; // build_runner ile oluşacak

@HiveType(typeId: 0)
class InvestmentModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String symbol; // HISSE: BIST kodu, KRIPTO: BTCUSDT gibi

  @HiveField(2)
  String type; // Hisse, Fon, Altın, Kripto, Döviz

  @HiveField(3)
  double quantity;

  @HiveField(4)
  double buyPrice; // Alış fiyatı birim fiyat

  @HiveField(5)
  double currentPrice; // Güncel birim fiyat (manuel girilecek veya API ile)

  @HiveField(6)
  DateTime buyDate;

  InvestmentModel({
    required this.name,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.buyPrice,
    this.currentPrice = 0.0,
    required this.buyDate,
  });

  double get totalCost => quantity * buyPrice;
  double get currentValue => quantity * currentPrice;
  double get profitLoss => currentValue - totalCost;
  double get profitLossPercent =>
      totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;
}
