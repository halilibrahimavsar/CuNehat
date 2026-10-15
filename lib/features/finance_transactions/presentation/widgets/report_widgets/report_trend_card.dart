import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_trend.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_change_badge.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_time_axis.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Zaman çizgisinin bir kategoriye odaklandığı hâl (kategori keşfinde
/// inilen düğüm).
@immutable
class ReportTrendFocus {
  final String label;
  final Color color;
  final double amount;

  /// Önceki dönemin aynı noktasındaki tutar; bilinmiyorsa null.
  final double? previousAmount;

  /// Düğümün kendi tarafının (gider/gelir) toplamı içindeki payı, 0–1.
  final double share;
  final bool isExpense;

  const ReportTrendFocus({
    required this.label,
    required this.color,
    required this.amount,
    required this.previousAmount,
    required this.share,
    required this.isExpense,
  });
}

/// Raporun MANŞETİ: seçili ölçünün dönem toplamı ve zaman çizgisi.
///
/// **Neden en üstte ve neden çizgi:** raporun ilk ekranı eskiden üç özet
/// kutusu + bir pasta çemberiydi; "bu ay nasıl gidiyorum" sorusunun cevabı
/// (zaman) iki ekran aşağıda, çubuklarla duruyordu. Kullanıcı varsayılanın
/// çizgi olmasını istedi. Çizgi BİRİKİMLİDİR (bkz. [ReportTrend]) ve önceki
/// dönemin çizgisi kesikli olarak üstüne biner: kıyas rakamla değil şekille
/// okunur. Kova kova tutar çubuk görünümündedir (tek dokunuş).
///
/// Özet kutularının yerine geçer: seçili ölçü manşette, diğer ikisi altında
/// tek satırda yazılır.
///
/// Kategori keşfinde bir düğüme inildiğinde ([focus]) kart o kategoriyi
/// çizer; ölçü seçicinin yerinde kategorinin çipi durur.
class ReportTrendCard extends StatelessWidget {
  final TrendMetric metric;
  final ValueChanged<TrendMetric> onMetricChanged;

  /// Çizgi mi (varsayılan) çubuk mu.
  final bool asLine;
  final ValueChanged<bool> onAsLineChanged;

  /// Dönemin (odaksız) toplamları ve kıyas penceresinin toplamları.
  final ReportTotals totals;
  final ReportTotals previousTotals;

  /// Zaman ekseni boyunca akış serisi (analiz evreni; odak varsa odağa
  /// süzülmüş). İlk [elapsedCount] kovası yaşanmıştır.
  final ReportSeries flow;

  /// Aynı eksende bakiye serisi (defterin tamamı + açılış bakiyesi).
  final ReportSeries balance;

  /// Önceki dönemin akış serisi (aynı çözünürlük, aynı süzgeç); yoksa null.
  final ReportSeries? previousFlow;

  /// Eksendeki YAŞANMIŞ kova sayısı: güncel çizgi burada biter. Kalan kovalar
  /// yalnız önceki dönemin çizgisi için vardır ("geçen ay ay sonunda ne
  /// olmuştu").
  final int elapsedCount;

  final ReportTrendFocus? focus;
  final VoidCallback? onClearFocus;

  /// Dönemin adı ("Ekim 2026") — ekran okuyucu etiketi için; efsane
  /// "Bu dönem" der.
  final String currentLabel;

  /// Önceki dönemin adı ("Eylül 2026") — kesikli çizginin efsanesi.
  final String previousLabel;

  /// Çözünürlük seçicisi (yalnız uzun aralıklarda verilir).
  final Widget? unitSelector;

  const ReportTrendCard({
    super.key,
    required this.metric,
    required this.onMetricChanged,
    required this.asLine,
    required this.onAsLineChanged,
    required this.totals,
    required this.previousTotals,
    required this.flow,
    required this.balance,
    required this.elapsedCount,
    required this.currentLabel,
    required this.previousLabel,
    this.previousFlow,
    this.focus,
    this.onClearFocus,
    this.unitSelector,
  });

  /// Odak varken ölçü kategorinin tarafına kilitlidir.
  TrendMetric get _effectiveMetric {
    final f = focus;
    if (f == null) return metric;
    return f.isExpense ? TrendMetric.expense : TrendMetric.income;
  }

  Color _colorFor(TrendMetric m, ColorScheme scheme) =>
      focus?.color ??
      switch (m) {
        TrendMetric.expense => MoneyColors.expense,
        TrendMetric.income => MoneyColors.income,
        TrendMetric.net => MoneyColors.netPositive,
        TrendMetric.balance => scheme.primary,
      };

  String _metricLabel(BuildContext context, TrendMetric m) => switch (m) {
        TrendMetric.expense => context.l10n.reportModeExpense,
        TrendMetric.income => context.l10n.reportModeIncome,
        TrendMetric.net => context.l10n.reportNetLabel,
        TrendMetric.balance => context.l10n.reportLensBalance,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);
    final m = _effectiveMetric;
    final color = _colorFor(m, scheme);

    final elapsed = elapsedCount.clamp(0, flow.buckets.length);
    final isBalance = m == TrendMetric.balance;
    final source = isBalance ? balance : flow;
    final current = ReportTrend.cumulative(source, m, count: elapsed);
    final previous = isBalance
        ? null
        : ReportTrend.alignedPrevious(previousFlow, m, flow.buckets.length);

    final headline = _headline(m, current);

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (focus == null)
            LabeledSegment<TrendMetric>(
              selected: metric,
              onChanged: onMetricChanged,
              items: [
                for (final item in TrendMetric.values)
                  SegmentItem(
                    value: item,
                    label: _metricLabel(context, item),
                    color: _colorFor(item, scheme),
                  ),
              ],
            )
          else
            _FocusChip(focus: focus!, onClear: onClearFocus),
          const SizedBox(height: 14),
          _Headline(
            amount: headline.amount,
            color: color,
            signed: m == TrendMetric.net,
            change: headline.change,
            increaseIsGood: headline.increaseIsGood,
            noPrevious: headline.noPrevious,
          ),
          const SizedBox(height: 4),
          _Context(lines: _contextLines(context, money, m, headline.amount)),
          const SizedBox(height: 14),
          Semantics(
            label: context.l10n.reportTrendSemantics(
              _metricLabel(context, m),
              currentLabel,
              m == TrendMetric.net
                  ? money.withSign(headline.amount)
                  : money(headline.amount),
            ),
            child: asLine || isBalance
                ? _TrendLineChart(
                    axis: flow.buckets,
                    unit: flow.unit,
                    current: current,
                    bucketAmounts: [
                      for (var i = 0; i < elapsed; i++)
                        ReportTrend.amountOf(source.buckets[i], m),
                    ],
                    previous: previous,
                    previousBuckets: previousFlow?.buckets,
                    color: color,
                    showBucketDelta: !isBalance,
                    zeroBased: !isBalance,
                  )
                : ReportDailyNetFlowChart(
                    series: ReportSeries(
                      unit: flow.unit,
                      buckets: flow.buckets.take(elapsed).toList(),
                    ),
                    height: 180,
                    showIncome: m != TrendMetric.expense,
                    showExpense: m != TrendMetric.income,
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (asLine || isBalance) ...[
                      // Dönemin ADI hemen üstteki dönem çubuğunda yazılı; efsanede
                      // tekrar etmek yerine "Bu dönem" denir.
                      _LegendSwatch(
                        color: color,
                        label: context.l10n.reportTrendThisPeriod,
                      ),
                      if (previous != null)
                        _LegendSwatch(
                          color: scheme.onSurfaceVariant,
                          label: previousLabel,
                          dashed: true,
                        ),
                    ],
                  ],
                ),
              ),
              if (!isBalance) ...[
                _ViewToggle(
                  icon: Icons.show_chart_rounded,
                  tooltip: context.l10n.reportViewLine,
                  selected: asLine,
                  onTap: () => onAsLineChanged(true),
                ),
                _ViewToggle(
                  icon: Icons.bar_chart_rounded,
                  tooltip: context.l10n.reportViewBars,
                  selected: !asLine,
                  onTap: () => onAsLineChanged(false),
                ),
              ],
            ],
          ),
          if (unitSelector != null) ...[
            const SizedBox(height: 6),
            unitSelector!,
          ],
        ],
      ),
    );
  }

  ({
    double amount,
    double? change,
    bool increaseIsGood,
    bool noPrevious,
  }) _headline(TrendMetric m, List<double> current) {
    final f = focus;
    if (f != null) {
      return _withChange(f.amount, f.previousAmount,
          increaseIsGood: !f.isExpense);
    }
    return switch (m) {
      TrendMetric.expense => _withChange(
          totals.totalExpense, previousTotals.totalExpense,
          increaseIsGood: false),
      TrendMetric.income => _withChange(
          totals.totalIncome, previousTotals.totalIncome,
          increaseIsGood: true),
      // Net için yüzde değişim anlamsız (işaret değişebilir); alt satır
      // birikim oranını yazar.
      TrendMetric.net => (
          amount: totals.net,
          change: null,
          increaseIsGood: true,
          noPrevious: false,
        ),
      TrendMetric.balance => (
          amount: current.isEmpty ? balance.openingBalance : current.last,
          change: null,
          increaseIsGood: true,
          noPrevious: false,
        ),
    };
  }

  static ({
    double amount,
    double? change,
    bool increaseIsGood,
    bool noPrevious,
  }) _withChange(double amount, double? previous,
      {required bool increaseIsGood}) {
    if (previous == null || previous == 0) {
      return (
        amount: amount,
        change: null,
        increaseIsGood: increaseIsGood,
        // Sıfır ↔ sıfır kıyas değil, sessizlik: yazacak bir şey yok.
        noPrevious: previous == 0 && amount != 0,
      );
    }
    return (
      amount: amount,
      change: (amount - previous) / previous * 100,
      increaseIsGood: increaseIsGood,
      noPrevious: false,
    );
  }

  /// Dönem sonu bakiyesi − dönem başı − net: nete girmeyip bakiyeyi
  /// değiştiren hareketler (para taşıma; "kartlar dahil"de karttan yapılan
  /// harcama ters yönde).
  double _otherMovements(double endBalance) =>
      roundToCents(endBalance - balance.openingBalance - totals.net);

  /// Manşetin altındaki bağlam satırı: özet kutularının yerine geçen
  /// "diğer sayılar".
  List<String> _contextLines(BuildContext context, MoneyWriter money,
      TrendMetric m, double headlineAmount) {
    final l10n = context.l10n;
    final f = focus;
    if (f != null) {
      final share = formatPercent(f.share * 100);
      return [
        f.isExpense
            ? l10n.reportFocusShareExpense(share)
            : l10n.reportFocusShareIncome(share),
        if (f.previousAmount != null && f.previousAmount! > 0)
          l10n.reportPreviousAmount(money(f.previousAmount!)),
      ];
    }
    final income = '${l10n.reportModeIncome} ${money(totals.totalIncome)}';
    final expense = '${l10n.reportModeExpense} ${money(totals.totalExpense)}';
    final net = '${l10n.reportNetLabel} ${money.withSign(totals.net)}';
    return switch (m) {
      TrendMetric.expense => [income, net],
      TrendMetric.income => [expense, net],
      TrendMetric.net => [income, expense, netRateLabel(context, totals)],
      TrendMetric.balance => [
          l10n.reportTrendBalanceStart(money(balance.openingBalance)),
          net,
          // Satır başlıktaki bakiyeye TOPLANMALI: "Dönem başı 37.100 · Net
          // +26.400" 63.500 ediyordu, bakiye 60.000 (aradaki −3.500 para
          // taşıma; X-04). Kalan, nete girmeyip bakiyeyi değiştiren her şey.
          if (_otherMovements(headlineAmount).abs() >= 0.005)
            l10n.reportTrendBalanceOther(
                money.withSign(_otherMovements(headlineAmount))),
        ],
    };
  }
}

