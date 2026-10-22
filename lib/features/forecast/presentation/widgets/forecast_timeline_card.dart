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
import 'package:cunehat/features/forecast/presentation/widgets/forecast_sections.dart'
    show forecastEventTitle;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// "Bugün" / "Yarın" / "14 Kas". [inline]: cümle İÇİNDE ("bu hızla bugün
/// dolar") küçük harfli biçim — cihazda "Bu hızla Bugün dolar" görüldü.
String forecastDayLabel(AppLocalizations l10n, DateTime day, DateTime today,
    {bool inline = false}) {
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(today.year, today.month, today.day);
  if (d == t) return inline ? l10n.forecastTodayInline : l10n.forecastToday;
  if (d == DateTime(t.year, t.month, t.day + 1)) {
    return inline ? l10n.forecastTomorrowInline : l10n.forecastTomorrow;
  }
  return AppFormatters.dayMonth.format(d);
}

/// "23 Eki Cum" — yaklaşanlar listesinde ve gün panelinde tam tarih.
String forecastFullDay(DateTime day) =>
    DateFormat.MMMEd(Intl.defaultLocale).format(day);

/// TAHMİN manşeti (hız dahil, beklenen yol). Plan görünümünde kullanılmaz;
/// tahmin açıkken plan manşetinin altında mor satır olur.
///
/// Öncelik: (1) maaştan ÖNCE eksiye düşüş, (2) sıradaki maaşa kadar yetiyor
/// mu, (3) ufuk boyunca yetiyor mu. Kart cüzdanında borç zaten eksidir; o
/// zaman cümle ekstre tahminidir.
({String headline, String? detail, bool warning}) forecastHeadline(
  AppLocalizations l10n,
  WalletForecast f,
  MoneyWriter money,
  DateTime today, {
  required DateTime horizonEnd,
}) {
  final card = f.card;
  if (f.isCard && card != null) {
    return (
      headline: l10n.forecastCardEstimate(money(card.statementEstimate)),
      detail: null,
      warning: false,
    );
  }
  final income = f.nextIncome;
  final negative = f.firstNegative;
  if (negative != null &&
      (income == null || negative.day.isBefore(income.date))) {
    return (
      headline: l10n.forecastHeadlineNegative(
          forecastDayLabel(l10n, negative.day, today, inline: true)),
      detail: null,
      warning: true,
    );
  }
  final low = f.lowestPoint(until: income?.date);
  final detail = low == null
      ? null
      : l10n.forecastLowestPoint(
          forecastDayLabel(l10n, low.day, today, inline: true),
          money(low.expected));
  if (income != null) {
    return (
      headline: l10n.forecastHeadlineUntilIncome(income.title,
          forecastDayLabel(l10n, income.date, today, inline: true)),
      detail: detail,
      warning: false,
    );
  }
  return (
    headline:
        l10n.forecastHeadlineOkUntil(AppFormatters.dayMonth.format(horizonEnd)),
    detail: detail,
    warning: false,
  );
}

double _unitRate(ForecastEvent e) => 1;

