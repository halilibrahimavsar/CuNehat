import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Portföy dağılımı halkası.
///
/// Dilim rengi kaydın KENDİ rengidir (kartında da o renk görünür), ama halka
/// içinde benzersizliği garanti edilir — bkz. [_resolveSlices].
class InvestmentChart extends StatelessWidget {
  const InvestmentChart({
    super.key,
    required this.investments,
  });

  final List<InvestmentEntity> investments;

  /// Bu payın altındaki dilime halka ÜSTÜNDE etiket yazılmaz: %0,1'lik bir
  /// dilim birkaç piksel geniştir, yazı kendi diliminin dışına taşıp komşunun
  /// ve halkanın kenarının üstüne düşüyordu. Değer zaten efsanede yazıyor.
  static const double _inlineLabelMinPercent = 4.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (investments.isEmpty) {
      return AppCard(
        section: AppSection.savings,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            context.l10n.grafikIcinYatirimBulunmuyor,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Dilimler TEK yerde kurulur: halka ile efsane ayrı ayrı hesaplayınca
    // renk benzersizleştirmesi ikisinde farklı sonuç verebilirdi.
    final slices = _resolveSlices();

    return AppCard(
      section: AppSection.savings,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.portfoyDagilimi,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  for (final slice in slices)
                    PieChartSectionData(
                      color: slice.color,
                      value: slice.value,
                      title: slice.percent >= _inlineLabelMinPercent
                          ? formatPercent(slice.percent, decimals: 1)
                          : '',
                      radius: 56,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                ],
                centerSpaceRadius: 44,
                sectionsSpace: 3,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final slice in slices) _legendRow(theme, scheme, slice),
        ],
      ),
    );
  }

  Widget _legendRow(ThemeData theme, ColorScheme scheme, _Slice slice) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: slice.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              slice.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatPercent(slice.percent, decimals: 1),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Kayıtları dilime çevirir ve RENKLERİ BENZERSİZLEŞTİRİR.
  ///
  /// Her ekleme sayfası sabit bir varsayılan renk veriyor (altın hep amber),
  /// ad boş bırakılırsa da tür etiketine düşüyor. İki gram altın kaydı olan
  /// kullanıcı efsanede birbirinin AYNI iki satır görüyordu: aynı sarı nokta,
  /// aynı "Gram Altın" yazısı — hangi dilimin hangisi olduğu anlaşılmıyordu.
  ///
  /// Çözüm rengi ezmek değil, çakışanı aynı renk ailesinde kaydırmak: ton
  /// korunur (altın hâlâ sarıdır, kartıyla eşleşir), parlaklık adım adım
  /// değişir. Sıra listenin sırasıdır, yani deterministiktir.
  List<_Slice> _resolveSlices() {
    final total = investments.fold<double>(
      0.0,
      (sum, investment) => sum + investment.currentValue,
    );

    final used = <int>{};
    return [
      for (final investment in investments)
        _Slice(
          name: investment.name,
          value: investment.currentValue,
          percent: total > 0 ? (investment.currentValue / total) * 100 : 0.0,
          color: _distinct(investment.color, used),
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
}

class _Slice {
  const _Slice({
    required this.name,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String name;
  final double value;
  final double percent;
  final Color color;
}
