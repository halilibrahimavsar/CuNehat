import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A theme-aware premium investment pie chart component.
class InvestmentChart extends StatelessWidget {
  const InvestmentChart({
    super.key,
    required this.investments,
  });

  final List<InvestmentEntity> investments;

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
                sections: _buildSections(),
                centerSpaceRadius: 44,
                sectionsSpace: 3,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ..._buildLegend(context, theme),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final totalValue = investments.fold(
      0.0,
      (sum, investment) => sum + investment.currentValue,
    );

    return investments.map((investment) {
      final percentage =
          totalValue > 0 ? (investment.currentValue / totalValue) * 100 : 0;

      return PieChartSectionData(
        color: investment.color,
        value: investment.currentValue,
        title: '${percentage.toStringAsFixed(1)}%',
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
      );
    }).toList();
  }

  List<Widget> _buildLegend(BuildContext context, ThemeData theme) {
    final scheme = theme.colorScheme;
    final totalValue = investments.fold(0.0, (sum, i) => sum + i.currentValue);

    return investments.map((investment) {
      final percentage = totalValue > 0
          ? (investment.currentValue / totalValue * 100).toStringAsFixed(1)
          : '0.0';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: investment.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                investment.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              context.l10n.percentage(percentage),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
