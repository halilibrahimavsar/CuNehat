import 'dart:ui';
import 'package:equatable/equatable.dart';

enum InvestmentType {
  stock,
  gold,
  custom,
}

/// Bir yatırım kaydı.
///
/// PARA BİRİMİ: [amount] (maliyet) ve [currentValue] (güncel değer) her zaman
/// kaydın CÜZDANININ birimindedir — kayıtta ayrı bir değerleme birimi alanı
/// yoktur, birim `walletId`'den türetilir. Canlı fiyat başka bir birimden
/// geliyorsa çapraz kurla cüzdanın birimine çevrilerek yazılır (bkz.
/// `LivePriceQuote.convertedPrice`). [currency] ise yalnız fiyat KAYNAĞININ
/// birimidir; bilgi amaçlıdır, değerlemeye girmez.
class InvestmentEntity extends Equatable {
  final String? id;
  final String userId;
  final String walletId;
  final String name;
  final double amount;
  final double currentValue;
  final InvestmentType type;
  final Color color;
  final DateTime dateAdded;
  final String? symbol;
  final double? returnRate;

  /// Toplam birim (gram/lot/adet). null = miktar takibi olmayan yatırım
  /// (ör. özel varlık).
  final double? quantity;

  /// Bağlı olduğu birikim hedefi (`GoalEntity.id`); null → bağsız varlık.
  ///
  /// Hedef artık kaydın kendi alanı DEĞİL: bir hedefe gram altın, çeyrek
  /// altın ve hisse birlikte bağlanabilsin diye üst kayıt oldu. Bir yatırım
  /// en fazla bir hedefe bağlanır.
  final String? goalId;

  /// Fiyat KAYNAĞININ para birimi (örn. AAPL → 'USD', altın → 'TRY').
  /// Kaydın değerleme birimi DEĞİLDİR — o cüzdandan gelir; bkz. sınıf notu.
  final String? currency;

  /// [amount]'un deftere İŞLENMEMİŞ kısmı: kaydı açarken "bu varlık zaten
  /// bende, cüzdandan düşme" denen tutar. Uygulamaya girmeden önce alınmış
  /// varlıklar bugünün defterine sahte gider yazmasın diye tutulur.
  ///
  /// Silme düzeltmesi yalnız [bookedCost]'u iade eder: işlenmemiş kısım
  /// cüzdandan hiç çıkmadığı için geri de verilemez.
  final double unbookedCost;

  const InvestmentEntity({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.name,
    required this.amount,
    required this.currentValue,
    required this.type,
    required this.color,
    required this.dateAdded,
    this.symbol,
    this.returnRate,
    this.quantity,
    this.goalId,
    this.currency,
    this.unbookedCost = 0,
  });

  InvestmentEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? name,
    double? amount,
    double? currentValue,
    InvestmentType? type,
    Color? color,
    DateTime? dateAdded,
    String? symbol,
    double? returnRate,
    double? quantity,
    String? goalId,
    String? currency,
    double? unbookedCost,
  }) {
    return InvestmentEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currentValue: currentValue ?? this.currentValue,
      type: type ?? this.type,
      color: color ?? this.color,
      dateAdded: dateAdded ?? this.dateAdded,
      symbol: symbol ?? this.symbol,
      returnRate: returnRate ?? this.returnRate,
      quantity: quantity ?? this.quantity,
      goalId: goalId ?? this.goalId,
      currency: currency ?? this.currency,
      unbookedCost: unbookedCost ?? this.unbookedCost,
    );
  }

  /// Maliyetin deftere gider olarak işlenmiş kısmı; silme düzeltmesinde
  /// cüzdana iade edilecek tutar budur.
  double get bookedCost {
    final booked = amount - unbookedCost;
    return booked > 0 ? booked : 0;
  }

  double get profit => currentValue - amount;
  double get profitPercentage => amount > 0 ? (profit / amount) * 100 : 0;
  bool get isProfitable => profit >= 0;

  /// Hedefle bağı KOPARIR. `copyWith` null'ı "değiştirme" saydığı için
  /// bağı kaldırmanın ayrı bir yolu olmak zorunda.
  InvestmentEntity clearGoal() => InvestmentEntity(
        id: id,
        userId: userId,
        walletId: walletId,
        name: name,
        amount: amount,
        currentValue: currentValue,
        type: type,
        color: color,
        dateAdded: dateAdded,
        symbol: symbol,
        returnRate: returnRate,
        quantity: quantity,
        goalId: null,
        currency: currency,
        unbookedCost: unbookedCost,
      );

  /// Birim başına güncel değer; miktar takibi yoksa null.
  double? get unitValue =>
      (quantity != null && quantity! > 0) ? currentValue / quantity! : null;

  /// Fiyat yenileme yalnızca sembollü ve miktarı bilinen kayıtlarda mümkün.
  bool get canRefreshPrice =>
      symbol != null && quantity != null && quantity! > 0;

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        name,
        amount,
        currentValue,
        type,
        color,
        dateAdded,
        symbol,
        returnRate,
        quantity,
        goalId,
        currency,
        unbookedCost,
      ];
}
