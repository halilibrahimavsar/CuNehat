import 'dart:math' as math;

import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_time_axis.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// "Bugün" / "Yarın" / "14 Kas".
String forecastDayLabel(AppLocalizations l10n, DateTime day, DateTime today) {
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(today.year, today.month, today.day);
  if (d == t) return l10n.forecastToday;
  if (d == DateTime(t.year, t.month, t.day + 1)) return l10n.forecastTomorrow;
  return AppFormatters.dayMonth.format(d);
}

/// Bakiye yolculuğunun manşet cümlesi — sayfanın ASIL cevabı.
///
/// Öncelik: (1) maaştan ÖNCE eksiye düşüş, (2) sıradaki maaşa kadar yetiyor
/// mu, (3) ufuk boyunca yetiyor mu. Kart cüzdanında borç zaten eksidir; o
/// zaman cümle ekstre tahminidir.
({String headline, String? detail, bool warning}) forecastHeadline(
  AppLocalizations l10n,
  WalletForecast f,
  MoneyWriter money,
  DateTime today, {
  required int horizonDays,
}) {
  final card = f.card;
  if (f.isCard && card != null) {
    return (
      headline: l10n.forecastCardEstimate(money(card.statementEstimate)),
      detail: l10n.forecastCardClosingDue(
        AppFormatters.dayMonth.format(card.nextClosing),
        AppFormatters.dayMonth.format(card.nextDue),
      ),
      warning: false,
    );
  }
  final income = f.nextIncome;
  final negative = f.firstNegative;
  if (negative != null &&
      (income == null || negative.day.isBefore(income.date))) {
    return (
      headline: l10n.forecastHeadlineNegative(
          forecastDayLabel(l10n, negative.day, today)),
      detail: null,
      warning: true,
    );
  }
  final low = f.lowestPoint(until: income?.date);
  final detail = low == null
      ? null
      : l10n.forecastLowestPoint(
          forecastDayLabel(l10n, low.day, today), money(low.expected));
  if (income != null) {
    return (
      headline: l10n.forecastHeadlineUntilIncome(
          income.title, forecastDayLabel(l10n, income.date, today)),
      detail: detail,
      warning: false,
    );
  }
  return (
    headline: l10n.forecastHeadlineHorizonOk(horizonDays),
    detail: detail,
    warning: false,
  );
}

/// Manşet kartı: cümle + 30 günlük bakiye yolu (beklenen çizgi + olası
/// aralık bandı). Güven kapısı kapalıysa (hız yok) çizgi yalnız planlı
/// olaylarla çizilir ve bant yoktur.
class ForecastPathCard extends StatelessWidget {
  final WalletForecast forecast;
  final MoneyWriter money;
  final DateTime today;
  final int horizonDays;

  /// Olası aralık bandı çizilsin mi; verilmezse cüzdanın hızı varsa.
  /// Birleşik görünümde hız tek bir cüzdana ait değildir.
  final bool? showBand;

  const ForecastPathCard({
    super.key,
    required this.forecast,
    required this.money,
    required this.today,
    required this.horizonDays,
    this.showBand,
  });

  bool get _band => showBand ?? forecast.pace != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final h = forecastHeadline(l10n, forecast, money, today,
        horizonDays: horizonDays);
    final accent = h.warning ? MoneyColors.bad : MoneyColors.netPositive;

    return AppCard(
      key: const ValueKey('forecast-path-card'),
      accent: accent,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                h.warning
                    ? Icons.warning_amber_rounded
                    : (forecast.isCard
                        ? Icons.credit_card_rounded
                        : Icons.trending_flat_rounded),
                color: accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  h.headline,
                  key: const ValueKey('forecast-headline'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: AppType.strong),
                ),
              ),
            ],
          ),
          if (h.detail != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                h.detail!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: _PathChart(
              forecast: forecast,
              money: money,
              today: today,
              color: accent,
              hasBand: _band,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _LegendDot(
                  color: accent,
                  label: forecast.isCard
                      ? l10n.forecastCardPathTitle
                      : l10n.forecastLegendExpected),
              if (_band)
                _LegendDot(
                    color: accent.withValues(alpha: 0.25),
                    label: l10n.forecastLegendRange),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: chartAxisLabelStyle(scheme)),
      ],
    );
  }
}

