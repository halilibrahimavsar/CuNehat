import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_time_axis.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Son 6/12 ayın gelir–gider çubukları + ortalama gider çizgisi.
///
/// **Neden seçili aralıktan BAĞIMSIZ:** "bu ay ne harcadım" sorusunun cevabı
/// raporun geri kalanında zaten var. Buradaki soru "daha çok mu harcıyorum"
/// ve o soru daha uzun bir ufuk ister — dönem seçicisiyle aynı eksene
/// bağlanırsa sorulamaz hâle gelir.
///
/// **Bir aya dokunmak raporun DÖNEMİNİ o aya alır.** Trend kartı böylece
/// yalnız bir grafik değil, gezinme aracı olur: "Ekim'de neden bu kadar
/// harcamışım?" sorusundan cevabına tek dokunuş.
class ReportMonthlyTrendCard extends StatelessWidget {
  /// Aylık kovalar (bkz. [ReportSeriesService.monthsWindow]).
  final ReportSeries series;

  /// Kaç aylık pencere gösteriliyor (6 | 12).
  final int months;

  final ValueChanged<int> onMonthsChanged;

  /// Seçili dönemin kapsadığı ay — vurgulanır.
  final DateTime? selectedMonth;

  /// Bir aya dokunulduğunda raporun dönemi o aya alınır.
  final ValueChanged<ReportBucket> onMonthTap;

  const ReportMonthlyTrendCard({
    super.key,
    required this.series,
    required this.months,
    required this.onMonthsChanged,
    required this.onMonthTap,
    this.selectedMonth,
  });

  static const _incomeColor = Colors.green;
  static const _expenseColor = Colors.redAccent;

  /// Seçenekler; 12'nin ötesi 360dp'de çubuk başına ~8dp bırakıyor.
  static const List<int> monthOptions = [6, 12];

  bool _isSelected(ReportBucket b) =>
      selectedMonth != null &&
      b.start.year == selectedMonth!.year &&
      b.start.month == selectedMonth!.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final buckets = series.buckets;
    if (buckets.isEmpty || series.hasNoActivity) return const SizedBox.shrink();

    final money = MoneyWriter.of(context);

    final maxVal = buckets.fold<double>(0, (m, b) {
      final v = b.income > b.expense ? b.income : b.expense;
      return v > m ? v : m;
    });
    final maxY = maxVal == 0 ? 1.0 : maxVal * 1.25;

    // Ortalama YALNIZ hareketli aylardan hesaplanır: veri girilmemiş aylar
    // ortalamayı aşağı çekip "harcamam düşüyor" yanılsaması üretiyordu.
    final activeMonths = buckets.where((b) => !b.isEmpty).toList();
    final avgExpense = activeMonths.isEmpty
        ? 0.0
        : activeMonths.fold<double>(0, (s, b) => s + b.expense) /
            activeMonths.length;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _Legend(scheme: scheme, avgExpense: money(avgExpense)),
              Wrap(
                spacing: 6,
                children: [
                  for (final option in monthOptions)
                    ChoiceChip(
                      label: Text(context.l10n.reportMonthsOption('$option')),
                      selected: months == option,
                      onSelected: (_) => onMonthsChanged(option),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: context.l10n.reportMonthlyTrendSemantics(
              '${buckets.length}',
              money(avgExpense),
            ),
            child: SizedBox(
              height: 180,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final step = dateLabelStep(
                    pointCount: buckets.length,
                    availableWidth: constraints.maxWidth - kValueAxisWidth,
                    slotWidth: scaledDateLabelSlot(context),
                  );
                  final barWidth = buckets.length <= 6 ? 9.0 : 5.0;

                  return BarChart(
                    BarChartData(
                      maxY: maxY,
                      minY: 0,
                      barGroups: [
                        for (var i = 0; i < buckets.length; i++)
                          BarChartGroupData(
                            x: i,
                            barsSpace: barWidth / 3,
                            barRods: [
                              BarChartRodData(
                                toY: buckets[i].income,
                                color: _shade(
                                    _incomeColor, _isSelected(buckets[i])),
                                width: barWidth,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              BarChartRodData(
                                toY: buckets[i].expense,
                                color: _shade(
                                    _expenseColor, _isSelected(buckets[i])),
                                width: barWidth,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),
                      ],
                      // Ortalama gider çizgisi: tek bir ayın yüksek olması ile
                      // eğilimin yükselmesi ancak bu referansla ayrılır.
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          if (avgExpense > 0)
                            HorizontalLine(
                              y: avgExpense,
                              color: _expenseColor.withValues(alpha: 0.55),
                              strokeWidth: 1,
                              dashArray: [5, 4],
                            ),
                        ],
                      ),
                      barTouchData: BarTouchData(
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          final index =
                              response?.spot?.touchedBarGroupIndex ?? -1;
                          if (index < 0 || index >= buckets.length) return;
                          onMonthTap(buckets[index]);
                        },
                        touchTooltipData: BarTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItem: (group, _, rod, rodIndex) {
                            if (group.x < 0 || group.x >= buckets.length) {
                              return null;
                            }
                            final label = rodIndex == 0
                                ? context.l10n.detailLabelGelir
                                : context.l10n.detailLabelGider;
                            return BarTooltipItem(
                              '${DateFormat('MMMM y').format(buckets[group.x].start)}\n'
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
                            interval: maxVal == 0 ? 1 : maxVal / 2,
                            getTitlesWidget: (value, meta) {
                              if (value > maxVal || !money.visible) {
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
                              final selected = _isSelected(buckets[index]);
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                fitInside:
                                    SideTitleFitInsideData.fromTitleMeta(meta),
                                child: Text(
                                  DateFormat('MMM')
                                      .format(buckets[index].start),
                                  style: chartAxisLabelStyle(scheme).copyWith(
                                    color: selected
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxVal == 0 ? 1 : maxVal / 2,
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
          const SizedBox(height: 4),
          Text(
            context.l10n.reportMonthlyTrendHint,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  /// Seçili ay tam şiddette, diğerleri sönümlü: hangi ayın raporda açık
  /// olduğu çubuktan okunur.
  Color _shade(Color base, bool selected) =>
      selectedMonth == null || selected ? base : base.withValues(alpha: 0.45);
}

class _Legend extends StatelessWidget {
  final ColorScheme scheme;
  final String avgExpense;

  const _Legend({required this.scheme, required this.avgExpense});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );

    // Row DEĞİL Wrap: üç efsane öğesi + "Ort. 5.250,00 ₺" 360dp'de tek
    // satıra sığmıyor (ölçüldü: 28px taşma). Sığmayınca alta iner.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 4,
      children: [
        _dot(ReportMonthlyTrendCard._incomeColor),
        const SizedBox(width: 5),
        Text(context.l10n.detailLabelGelir, style: style),
        const SizedBox(width: 12),
        _dot(ReportMonthlyTrendCard._expenseColor),
        const SizedBox(width: 5),
        Text(context.l10n.detailLabelGider, style: style),
        const SizedBox(width: 12),
        // Kesikli çizgi efsanede de kesikli görünsün.
        SizedBox(
          width: 14,
          height: 9,
          child: CustomPaint(
            painter: _DashPainter(
              color:
                  ReportMonthlyTrendCard._expenseColor.withValues(alpha: 0.55),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(context.l10n.reportAverageShort(avgExpense), style: style),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}
