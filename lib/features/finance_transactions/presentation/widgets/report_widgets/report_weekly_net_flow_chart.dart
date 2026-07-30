import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_time_axis.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Gün gün gelir/gider çubukları.
///
/// Çubuklar renkten başka bir şey söylemediği için üstte açıklama (legend)
/// var; dokununca tooltip tam tutarı [formatMoney] ile yazar.
class ReportWeeklyNetFlowChart extends StatelessWidget {
  final List<TransactionEntity> transactions;

  const ReportWeeklyNetFlowChart({
    super.key,
    required this.transactions,
  });

  static const _incomeColor = Colors.green;
  static const _expenseColor = Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (transactions.isEmpty) return const SizedBox();

    final Map<DateTime, ReportTotals> dailyTotals = {};
    for (final t in transactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      final current = dailyTotals[day] ??
          const ReportTotals(totalIncome: 0, totalExpense: 0, net: 0);
      dailyTotals[day] = ReportTotals(
        totalIncome: current.totalIncome + (t.isIncome ? t.amount : 0),
        totalExpense: current.totalExpense + (t.isExpense ? t.amount : 0),
        net: 0,
      );
    }

    final entries = dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) return const SizedBox();

    final maxVal = entries.fold<double>(0.0, (prev, e) {
      final m = e.value.totalIncome > e.value.totalExpense
          ? e.value.totalIncome
          : e.value.totalExpense;
      return m > prev ? m : prev;
    });
    // Tepedeki çubuğun üstünde nefes payı; tooltip de oraya açılıyor.
    final maxY = maxVal == 0 ? 1.0 : maxVal * 1.2;
    // Etiketler 0 / yarı / tepe hizasına düşsün (tepe maxY'nin altında kalır).
    final yInterval = maxVal == 0 ? 1.0 : maxVal / 2;

    final currency = context.activeWalletCurrency;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Legend(scheme: scheme),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final step = dateLabelStep(
                  pointCount: entries.length,
                  availableWidth: constraints.maxWidth - kValueAxisWidth,
                  slotWidth: scaledDateLabelSlot(context),
                );
                // Az günde kalın, çok günde ince çubuk: 30 günlük veride
                // sabit 10px genişlik çubukları birbirine yapıştırıyordu.
                final barWidth = switch (entries.length) {
                  <= 7 => 12.0,
                  <= 14 => 8.0,
                  <= 24 => 5.0,
                  _ => 3.0,
                };

                return BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    barGroups: List.generate(entries.length, (index) {
                      final totals = entries[index].value;
                      return BarChartGroupData(
                        x: index,
                        barsSpace: barWidth / 4,
                        barRods: [
                          BarChartRodData(
                            toY: totals.totalIncome,
                            color: _incomeColor,
                            width: barWidth,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          BarChartRodData(
                            toY: totals.totalExpense,
                            color: _expenseColor,
                            width: barWidth,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      );
                    }),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (group.x < 0 || group.x >= entries.length) {
                            return null;
                          }
                          final isIncome = rodIndex == 0;
                          final label = isIncome
                              ? context.l10n.detailLabelGelir
                              : context.l10n.detailLabelGider;
                          return BarTooltipItem(
                            '${chartTooltipDate(entries[group.x].key)}\n'
                            '$label: ${formatMoney(rod.toY, currency: currency)}',
                            kChartTooltipStyle,
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: kValueAxisWidth,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            // Tepe boşluğuna denk gelen etiket çizilmez.
                            if (value > maxVal) return const SizedBox.shrink();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                formatMoneyCompact(value, symbol: false),
                                style: chartAxisLabelStyle(scheme),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= entries.length ||
                                index % step != 0) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              // Serinin ilk/son tarihi eksenin tam ucuna denk
                              // geliyor ve kartın dışına taşıyordu.
                              fitInside:
                                  SideTitleFitInsideData.fromTitleMeta(meta),
                              child: Text(
                                chartDateLabel(entries[index].key),
                                style: chartAxisLabelStyle(scheme),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: scheme.onSurface.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final ColorScheme scheme;
  const _Legend({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(context, ReportWeeklyNetFlowChart._incomeColor,
            context.l10n.detailLabelGelir),
        const SizedBox(width: 14),
        _dot(context, ReportWeeklyNetFlowChart._expenseColor,
            context.l10n.detailLabelGider),
      ],
    );
  }

  Widget _dot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
