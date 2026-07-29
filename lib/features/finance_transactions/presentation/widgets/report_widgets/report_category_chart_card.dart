import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReportCategoryChartCard extends StatefulWidget {
  final String title;
  final List<CategoryData> fullData;
  final List<CategoryData> pieData;
  final bool isExpense;
  final bool showBarChart;
  final ValueChanged<bool> onToggleBarChart;
  final void Function(CategoryData cat, bool useFullData) onCategoryTap;
  final ({double progress, bool isExceeded, double limit})? Function(
      String tag, double spent) budgetProgressFor;

  /// `tag` → görünen ad. Dilim/çubuk anahtarı hep `CategoryData.name` (tag)
  /// kalır; bu harita yalnız etiket basarken kullanılır.
  final Map<String, String> categoryLabels;

  const ReportCategoryChartCard({
    super.key,
    required this.title,
    required this.fullData,
    required this.pieData,
    required this.isExpense,
    required this.showBarChart,
    required this.onToggleBarChart,
    required this.onCategoryTap,
    required this.budgetProgressFor,
    this.categoryLabels = const {},
  });

  @override
  State<ReportCategoryChartCard> createState() =>
      _ReportCategoryChartCardState();
}

class _ReportCategoryChartCardState extends State<ReportCategoryChartCard> {
  int _touchedIndex = -1;

  @override
  void didUpdateWidget(ReportCategoryChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dilim listesi değiştiğinde (tarih aralığı seçimi, işlem ekleme/silme)
    // eski indeks artık başka bir kategoriyi işaret eder; vurgu sıfırlanır.
    // Uzunluk yetmez: aynı sayıda ama farklı sıradaki kategoriler de kayar.
    if (!listEquals(
      [for (final c in oldWidget.pieData) c.name],
      [for (final c in widget.pieData) c.name],
    )) {
      _touchedIndex = -1;
    }
  }

  String _formatCurrency(BuildContext context, double value) =>
      formatMoney(value, currency: context.activeWalletCurrency);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.fullData.isEmpty) {
      return AppCard(
        section: AppSection.transactions,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatCurrency(context, 0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.titleIcinVeriYok(widget.title),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    final total = widget.fullData
        .fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    final activeData = widget.showBarChart ? widget.fullData : widget.pieData;

    final sections =
        List<PieChartSectionData>.generate(widget.pieData.length, (i) {
      final item = widget.pieData[i];
      final percent = total == 0 ? 0 : (item.totalAmount / total) * 100;
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 75.0 : 66.0;

      return PieChartSectionData(
        value: item.totalAmount,
        title: '%${percent.toStringAsFixed(0)}',
        radius: radius,
        color: item.color,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: const [
            BoxShadow(
                color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      );
    });

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.pie_chart,
                      color: !widget.showBarChart
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    onPressed: () => widget.onToggleBarChart(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.bar_chart,
                      color: widget.showBarChart
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    onPressed: () => widget.onToggleBarChart(true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatCurrency(context, total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.isExpense ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          widget.showBarChart
              ? _buildCategoryBarChart(context)
              : SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          final isTapUp = event is FlTapUpEvent;
                          int? tappedIndex;

                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              final touchIndex = pieTouchResponse
                                      ?.touchedSection?.touchedSectionIndex ??
                                  -1;
                              final actualIndex =
                                  touchIndex != -1 ? touchIndex : _touchedIndex;

                              if (isTapUp &&
                                  actualIndex != -1 &&
                                  actualIndex < widget.pieData.length) {
                                tappedIndex = actualIndex;
                              }

                              _touchedIndex = -1;
                              return;
                            }

                            final newIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                            _touchedIndex = newIndex;

                            if (isTapUp &&
                                newIndex != -1 &&
                                newIndex < widget.pieData.length) {
                              tappedIndex = newIndex;
                            }
                          });

                          if (tappedIndex != null) {
                            widget.onCategoryTap(
                                widget.pieData[tappedIndex!], false);
                          }
                        },
                      ),
                      sections: sections,
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
          const SizedBox(height: 24),
          _buildLegend(context, theme, activeData, total),
        ],
      ),
    );
  }

  Widget _buildCategoryBarChart(BuildContext context) {
    if (widget.fullData.isEmpty) return const SizedBox();

    double maxY = 0;
    for (final c in widget.fullData) {
      if (c.totalAmount > maxY) maxY = c.totalAmount;
    }
    if (maxY == 0) maxY = 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = widget.fullData.length * 50.0;
        final width =
            minWidth > constraints.maxWidth ? minWidth : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: 200,
            width: width,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY * 1.2,
                barGroups: List.generate(widget.fullData.length, (i) {
                  final cat = widget.fullData[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: cat.totalAmount,
                        color: cat.color,
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
                titlesData: const FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    if (event is FlTapUpEvent &&
                        barTouchResponse != null &&
                        barTouchResponse.spot != null) {
                      final index = barTouchResponse.spot!.touchedBarGroupIndex;
                      if (index >= 0 && index < widget.fullData.length) {
                        widget.onCategoryTap(widget.fullData[index], true);
                      }
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final cat = widget.fullData[group.x];
                      return BarTooltipItem(
                        '${cat.labelIn(context, widget.categoryLabels)}\n${_formatCurrency(context, rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegend(
    BuildContext context,
    ThemeData theme,
    List<CategoryData> data,
    double total,
  ) {
    final scheme = theme.colorScheme;
    return Column(
      children: data.map((item) {
        final percent = total == 0 ? 0 : (item.totalAmount / total) * 100;
        final budgetInfo = widget.isExpense
            ? widget.budgetProgressFor(item.name, item.totalAmount)
            : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onCategoryTap(item, widget.showBarChart),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.labelIn(context, widget.categoryLabels),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.formatMoneyItemTotalamountPercent(
                          _formatCurrency(context, item.totalAmount),
                          percent.toStringAsFixed(0)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (budgetInfo != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: budgetInfo.progress,
                        minHeight: 4,
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          budgetInfo.isExceeded
                              ? Colors.redAccent
                              : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