/// PLAN manşeti — yalnız kesin kalemler (hız yok). Sayfanın birincil
/// cevabı: tahmin açılsa da değişmez.
({String headline, List<String> details, bool warning}) forecastPlanHeadline(
  AppLocalizations l10n,
  WalletForecast f,
  MoneyWriter money,
  DateTime today, {
  required DateTime horizonEnd,
  double Function(ForecastEvent e) rateOf = _unitRate,
}) {
  final card = f.card;
  if (f.isCard && card != null) {
    return (
      headline: l10n.forecastCardSoFarTotal(money(card.statementKnown)),
      details: [
        if (card.pendingAmount > 0.005)
          l10n.forecastCardPending(
            money(card.pendingAmount),
            forecastDayLabel(l10n, card.pendingDue, today, inline: true),
          ),
        l10n.forecastCardClosingDue(
          AppFormatters.dayMonth.format(card.nextClosing),
          AppFormatters.dayMonth.format(card.nextDue),
        ),
      ],
      warning: card.pendingOverdue,
    );
  }

  var outCount = 0, inCount = 0;
  var out = 0.0, inn = 0.0;
  for (final e in f.events) {
    final k = e.knownAmount * rateOf(e);
    if (k < -0.005) {
      outCount++;
      out -= k;
    } else if (k > 0.005) {
      inCount++;
      inn += k;
    }
  }
  final details = <String>[
    if (outCount == 0 && inCount == 0)
      l10n.forecastPlanNothing
    else
      [
        if (outCount > 0) l10n.forecastPlanOutCount(outCount, money(out)),
        if (inCount > 0) l10n.forecastPlanInCount(inCount, money(inn)),
      ].join(' · '),
  ];

  final income = f.nextIncome;
  final negative = f.firstNegativeOf(planned: true);
  if (negative != null &&
      (income == null || negative.day.isBefore(income.date))) {
    return (
      headline: l10n.forecastPlanHeadlineNegative(
          forecastDayLabel(l10n, negative.day, today, inline: true)),
      details: details,
      warning: true,
    );
  }
  final low = f.lowestPointOf(until: income?.date, planned: true);
  if (outCount > 0 &&
      low != null &&
      f.path.isNotEmpty &&
      low.planned < f.path.first.planned - 0.005) {
    details.add(l10n.forecastLowestPoint(
        forecastDayLabel(l10n, low.day, today, inline: true),
        money(low.planned)));
  }
  if (income != null) {
    return (
      headline: l10n.forecastPlanHeadlineUntilIncome(income.title,
          forecastDayLabel(l10n, income.date, today, inline: true)),
      details: details,
      warning: false,
    );
  }
  return (
    headline:
        l10n.forecastPlanHeadlineOk(AppFormatters.dayMonth.format(horizonEnd)),
    details: details,
    warning: false,
  );
}

/// Grafiğin bir günü — bakiye ve akışlar, görüntü biriminde.
@immutable
class TimelineDay {
  final DateTime day;

  /// Gün sonu bakiyesi: yalnız kesin kalemlerle ve tahminle (bant dahil).
  final double planned;
  final double expected;
  final double low;
  final double high;

  /// Kesin çıkış / giriş (pozitif).
  final double out;
  final double inn;

  /// Beklenen alacak — bakiyeye katılmaz (içi boş çubuk).
  final double expectedIn;

  /// Tahmini çıkış: kesilmemiş ekstrenin hız payı (hız ayrıca çubuk
  /// olarak çizilmez; mor çizgide ve bantta görünür).
  final double estimatedOut;

  final List<ForecastEvent> events;

  const TimelineDay({
    required this.day,
    required this.planned,
    required this.expected,
    required this.low,
    required this.high,
    this.out = 0,
    this.inn = 0,
    this.expectedIn = 0,
    this.estimatedOut = 0,
    this.events = const [],
  });
}

/// Bakiye yolu + olaylar → gün gün grafik verisi — SAF.
///
/// [rateOf]: olayın kendi biriminden görüntü birimine kur ("Tüm cüzdanlar"da
/// olaylar KENDİ biriminde durur; çubuklar ortak ölçekte çizilmeli).
List<TimelineDay> buildTimelineDays(
  List<BalancePoint> path,
  List<ForecastEvent> events, {
  double Function(ForecastEvent e) rateOf = _unitRate,
}) {
  final byDay = <DateTime, List<ForecastEvent>>{};
  for (final e in events) {
    final d = DateTime(e.date.year, e.date.month, e.date.day);
    (byDay[d] ??= <ForecastEvent>[]).add(e);
  }
  return [
    for (final p in path)
      () {
        final day = DateTime(p.day.year, p.day.month, p.day.day);
        final list = byDay[day] ?? const <ForecastEvent>[];
        var out = 0.0, inn = 0.0, expectedIn = 0.0, estimatedOut = 0.0;
        for (final e in list) {
          final r = rateOf(e);
          final k = e.knownAmount * r;
          if (k < 0) {
            out -= k;
          } else {
            inn += k;
          }
          final est = e.estimatedAmount * r;
          if (est > 0) {
            expectedIn += est;
          } else {
            estimatedOut -= est;
          }
        }
        return TimelineDay(
          day: day,
          planned: p.planned,
          expected: p.expected,
          low: p.low,
          high: p.high,
          out: out,
          inn: inn,
          expectedIn: expectedIn,
          estimatedOut: estimatedOut,
          events: list,
        );
      }(),
  ];
}

