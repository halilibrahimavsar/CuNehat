import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/cash_pots.dart';
import 'package:flutter/material.dart';

/// Portföy dağılımının neye göre dilimlendiği.
enum PortfolioBreakdown {
  /// Her kayıt bir dilim.
  asset,

  /// Kayıtlar türüne göre toplanır (altın, hisse, özel, nakit).
  type,
}

/// Dağılımın bir dilimi; halka ve efsane AYNI listeden çizilir.
@immutable
class PortfolioSlice {
  const PortfolioSlice({
    required this.key,
    required this.name,
    required this.value,
    required this.percent,
    required this.color,
    this.memberKeys = const [],
  });

  /// Dilimin kimliği (seçim durumu bununla tutulur).
  final String key;
  final String name;
  final double value;

  /// Toplamdaki payı, 0–100.
  final double percent;
  final Color color;

  /// Halkadaki "Diğer" dilimi için: içine katlanan dilimlerin anahtarları.
  final List<String> memberKeys;
}

/// Halkada birden çok küçük dilimin katlandığı kovanın anahtarı.
const String kPortfolioOtherKey = '__other__';

/// Bu payın altındaki dilimler halkada tek "Diğer" dilimine katlanır.
const double kPortfolioFoldBelowPercent = 2.0;

/// Tür dilimlerinin sabit renkleri (tür kipinde kaydın kendi rengi anlamsız:
/// aynı türde farklı renkli kayıtlar olabilir).
Color portfolioTypeColor(InvestmentType type) => switch (type) {
      InvestmentType.gold => Colors.amber,
      InvestmentType.stock => Colors.blue,
      InvestmentType.custom => Colors.purple,
      InvestmentType.cash => kCashPotColor,
    };

/// Kayıtları dilime çevirir: BÜYÜKTEN KÜÇÜĞE sıralı, renkleri benzersiz.
///
/// Renk: her ekleme sayfası sabit bir varsayılan renk veriyor (altın hep
/// amber), ad boş bırakılırsa da tür etiketine düşüyor. İki gram altın kaydı
/// olan kullanıcı efsanede birbirinin AYNI iki satır görüyordu. Çözüm rengi
/// ezmek değil, çakışanı aynı renk ailesinde kaydırmak: ton korunur (altın
/// hâlâ sarıdır, kartıyla eşleşir), parlaklık adım adım değişir. Renk
/// sıralamadan SONRA atanır: en büyük dilim kendi rengini korur.
List<PortfolioSlice> buildPortfolioSlices(
  List<InvestmentEntity> investments, {
  required PortfolioBreakdown by,
  required String Function(InvestmentType type) typeLabel,
}) {
  final total = investments.fold<double>(0.0, (sum, i) => sum + i.currentValue);
  double share(double value) => total > 0 ? (value / total) * 100 : 0.0;

  if (by == PortfolioBreakdown.type) {
    final sums = <InvestmentType, double>{};
    for (final i in investments) {
      sums[i.type] = (sums[i.type] ?? 0) + i.currentValue;
    }
    final types = sums.keys.toList()
      ..sort((a, b) {
        final byValue = sums[b]!.compareTo(sums[a]!);
        return byValue != 0 ? byValue : a.index.compareTo(b.index);
      });
    return [
      for (final type in types)
        PortfolioSlice(
          key: 'type-${type.name}',
          name: typeLabel(type),
          value: sums[type]!,
          percent: share(sums[type]!),
          color: portfolioTypeColor(type),
        ),
    ];
  }

  // Kimliksiz kayıt (henüz yazılmamış) için konumdan anahtar.
  final keyed = [
    for (var n = 0; n < investments.length; n++)
      (key: investments[n].id ?? 'index-$n', item: investments[n]),
  ]..sort((a, b) {
      final byValue = b.item.currentValue.compareTo(a.item.currentValue);
      return byValue != 0 ? byValue : a.key.compareTo(b.key);
    });

  final used = <int>{};
  return [
    for (final e in keyed)
      PortfolioSlice(
        key: e.key,
        name: e.item.name,
        value: e.item.currentValue,
        percent: share(e.item.currentValue),
        color: _distinct(e.item.color, used),
      ),
  ];
}

/// Halkaya çizilecek dilimler: [kPortfolioFoldBelowPercent] altındaki
/// dilimlerden BİRDEN ÇOK varsa tek "Diğer" dilimine katlanır.
///
/// Onlarca kırıntı dilim halkayı birkaç piksellik çizgilere bölüyor, aradaki
/// boşluklar toplamda gerçek paylardan fazla yer tutuyordu. Efsane katlamaz:
/// her kaydın payı orada ayrı okunur. Tek küçük dilim katlanmaz — yalnız adı
/// değişmiş olurdu.
List<PortfolioSlice> foldPortfolioRing(
  List<PortfolioSlice> slices, {
  required String otherLabel,
  required Color otherColor,
}) {
  final small = [
    for (final s in slices)
      if (s.percent < kPortfolioFoldBelowPercent) s,
  ];
  if (small.length < 2) return slices;
  return [
    for (final s in slices)
      if (s.percent >= kPortfolioFoldBelowPercent) s,
    PortfolioSlice(
      key: kPortfolioOtherKey,
      name: otherLabel,
      value: small.fold(0.0, (sum, s) => sum + s.value),
      percent: small.fold(0.0, (sum, s) => sum + s.percent),
      color: otherColor,
      memberKeys: [for (final s in small) s.key],
    ),
  ];
}

/// [seed] daha önce kullanılmadıysa aynen döner; kullanıldıysa parlaklığı
/// kaydırarak boş bir tona iner. Sınırlara dayanınca ters yöne geçer;
/// hiçbir adım tutmazsa (pratikte 12+ aynı renk) seed'in kendisi döner —
/// gösterim asla düşmez.
Color _distinct(Color seed, Set<int> used) {
  if (used.add(seed.toARGB32())) return seed;

  final hsl = HSLColor.fromColor(seed);
  for (var step = 1; step <= 6; step++) {
    for (final direction in const [1, -1]) {
      final lightness = hsl.lightness + direction * 0.12 * step;
      if (lightness < 0.18 || lightness > 0.86) continue;
      final candidate = hsl.withLightness(lightness).toColor();
      if (used.add(candidate.toARGB32())) return candidate;
    }
  }
  return seed;
}
