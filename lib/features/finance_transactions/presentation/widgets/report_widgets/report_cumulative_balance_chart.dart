import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_time_axis.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Dönem boyunca cüzdan bakiyesinin seyri.
///
/// İki şey buradan okunmalı ve ikisi de eskiden yanlıştı:
///
///  1. **Eksen takvimdir.** Hareketsiz kovalar da çizilir, çizgi onlarda düz
///     gider. Eskiden yalnız işlem OLAN günler yan yana diziliyordu; eğim
///     tamamen uydurmaydı.
///  2. **Çizgi GERÇEK bakiyeyi gösterir.** Eskiden her dönem 0'dan
///     başlıyordu, yani cüzdanında 50.000 TL olan bir kullanıcı sadece
///     gideri olan bir ayda "-700"e inen bir "Bakiye Trendi" görüyordu.
///     Çıpa [ReportSeries.openingBalance]'tır.
///
/// Dokununca tooltip o kovanın tarihini ve bakiyeyi [MoneyWriter] ile yazar
/// (göz düğmesine duyarlı); sıfırın altına inen dönemlerde ayrıca sıfır
/// çizgisi gösterilir.
class ReportCumulativeBalanceChart extends StatelessWidget {
  final ReportSeries series;

  const ReportCumulativeBalanceChart({
    super.key,
    required this.series,
  });

  /// Bu sayıdan çok nokta varken tek tek noktalar çizgiyi boğuyor.
  static const _maxDotCount = 15;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (series.isEmpty || series.hasNoActivity) return const SizedBox();

    final buckets = series.buckets;
    final balances = series.cumulativeBalance;

    final spots = <FlSpot>[
      for (var i = 0; i < balances.length; i++)
        FlSpot(i.toDouble(), balances[i]),
    ];

    var minValue = balances.first;
    var maxValue = balances.first;
    for (final v in balances) {
      if (v < minValue) minValue = v;
      if (v > maxValue) maxValue = v;
    }

    if (minValue == maxValue) {
      minValue -= 10;
      maxValue += 10;
    }

    // Payı aralığın kendisinden hesapla: eskiden minY/maxY ayrı ayrı %10
    // büyütülüyordu, bu yüzden 0'da biten seriler grafiğin tam kenarına
    // yapışıyordu (üst sınır 0 × 1.1 = 0).
    final pad = (maxValue - minValue) * 0.1;
    final axisMin = minValue - pad;
    final axisMax = maxValue + pad;
    final yInterval = (maxValue - minValue).abs() / 2;

    // Tooltip/eksen closure'ları build dışında çalışır: birim ve görünürlük
    // burada bir kez okunup taşınır.
    final money = MoneyWriter.of(context);
    final crossesZero = minValue < 0 && maxValue > 0;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      child: Semantics(
        label: context.l10n.reportBalanceChartSemantics(
          money(balances.first),
          money(balances.last),
        ),
        child: SizedBox(
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final step = dateLabelStep(
                pointCount: buckets.length,
                availableWidth: constraints.maxWidth - kValueAxisWidth,
                slotWidth: scaledDateLabelSlot(context),
              );

              return LineChart(
                LineChartData(
                  minY: axisMin,
                  maxY: axisMax,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: scheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: spots.length <= _maxDotCount),
                      belowBarData: BarAreaData(
                        show: true,
                        color: scheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final date = index >= 0 && index < buckets.length
                              ? '${bucketTooltipDate(buckets[index], series.unit)}\n'
                              : '';
                          return LineTooltipItem(
                            '$date${money(spot.y)}',
                            kChartTooltipStyle,
                          );
                        }).toList();
                      },
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (crossesZero)
                        HorizontalLine(
                          y: 0,
                          color: scheme.onSurface.withValues(alpha: 0.35),
                          strokeWidth: 1,
                          dashArray: [4, 3],
                        ),
                    ],
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
                        interval: yInterval > 0 ? yInterval : 1,
                        getTitlesWidget: (value, meta) {
                          // fl_chart aralık etiketlerinin YANINDA eksenin uç
                          // değerlerini de basıyor; bunlar nefes payından gelen
                          // rastgele sayılar ("-581") ve komşularının 16px
                          // dibine düşüp okunmaz bir küme oluşturuyorlardı.
                          // Yalnız gerçek veri aralığındakileri çiziyoruz.
                          if (value < minValue || value > maxValue) {
                            return const SizedBox.shrink();
                          }
                          // Tutarlar gizliyken değer ekseni yazılmaz (bkz.
                          // günlük akış grafiği); çizginin şekli görünür kalır.
                          if (!money.visible) return const SizedBox.shrink();
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
                            // Serinin ilk/son tarihi eksenin tam ucuna denk
                            // geliyor ve kartın dışına taşıyordu.
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
                    horizontalInterval: yInterval > 0 ? yInterval : 1,
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
    );
  }
}