/// Manşet kartı: plan cümlesi (tahmin açıkken altında mor tahmin satırı),
/// gün gün çubuklar + planlı bakiye basamağı, göstergeler ve seçili günün
/// kalemleri.
class ForecastTimelineCard extends StatefulWidget {
  final WalletForecast forecast;
  final MoneyWriter money;
  final DateTime today;
  final DateTime horizonEnd;
  final bool estimates;

  /// Olası aralık bandı çizilsin mi; verilmezse cüzdanın hızı varsa.
  /// Birleşik görünümde hız tek bir cüzdana ait değildir.
  final bool? showBand;

  /// Olay → görüntü birimi kuru (birleşik görünüm).
  final double Function(ForecastEvent e) rateOf;

  /// Birleşik görünümde gün panelindeki satırın cüzdan adı ve birimi.
  final Map<String, String> walletNames;
  final Map<String, String> currencyOf;

  const ForecastTimelineCard({
    super.key,
    required this.forecast,
    required this.money,
    required this.today,
    required this.horizonEnd,
    required this.estimates,
    this.showBand,
    this.rateOf = _unitRate,
    this.walletNames = const {},
    this.currencyOf = const {},
  });

  @override
  State<ForecastTimelineCard> createState() => _ForecastTimelineCardState();
}

class _ForecastTimelineCardState extends State<ForecastTimelineCard> {
  /// Seçili gün (yol indeksi); başta seçim yok — panel ipucu gösterir.
  int? _selected;

  @override
  void didUpdateWidget(covariant ForecastTimelineCard old) {
    super.didUpdateWidget(old);
    final n = widget.forecast.path.length;
    if (_selected != null && _selected! >= n) _selected = null;
  }

  bool get _band => widget.showBand ?? widget.forecast.pace != null;