/// Net tutarın alt satırı — gelir yoksa oran tanımsızdır, net negatifse
/// "gelirin üzerinde" denir (bkz. İçgörü'deki özet kartı, aynı fonksiyon).
String netRateLabel(BuildContext context, ReportTotals totals) {
  if (totals.totalIncome == 0) return context.l10n.reportNoIncomeForRate;
  final rate = (totals.net.abs() / totals.totalIncome) * 100;
  return totals.net >= 0
      ? context.l10n.reportSavingsSubtitle(rate.toStringAsFixed(0))
      : context.l10n.reportCompareOverspend(rate.toStringAsFixed(0));
}

class _Headline extends StatelessWidget {
  final double amount;
  final Color color;
  final bool signed;
  final double? change;
  final bool increaseIsGood;
  final bool noPrevious;

  const _Headline({
    required this.amount,
    required this.color,
    required this.signed,
    required this.change,
    required this.increaseIsGood,
    required this.noPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11,
      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
    );
    final showsChange =
        change != null && change!.abs() >= ReportChangeBadge.minPercent;

    // Wrap: yedi haneli tutar + rozet dar telefonda tek satıra sığmazsa
    // rozet alta iner, kesilmez.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 2,
      children: [
        Text(
          signed ? money.withSign(amount) : money(amount),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: signed ? MoneyColors.net(amount) : color,
          ),
        ),
        if (showsChange)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReportChangeBadge(
                percent: change,
                increaseIsGood: increaseIsGood,
              ),
              const SizedBox(width: 4),
              Text(context.l10n.reportTrendVsPrevious, style: muted),
            ],
          )
        else if (noPrevious)
          Text(context.l10n.reportNoPreviousPeriod, style: muted),
      ],
    );
  }
}

