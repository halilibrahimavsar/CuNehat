import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_time_axis.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Dönem boyunca gelir/gider çubukları.
///
/// Eksen TAKVİM'dir: hareketsiz kovalar da çizilir (bkz. [ReportSeries]).
/// Eskiden yalnız işlem OLAN günler yan yana diziliyordu, yani 1 ve 25
/// Haziran'daki iki işlem komşu iki çubuk oluyordu.
///
/// Çubuklar renkten başka bir şey söylemediği için üstte açıklama (legend)
/// var; dokununca tooltip tam tutarı [MoneyWriter] ile yazar — yani göz
/// düğmesi kapalıyken tooltip de eksen de tutarı ele vermez.
class ReportDailyNetFlowChart extends StatelessWidget {
  final ReportSeries series;

  const ReportDailyNetFlowChart({
    super.key,
    required this.series,
  });

  static const _incomeColor = Colors.green;
  static const _expenseColor = Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Tamamen hareketsiz bir dönemde grafik yerine hiçbir şey çizilmez;
    // 30 boş çubuk bilgi değil gürültüdür.
    if (series.isEmpty || series.hasNoActivity) return const SizedBox();

    final buckets = series.buckets;

    final maxVal = buckets.fold<double>(0.0, (prev, b) {
      final m = b.income > b.expense ? b.income : b.expense;
      return m > prev ? m : prev;
    });
    // Tepedeki çubuğun üstünde nefes payı; tooltip de oraya açılıyor.
    final maxY = maxVal == 0 ? 1.0 : maxVal * 1.2;
    // Etiketler 0 / yarı / tepe hizasına düşsün (tepe maxY'nin altında kalır).
    final yInterval = maxVal == 0 ? 1.0 : maxVal / 2;

    // Tooltip ve eksen etiketleri closure içinde, yani build DIŞINDA
    // çalışır: birim ve görünürlük burada bir kez okunup taşınır.
    final money = MoneyWriter.of(context);

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Legend(scheme: scheme),
          const SizedBox(height: 12),
          Semantics(
            // Grafiğin kendisi ekran okuyucuya hiçbir şey söylemiyordu.
            label: context.l10n.reportFlowChartSemantics(
              buckets.length.toString(),
              money(buckets.fold<double>(0, (s, b) => s + b.income)),
              money(buckets.fold<double>(0, (s, b) => s + b.expense)),
            ),
            child: SizedBox(
              height: 200,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final step = dateLabelStep(
                    pointCount: buckets.length,
                    availableWidth: constraints.maxWidth - kValueAxisWidth,
                    slotWidth: scaledDateLabelSlot(context),
                  );
                  // Az kovada kalın, çok kovada ince çubuk: 30 günlük veride
                  // sabit 10px genişlik çubukları birbirine yapıştırıyordu.
                  final barWidth = switch (buckets.length) {
                    <= 7 => 12.0,
                    <= 14 => 8.0,
                    <= 24 => 5.0,
                    _ => 3.0,
                  };

                  return BarChart(
                    BarChartData(
                      maxY: maxY,
                      minY: 0,
                      barGroups: List.generate(buckets.length, (index) {
                        final b = buckets[index];
                        return BarChartGroupData(
                          x: index,
                          barsSpace: barWidth / 4,
                          barRods: [
                            BarChartRodData(
                              toY: b.income,
                              color: _incomeColor,
                              width: barWidth,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            BarChartRodData(
                              toY: b.expense,
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
                            if (group.x < 0 || group.x >= buckets.length) {
                              return null;
                            }
                            final isIncome = rodIndex == 0;
                            final label = isIncome
                                ? context.l10n.detailLabelGelir
                                : context.l10n.detailLabelGider;
                            return BarTooltipItem(
                              '${bucketTooltipDate(buckets[group.x], series.unit)}\n'
                              '$label: ${money(rod.toY)}',
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
                              if (value > maxVal) {
                                return const SizedBox.shrink();
                              }
                              // Tutarlar gizliyken değer ekseni HİÇ yazılmaz:
                              // üç kere "****" basmak gürültü, üstelik hiçbir
                              // şey anlatmıyor. Çubukların oranı zaten görünür.
                              if (!money.visible) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  money.compact(value, symbol: false),
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
                                  index >= buckets.length ||
                                  index % step != 0) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                // Serinin ilk/son tarihi eksenin tam ucuna
                                // denk geliyor ve kartın dışına taşıyordu.
                                fitInside:
                                    SideTitleFitInsideData.fromTitleMeta(meta),
                                child: Text(
                                  bucketAxisLabel(buckets[index], series.unit),
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
        _dot(context, ReportDailyNetFlowChart._incomeColor,
            context.l10n.detailLabelGelir),
        const SizedBox(width: 14),
        _dot(context, ReportDailyNetFlowChart._expenseColor,
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