  /// Tahmin plandan ayrışıyor mu (hız, bant, beklenen alacak, ekstre payı)?
  bool get _diverges => widget.forecast.path.any((p) =>
      (p.expected - p.planned).abs() > 0.005 || (p.high - p.low).abs() > 0.005);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final f = widget.forecast;
    final violet = MoneyColors.forecastText(theme.brightness);
    final plan = forecastPlanHeadline(l10n, f, widget.money, widget.today,
        horizonEnd: widget.horizonEnd, rateOf: widget.rateOf);
    final estimate = widget.estimates && _diverges
        ? forecastHeadline(l10n, f, widget.money, widget.today,
            horizonEnd: widget.horizonEnd)
        : null;
    final estimateWarns = estimate?.warning ?? false;
    final accent = plan.warning
        ? MoneyColors.bad
        : (estimateWarns ? MoneyColors.forecast : MoneyColors.netPositive);
    final days = buildTimelineDays(f.path, f.events, rateOf: widget.rateOf);
    final hasExpectedIn = days.any((d) => d.expectedIn > 0.005);
    final compact = MediaQuery.sizeOf(context).height < 700;

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
                plan.warning || estimateWarns
                    ? Icons.warning_amber_rounded
                    : (f.isCard
                        ? Icons.credit_card_rounded
                        : Icons.event_available_rounded),
                color: accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  plan.headline,
                  key: const ValueKey('forecast-headline'),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: AppType.strong),
                ),
              ),
            ],
          ),
          for (final d in plan.details)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                d,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          if (estimate != null)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 8),
              child: Row(
                key: const ValueKey('forecast-headline-estimate'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EstimateTag(color: violet),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      estimate.headline,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: violet, fontWeight: AppType.medium),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          ForecastTimelineChart(
            days: days,
            today: widget.today,
            money: widget.money,
            estimates: widget.estimates,
            band: widget.estimates && _band,
            selected: _selected,
            height: compact ? 156 : 188,
            onSelected: (i) => setState(() => _selected = i),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _Legend(
                  kind: _LegendKind.line,
                  color: scheme.primary,
                  label: f.isCard
                      ? l10n.forecastCardPathTitle
                      : l10n.forecastLegendPlanned),
              _Legend(
                  kind: _LegendKind.bar,
                  color: MoneyColors.expense,
                  label: l10n.forecastLegendOut),
              _Legend(
                  kind: _LegendKind.bar,
                  color: MoneyColors.income,
                  label: l10n.forecastLegendIn),
              if (hasExpectedIn)
                _Legend(
                    kind: _LegendKind.hollow,
                    color: widget.estimates
                        ? MoneyColors.forecast
                        : MoneyColors.income,
                    label: l10n.forecastChipExpected),
              if (widget.estimates && _diverges)
                _Legend(
                    kind: _LegendKind.dashed,
                    color: MoneyColors.forecast,
                    label: l10n.forecastLegendEstimated),
              if (widget.estimates && _band)
                _Legend(
                    kind: _LegendKind.bar,
                    color: MoneyColors.forecast.withValues(alpha: 0.3),
                    label: l10n.forecastLegendRange),
            ],
          ),
          const Divider(height: 24),
          _DayPanel(
            key: const ValueKey('forecast-day-panel'),
            day: _selected == null ? null : days[_selected!],
            index: _selected,
            money: widget.money,
            estimates: widget.estimates,
            showEstimate: widget.estimates && _diverges,
            walletNames: widget.walletNames,
            currencyOf: widget.currencyOf,
          ),
        ],
      ),
    );
  }
}

/// Küçük mor "Tahmin" etiketi.
class _EstimateTag extends StatelessWidget {
  final Color color;

  const _EstimateTag({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: MoneyColors.forecast.withValues(alpha: 0.12),
        borderRadius: AppRadius.controlAll,
      ),
      child: Text(
        context.l10n.forecastEstimateLabel,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: AppType.strong),
      ),
    );
  }
}

enum _LegendKind { line, dashed, bar, hollow }

class _Legend extends StatelessWidget {
  final _LegendKind kind;
  final Color color;
  final String label;

  const _Legend({required this.kind, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget mark = switch (kind) {
      _LegendKind.line => Container(width: 14, height: 3, color: color),
      _LegendKind.dashed => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 5, height: 3, color: color),
            const SizedBox(width: 3),
            Container(width: 5, height: 3, color: color),
          ],
        ),
      _LegendKind.bar => Container(
          width: 8,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
      _LegendKind.hollow => Container(
          width: 8,
          height: 12,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 6),
        Text(label, style: chartAxisLabelStyle(scheme)),
      ],
    );
  }
}

/// Seçili günün kalemleri — grafiğin metin karşılığı.
class _DayPanel extends StatelessWidget {
  final TimelineDay? day;
  final int? index;
  final MoneyWriter money;
  final bool estimates;
  final bool showEstimate;
  final Map<String, String> walletNames;
  final Map<String, String> currencyOf;