class _Context extends StatelessWidget {
  final List<String> lines;

  const _Context({required this.lines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      lines.join('  ·  '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  final ReportTrendFocus focus;
  final VoidCallback? onClear;

  const _FocusChip({required this.focus, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InputChip(
        avatar: CircleAvatar(backgroundColor: focus.color, radius: 6),
        label: Text(focus.label, overflow: TextOverflow.ellipsis),
        onDeleted: onClear,
        deleteButtonTooltipMessage: context.l10n.reportFocusClear,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendSwatch({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 3,
          child: dashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 4,
                        color: color.withValues(alpha: 0.6),
                      ),
                  ],
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
        ),
        const SizedBox(width: 6),
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

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      isSelected: selected,
      color: scheme.onSurfaceVariant,
      selectedIcon: Icon(icon, size: 20, color: scheme.primary),
      onPressed: selected ? null : onTap,
      // 48dp yerine sıkı: iki ikon efsane satırını büyütmesin (bkz.
      // analiz yüzeylerindeki aynı ölçüm).
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        disabledForegroundColor: scheme.primary,
      ),
    );
  }
}

/// Birikimli çizgi + önceki dönemin kesikli çizgisi.
///
/// Eksen kurulumu bakiye grafiğinin dersleriyle aynı (bkz.
/// `ReportCumulativeBalanceChart`): yarım kova payı, eğri KAPALI (spline
/// maaş sıçramasında yaşanmamış değerler çizer), tam sayı olmayan x
/// etiketleri atılır, tutarlar [MoneyWriter] ile closure'a taşınır.
class _TrendLineChart extends StatelessWidget {
  final List<ReportBucket> axis;
  final ReportBucketUnit unit;
  final List<double> current;

  /// Yaşanmış her kovanın KENDİ tutarı (tooltip'te "+250 ₺").
  final List<double> bucketAmounts;
  final List<double>? previous;
  final List<ReportBucket>? previousBuckets;
  final Color color;
  final bool showBucketDelta;

  /// Eksen sıfırdan mı başlar. Birikimli gider/gelir/net sıfırdan başlar ve
  /// eksen de öyle olmalı; BAKİYE için değil: 60 B'lik bakiyede ±%10'luk
  /// hareket sıfır tabanlı eksende düz bir çizgiye dönüyordu (smoke test).
  final bool zeroBased;

  const _TrendLineChart({
    required this.axis,
    required this.unit,
    required this.current,
    required this.bucketAmounts,
    required this.previous,
    required this.previousBuckets,
    required this.color,
    required this.showBucketDelta,
    this.zeroBased = true,
  });

  static const double _height = 180;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final money = MoneyWriter.of(context);
    if (axis.isEmpty) return const SizedBox(height: _height);

    final prev = previous;
    final values = [...current, ...?prev];
    var minValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    var maxValue =
        values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    // Gider/gelir birikimi sıfırdan başlar; eksen de sıfırdan başlamalı,
    // yoksa küçük bir artış dik bir yokuş gibi görünür. Bakiye ise dönemin
    // kendi aralığında çizilir (bkz. ReportCumulativeBalanceChart).
    if (zeroBased && minValue > 0) minValue = 0;
    if (minValue == maxValue) {
      if (zeroBased) {
        maxValue = minValue + 10;
      } else {
        minValue -= 10;
        maxValue += 10;
      }
    }
    final pad = (maxValue - minValue) * 0.1;
    final axisMin = !zeroBased || minValue < 0 ? minValue - pad : 0.0;
    final axisMax = maxValue + pad;
    final yInterval = (maxValue - minValue).abs() / 2;
    final crossesZero = minValue < 0 && maxValue > 0;
    final ongoing = current.length < axis.length;

    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final step = dateLabelStep(
            pointCount: axis.length,
            availableWidth: constraints.maxWidth - kValueAxisWidth,
            slotWidth: scaledDateLabelSlot(context),
          );

          final currentBar = LineChartBarData(
            spots: [
              for (var i = 0; i < current.length; i++)
                FlSpot(i.toDouble(), current[i]),
            ],
            isCurved: false,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            // Yalnız "bugün" noktası: dönem sürüyorsa çizginin nerede
            // durduğu (ve neden durduğu) okunur.
            dotData: FlDotData(
              show: ongoing,
              checkToShowDot: (spot, _) => spot.x == current.length - 1,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.10),
            ),
          );

          final previousBar = prev == null
              ? null
              : LineChartBarData(
                  spots: [
                    for (var i = 0; i < prev.length; i++)
                      FlSpot(i.toDouble(), prev[i]),
                  ],
                  isCurved: false,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                  barWidth: 2,
                  dashArray: const [5, 4],
                  dotData: const FlDotData(show: false),
                );

          return LineChart(
            LineChartData(
              minY: axisMin,
              maxY: axisMax,
              minX: -0.5,
              maxX: (axis.length - 1) + 0.5,
              // Önceki dönem ALTTA çizilir; güncel çizgi onun üstünde.
              lineBarsData: [
                if (previousBar != null) previousBar,
                currentBar,
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (spots) => [
                    for (final spot in spots)
                      _tooltip(context, money, spot,
                          isPrevious:
                              previousBar != null && spot.barIndex == 0),
                  ],
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (crossesZero)
                    HorizontalLine(
                      y: 0,
                      color: scheme.onSurface.withValues(alpha: 0.35),
                      strokeWidth: 1,
                      dashArray: const [4, 3],
                    ),
                ],
              ),
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
                      if (value < minValue || value > maxValue) {
                        return const SizedBox.shrink();
                      }
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
                      if (value != value.roundToDouble()) {
                        return const SizedBox.shrink();
                      }
                      final index = value.toInt();
                      if (index < 0 ||
                          index >= axis.length ||
                          index % step != 0) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                        child: Text(
                          bucketAxisLabel(axis[index], unit),
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
                  color: scheme.onSurface.withValues(alpha: 0.08),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          );
        },
      ),
    );
  }

  LineTooltipItem _tooltip(
    BuildContext context,
    MoneyWriter money,
    LineBarSpot spot, {
    required bool isPrevious,
  }) {
    final index = spot.x.toInt();
    if (isPrevious) {
      final buckets = previousBuckets;
      final date = buckets != null && index >= 0 && index < buckets.length
          ? '${bucketTooltipDate(buckets[index], unit)}\n'
          : '';
      return LineTooltipItem(
        '$date${context.l10n.reportTrendTooltipPrevious(money(spot.y))}',
        kChartTooltipStyle.copyWith(fontWeight: FontWeight.w500),
      );
    }
    final date = index >= 0 && index < axis.length
        ? '${bucketTooltipDate(axis[index], unit)}\n'
        : '';
    final delta = showBucketDelta && index >= 0 && index < bucketAmounts.length
        ? '  (${money.withSign(bucketAmounts[index])})'
        : '';
    return LineTooltipItem('$date${money(spot.y)}$delta', kChartTooltipStyle);
  }
}