class _PathChart extends StatelessWidget {
  final WalletForecast forecast;
  final MoneyWriter money;
  final DateTime today;
  final Color color;
  final bool hasBand;

  const _PathChart({
    required this.forecast,
    required this.money,
    required this.today,
    required this.color,
    required this.hasBand,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final path = forecast.path;
    if (path.isEmpty) return const SizedBox.shrink();

    var minV = path.first.expected;
    var maxV = path.first.expected;
    for (final p in path) {
      minV = math.min(minV, hasBand ? p.low : p.expected);
      maxV = math.max(maxV, hasBand ? p.high : p.expected);
    }
    final crossesZero = minV < 0 && maxV > 0;
    if (minV == maxV) {
      minV -= 10;
      maxV += 10;
    }
    final pad = (maxV - minV) * 0.12;
    final yInterval = (maxV - minV) / 2;

    final low = forecast.lowestPoint(until: forecast.nextIncome?.date);
    final lowIndex = low == null ? -1 : path.indexOf(low);

    final expected = LineChartBarData(
      spots: [
        for (var i = 0; i < path.length; i++)
          FlSpot(i.toDouble(), path[i].expected),
      ],
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      // Gelecek: kesikli çizgi "henüz olmadı" demek (Rapor'daki önceki dönem
      // çizgisiyle aynı dil).
      dashArray: const [6, 4],
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, _) => spot.x == 0 || spot.x == lowIndex,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: spot.x == 0 ? 4 : 5,
          color: spot.x == 0 ? color : scheme.surface,
          strokeColor: color,
          strokeWidth: 2.5,
        ),
      ),
    );
    LineChartBarData edge(double Function(BalancePoint) of) => LineChartBarData(
          spots: [
            for (var i = 0; i < path.length; i++)
              FlSpot(i.toDouble(), of(path[i])),
          ],
          color: Colors.transparent,
          barWidth: 0,
          dotData: const FlDotData(show: false),
        );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (path.length - 1).toDouble(),
        minY: minV - pad,
        maxY: maxV + pad,
        lineBarsData: [
          if (hasBand) edge((p) => p.low),
          if (hasBand) edge((p) => p.high),
          expected,
        ],
        betweenBarsData: [
          if (hasBand)
            BetweenBarsData(
              fromIndex: 0,
              toIndex: 1,
              color: color.withValues(alpha: 0.14),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) => [
              for (final s in spots)
                if (s.barIndex == (hasBand ? 2 : 0))
                  LineTooltipItem(
                    '${forecastDayLabel(l10n, path[s.x.toInt()].day, today)}\n'
                    '${money(path[s.x.toInt()].expected)}',
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: AppType.strong,
                      fontSize: AppType.caption,
                    ),
                  )
                else
                  null,
            ],
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          if (crossesZero || minV < 0)
            HorizontalLine(
              y: 0,
              color: MoneyColors.bad.withValues(alpha: 0.55),
              strokeWidth: 1,
              dashArray: const [4, 3],
            ),
        ]),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: kValueAxisWidth,
              interval: yInterval > 0 ? yInterval : 1,
              getTitlesWidget: (value, meta) {
                if (value < minV || value > maxV || !money.visible) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(money.compact(value, symbol: false),
                      style: chartAxisLabelStyle(scheme)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (value != value.roundToDouble() ||
                    i < 0 ||
                    i >= path.length ||
                    i % 7 != 0) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                  child: Text(forecastDayLabel(l10n, path[i].day, today),
                      style: chartAxisLabelStyle(scheme)),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval > 0 ? yInterval : 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.onSurface.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