  const _DayPanel({
    super.key,
    required this.day,
    required this.index,
    required this.money,
    required this.estimates,
    required this.showEstimate,
    required this.walletNames,
    required this.currencyOf,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final d = day;
    if (d == null) {
      return Row(
        children: [
          Icon(Icons.touch_app_outlined,
              size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.forecastDayHint, style: muted)),
        ],
      );
    }
    final violet = MoneyColors.forecastText(theme.brightness);
    final rows = [
      for (final e in d.events)
        if (e.hasKnownPart ||
            e.kind == ForecastEventKind.receivable ||
            (estimates && e.hasEstimatedPart))
          e,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${forecastFullDay(d.day)} · ${l10n.forecastDaysAway(index ?? 0)}',
          style:
              theme.textTheme.labelLarge?.copyWith(fontWeight: AppType.strong),
        ),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          Text(l10n.forecastDayNothing, style: muted)
        else
          for (final e in rows) _row(context, e, violet),
        const SizedBox(height: 6),
        Text(l10n.forecastDayPlannedBalance(money(d.planned)), style: muted),
        if (showEstimate)
          Text(
            l10n.forecastDayEstimatedBalance(money(d.expected)),
            style: theme.textTheme.bodySmall?.copyWith(color: violet),
          ),
      ],
    );
  }

  Widget _row(BuildContext context, ForecastEvent e, Color violet) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = currencyOf[e.walletId];
    final m = c == null || c == money.currency
        ? money
        : MoneyWriter(currency: c, visible: money.visible);
    final receivable = e.kind == ForecastEventKind.receivable;
    final wallet = walletNames[e.walletId];
    final title = forecastEventTitle(l10n, e);
    final amount = receivable ? e.amount : e.knownAmount;
    final amountColor = receivable
        ? (estimates ? violet : MoneyColors.incomeText(theme.brightness))
        : (amount > 0
            ? MoneyColors.incomeText(theme.brightness)
            : scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              wallet == null ? title : '$title · $wallet',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (receivable || e.hasKnownPart)
                Text(
                  m.withSign(amount),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: amountColor, fontWeight: AppType.strong),
                ),
              if (receivable)
                Text(l10n.forecastChipExpected,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: estimates ? violet : scheme.onSurfaceVariant))
              else if (estimates && e.hasEstimatedPart)
                Text(
                  l10n.forecastEstimatedPart(m(e.estimatedAmount.abs())),
                  style: theme.textTheme.labelSmall?.copyWith(color: violet),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gün gün çubuklar + planlı bakiye basamağı (+ tahmin açıkken mor kesikli
/// beklenen çizgi ve mor bant).
///
/// fl_chart'ta çubuk ile çizgiyi aynı eksende birleştirmek hizalanmıyor ve
/// dokunuşu yalnız üstteki grafik alıyordu; bakiye hattındaki gibi tek bir
/// painter. Üst şerit bakiye, alt şerit akışlar; ikisi aynı x ekseninde.
/// Dokunmak ya da parmağı yatayda gezdirmek günü seçer; ekran okuyucuda
/// kaydırıcı gibi artır/azalt.
class ForecastTimelineChart extends StatelessWidget {
  final List<TimelineDay> days;
  final DateTime today;
  final MoneyWriter money;
  final bool estimates;
  final bool band;
  final int? selected;
  final ValueChanged<int> onSelected;
  final double height;

  const ForecastTimelineChart({
    super.key,
    required this.days,
    required this.today,
    required this.money,
    required this.estimates,
    required this.band,
    required this.selected,
    required this.onSelected,
    this.height = 188,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final labelHeight = MediaQuery.textScalerOf(context).scale(14) + 6;
    final n = days.length;
    final sel = selected;
    final next = (sel ?? -1) + 1;
    final dayName =
        sel == null ? l10n.forecastChartNoDay : forecastFullDay(days[sel].day);

    void select(int i, {bool haptic = false}) {
      if (i == selected) return;
      if (haptic) HapticFeedback.selectionClick();
      onSelected(i);
    }

    return Semantics(
      container: true,
      slider: true,
      label: l10n.forecastChartLabel(dayName),
      value: dayName,
      // Seçim yokken "artır" ilk günü seçer.
      increasedValue: next < n ? forecastFullDay(days[next].day) : null,
      decreasedValue:
          sel != null && sel > 0 ? forecastFullDay(days[sel - 1].day) : null,
      onIncrease: next < n ? () => select(next) : null,
      onDecrease: sel != null && sel > 0 ? () => select(sel - 1) : null,
      child: ExcludeSemantics(
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          const gutter = kValueAxisWidth;
          final chartW = math.max(1.0, width - gutter);
          final step = chartW / n;
          final slot = scaledDateLabelSlot(context);
          final fitStep = dateLabelStep(
              pointCount: n, availableWidth: chartW, slotWidth: slot);
          // Haftalık ritim (bugünden 7, 14… gün sonra) uzun ufukta kalır;
          // dar ekran ya da büyük yazıda iki-üç haftaya açılır.
          final every =
              n >= 14 ? 7 * math.max(1, (fitStep / 7).ceil()) : fitStep;
          final scale = _Scale.of(days, estimates: estimates, band: band);
          final topH = height * 0.62;

          int indexAt(double dx) =>
              ((dx - gutter) / step).floor().clamp(0, n - 1);

          return SizedBox(
            height: height + labelHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: gutter,
                  top: 0,
                  width: chartW,
                  height: height,
                  child: CustomPaint(
                    painter: _TimelinePainter(
                      days: days,
                      scale: scale,
                      estimates: estimates,
                      band: band,
                      selected: selected,
                      topShare: 0.62,
                      line: scheme.primary,
                      out: MoneyColors.expense,
                      inn: MoneyColors.income,
                      violet: MoneyColors.forecast,
                      bandAlpha: dark ? 0.18 : 0.12,
                      bad: MoneyColors.bad,
                      guide: scheme.outlineVariant,
                      highlight: scheme.onSurface.withValues(alpha: 0.06),
                      cursor: scheme.onSurface.withValues(alpha: 0.28),
                      surface: scheme.surface,
                    ),
                  ),
                ),
                if (money.visible) ...[
                  for (final v in {scale.maxV, scale.minV})
                    Positioned(
                      left: 0,
                      width: gutter - 6,
                      top: _TimelinePainter.yOf(v, scale, topH) - 7,
                      child: Text(
                        money.compact(v, symbol: false),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: chartAxisLabelStyle(scheme),
                      ),
                    ),
                ],
                for (var i = 0; i < n; i++)
                  if (i % every == 0)
                    Positioned(
                      left: _labelLeft(gutter + step * i + step / 2 - slot / 2,
                          min: gutter - slot / 4, max: width - slot),
                      width: slot,
                      top: height + 4,
                      child: Text(
                        forecastDayLabel(l10n, days[i].day, today),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: chartAxisLabelStyle(scheme),
                      ),
                    ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => select(indexAt(d.localPosition.dx)),
                    onHorizontalDragStart: (d) =>
                        select(indexAt(d.localPosition.dx), haptic: true),
                    onHorizontalDragUpdate: (d) =>
                        select(indexAt(d.localPosition.dx), haptic: true),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Etiketi grafiğin içinde tutar; dar alanda alt sınır üstünkünü geçerse
/// (clamp atardı) üst sınır kazanır.
double _labelLeft(double v, {required double min, required double max}) {
  final hi = math.max(0.0, max);
  return v.clamp(math.min(min, hi), hi);
}

/// Üst şeridin değer ölçeği (dolgu dahil) ve alt şeridin akış ölçeği.
class _Scale {
  /// Verinin gerçek uçları (eksen etiketleri).
  final double minV;
  final double maxV;

  /// Dolgulu çizim aralığı.
  final double lo;
  final double hi;

  /// Alt şerit: en büyük günlük giriş ve çıkış.
  final double maxUp;
  final double maxDown;

  const _Scale(
      this.minV, this.maxV, this.lo, this.hi, this.maxUp, this.maxDown);

  factory _Scale.of(List<TimelineDay> days,
      {required bool estimates, required bool band}) {
    var minV = days.first.planned, maxV = days.first.planned;
    var up = 0.0, down = 0.0;
    void take(double v) {
      minV = math.min(minV, v);
      maxV = math.max(maxV, v);
    }

    for (final d in days) {
      take(d.planned);
      if (estimates) {
        take(d.expected);
        if (band) {
          take(d.low);
          take(d.high);
        }
      }
      up = math.max(up, d.inn + d.expectedIn);
      down = math.max(down, d.out + (estimates ? d.estimatedOut : 0));
    }
    var lo = minV, hi = maxV;
    if (hi - lo < 1) {
      final pad = math.max(10.0, lo.abs() * 0.05);
      lo -= pad;
      hi += pad;
    } else {
      final pad = (hi - lo) * 0.1;
      lo -= pad;
      hi += pad;
    }
    return _Scale(minV, maxV, lo, hi, up, down);
  }
}

class _TimelinePainter extends CustomPainter {
  final List<TimelineDay> days;
  final _Scale scale;
  final bool estimates;
  final bool band;
  final int? selected;
  final double topShare;
  final Color line;
  final Color out;
  final Color inn;
  final Color violet;
  final double bandAlpha;
  final Color bad;
  final Color guide;
  final Color highlight;
  final Color cursor;
  final Color surface;

  _TimelinePainter({
    required this.days,
    required this.scale,
    required this.estimates,
    required this.band,
    required this.selected,
    required this.topShare,
    required this.line,
    required this.out,
    required this.inn,
    required this.violet,
    required this.bandAlpha,
    required this.bad,
    required this.guide,
    required this.highlight,
    required this.cursor,
    required this.surface,
  });

  static const double _padV = 6;
  static const double _laneGap = 10;

  /// Üst şeritte [v] değerinin y'si ([topH] = üst şeridin yüksekliği).
  static double yOf(double v, _Scale s, double topH) =>
      _padV + (1 - (v - s.lo) / (s.hi - s.lo)) * (topH - 2 * _padV);

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    if (n == 0) return;
    final step = size.width / n;
    double x(int i) => step * i + step / 2;
    final topH = size.height * topShare;
    double y(double v) => yOf(v, scale, topH);

    final sel = selected;
    if (sel != null) {
      canvas.drawRect(Rect.fromLTWH(step * sel, 0, step, size.height),
          Paint()..color = highlight);
    }

    // Sıfır çizgisi: eşiği geçmek görünür olsun.
    if (scale.lo < 0 && scale.hi > 0) {
      _dashedLine(canvas, Offset(0, y(0)), Offset(size.width, y(0)),
          bad.withValues(alpha: 0.55), 1, 4, 3);
    }

    // Tahmin: mor bant + mor kesikli beklenen çizgi.
    if (estimates) {
      if (band) {
        final poly = <Offset>[
          for (var i = 0; i < n; i++) Offset(x(i), y(days[i].high)),
          for (var i = n - 1; i >= 0; i--) Offset(x(i), y(days[i].low)),
        ];
        canvas.drawPath(Path()..addPolygon(poly, true),
            Paint()..color = violet.withValues(alpha: bandAlpha));
      }
      final diverges = days.any((d) => (d.expected - d.planned).abs() > 0.005);
      if (diverges) {
        final p = Path()..moveTo(x(0), y(days[0].expected));
        for (var i = 1; i < n; i++) {
          p.lineTo(x(i), y(days[i].expected));
        }
        _dashedPath(
            canvas,
            p,
            Paint()
              ..color = violet
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeJoin = StrokeJoin.round,
            5,
            4);
      }
    }

    // Plan: basamaklı düz çizgi — bakiye ödeme gününde sıçrar.
    final planned = Path()..moveTo(x(0), y(days[0].planned));
    for (var i = 1; i < n; i++) {
      planned
        ..lineTo(x(i), y(days[i - 1].planned))
        ..lineTo(x(i), y(days[i].planned));
    }
    canvas.drawPath(
      planned,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    // İlk planlı eksi gün.
    final neg = days.indexWhere((d) => d.planned < -0.005);
    if (neg >= 0) {
      final c = Offset(x(neg), y(days[neg].planned));
      canvas.drawCircle(c, 5, Paint()..color = surface);
      canvas.drawCircle(
          c,
          5,
          Paint()
            ..color = bad
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }

    // Akışlar: orta çizgiden yukarı giriş, aşağı çıkış. İki yön AYRI
    // ölçekte: ortak ölçekte tek bir maaş 30.000 iken 230'luk abonelik 2px'e
    // iniyordu — oysa plan görünümünün sorusu "hangi gün ne ödeyeceğim".
    // Çıkışlar alanın çoğunu alır; tutarlar gün panelinde yazılı.
    final laneTop = topH + _laneGap;
    final laneH = size.height - laneTop;
    final hasUp = scale.maxUp > 0.005;
    final hasDown = scale.maxDown > 0.005;
    final mid = hasUp && hasDown
        ? laneTop + laneH * 0.35
        : (hasUp ? size.height - 1 : laneTop + 1);
    canvas.drawLine(
        Offset(0, mid), Offset(size.width, mid), Paint()..color = guide);
    final upK = hasUp ? (mid - laneTop) / scale.maxUp : 0.0;
    final downK = hasDown ? (size.height - mid) / scale.maxDown : 0.0;
    if (hasUp || hasDown) {
      final w = (step * 0.6).clamp(2.0, 10.0);
      double h(double v, double k) => v <= 0 ? 0 : math.max(2.0, v * k);
      for (var i = 0; i < n; i++) {
        final d = days[i];
        final left = x(i) - w / 2;
        var downEnd = mid;
        if (d.out > 0.005) {
          final r = Rect.fromLTWH(left, mid, w, h(d.out, downK));
          canvas.drawRRect(
              RRect.fromRectAndRadius(r, const Radius.circular(1.5)),
              Paint()..color = out);
          downEnd = r.bottom;
        }
        if (estimates && d.estimatedOut > 0.005) {
          final r = Rect.fromLTWH(left, downEnd, w, h(d.estimatedOut, downK));
          canvas.drawRRect(
              RRect.fromRectAndRadius(r, const Radius.circular(1.5)),
              Paint()..color = violet);
        }
        var upEnd = mid;
        if (d.inn > 0.005) {
          final r = Rect.fromLTWH(left, mid - h(d.inn, upK), w, h(d.inn, upK));
          canvas.drawRRect(
              RRect.fromRectAndRadius(r, const Radius.circular(1.5)),
              Paint()..color = inn);
          upEnd = r.top;
        }
        if (d.expectedIn > 0.005) {
          final hh = h(d.expectedIn, upK);
          final r = Rect.fromLTWH(left + 0.75, upEnd - hh, w - 1.5, hh);
          canvas.drawRRect(
              RRect.fromRectAndRadius(r, const Radius.circular(1.5)),
              Paint()
                ..color = estimates ? violet : inn
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5);
        }
      }
    }

    if (sel != null) {
      final cx = x(sel);
      canvas.drawLine(
          Offset(cx, 0),
          Offset(cx, size.height),
          Paint()
            ..color = cursor
            ..strokeWidth = 1.5);
      final c = Offset(cx, y(days[sel].planned));
      canvas.drawCircle(c, 5.5, Paint()..color = line);
      if (estimates && (days[sel].expected - days[sel].planned).abs() > 0.005) {
        final e = Offset(cx, y(days[sel].expected));
        canvas.drawCircle(e, 5, Paint()..color = surface);
        canvas.drawCircle(
            e,
            5,
            Paint()
              ..color = violet
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }
  }

  static void _dashedLine(Canvas canvas, Offset a, Offset b, Color color,
      double width, double dash, double gap) {
    _dashedPath(
        canvas,
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke,
        dash,
        gap);
  }

  static void _dashedPath(
      Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) =>
      old.days != days ||
      old.selected != selected ||
      old.estimates != estimates ||
      old.band != band ||
      old.line != line ||
      old.surface != surface ||
      old.bandAlpha != bandAlpha;
}
