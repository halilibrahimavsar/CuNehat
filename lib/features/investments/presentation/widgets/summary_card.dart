import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter/material.dart';

/// A dashboard-style premium summary card for investment metrics.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.totalInvestment,
    required this.totalCurrentValue,
    required this.totalProfit,
    required this.totalProfitPercentage,
    required this.currency,
  });

  final double totalInvestment;
  final double totalCurrentValue;
  final double totalProfit;
  final double totalProfitPercentage;

  /// Cüzdanın para birimi; portföydeki tüm kayıtlar aynı cüzdana ait
  /// olduğundan toplamlar tek birimdedir.
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isProfit = totalProfit >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    return AppCard(
      section: AppSection.savings,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row containing title and trend icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Etiket harf aralıklı ve uzun; 360dp'de ikonla birlikte
              // satırı taşırıyordu (ölçüm: 283,5 + 36 > 272).
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    context.l10n.tOPLAMPortfoyDegeri,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: profitColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: profitColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Massive main balance display
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatMoney(totalCurrentValue, currency: currency),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 48,
                letterSpacing: -1.5,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            height: 1,
            color: scheme.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),

          // Maliyet ve kâr/zarar ALT ALTA: yan yana iki sütun, büyük
          // tutarlarda kartın iç genişliğini (360dp ekranda 272px) katlayarak
          // aşıyordu — ölçülen taşma 401px. Her satırda etiket solda, değer
          // sağda; değer sığmazsa küçülerek sığar, asla taşmaz.
          _MetricBlock(
            label: context.l10n.tOPLAMMaliyet,
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            value: Text(
              formatMoney(totalInvestment, currency: currency),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _MetricBlock(
            label: context.l10n.kAZANCZarar,
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            value: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Yüzde kapsülü ve tutar TEK parça olarak ölçeklenir:
                // ayrı ayrı küçülselerdi biri diğerinden büyük görünürdü.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: profitColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: profitColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    formatPercent(totalProfitPercentage,
                        decimals: 1, signed: true),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: profitColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatMoney(totalProfit, currency: currency),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: profitColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiket üstte (tam genişlik), değer altta sağa yaslı.
///
/// Etiketi değerle AYNI satıra koymak iki kötü seçenekten birini
/// dayatıyordu: ya değer küçülür ya etiket üç noktaya düşer (ölçüldü:
/// "TOPLAM MALİYET" 168px iken satırdan 86,7px pay alıyordu). Ayrı satırda
/// ikisi de tam okunur; değer yine [FittedBox] içinde, yani uzun tutarda
/// küçülerek sığar ve asla taşmaz.
class _MetricBlock extends StatelessWidget {
  final String label;
  final TextStyle? labelStyle;
  final Widget value;

  const _MetricBlock({
    required this.label,
    required this.labelStyle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: value,
        ),
      ],
    );
  }
}
