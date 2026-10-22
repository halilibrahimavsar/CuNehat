import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_series.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dönemin bakiye çizgisi: geçmiş düz; gelecek PLANDA yalnız kesin
/// kalemlerle soluk basamak, TAHMİNDE üstüne mor kesikli beklenen çizgi +
/// mor belirsizlik bandı (bkz. [BalanceLineSeries.estimates]).
///
/// **Gün seçici de budur.** Dokunmak ya da parmağı yatayda gezdirmek günü
/// seçer; ekran okuyucuda kaydırıcı gibi artır/azalt ile gezilir. Çizginin
/// kendisi rakam YAZMAZ: tutarlar gizliyken (göz düğmesi) bile şekil
/// güvenle görünür, rakam yalnız üstteki `MoneyText`'tedir.
///
/// Çizgi BASAMAKLIDIR: bakiye gün içinde kayıtlarla sıçrar, iki gün arası
/// eğik bir çizgi "bakiye yavaş yavaş eridi" gibi yanlış bir hikâye anlatır.
/// Planlı gelecek de basamaklıdır (ödeme gününde sıçrar); tahmin ise düz
/// parçalı (L): hız her güne yayılır, basamak kesinlik ima ederdi.
class BalanceLineChart extends StatefulWidget {
  final BalanceLineSeries series;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;

  /// Ekran okuyucu için günün adı ("22 Ekim Perşembe").
  final String Function(BalanceDay day) semanticDay;

  /// Ekran okuyucunun okuduğu kap etiketi; seçili günün adını içerir.
  final String Function(String day) semanticLabel;

  const BalanceLineChart({
    super.key,
    required this.series,
    required this.selectedIndex,
    required this.onSelected,
    required this.semanticDay,
    required this.semanticLabel,
    this.height = 150,
  });

  @override
  State<BalanceLineChart> createState() => _BalanceLineChartState();
}

class _BalanceLineChartState extends State<BalanceLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppMotion.medium);
  late Animation<double> _cursor =
      AlwaysStoppedAnimation(widget.selectedIndex.toDouble());

  @override
  void didUpdateWidget(covariant BalanceLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.selectedIndex.toDouble();
    if (oldWidget.series != widget.series) {
      // Dönem değişti: eski konumdan kaymak anlamsız, yeni güne otur.
      _controller.stop();
      _cursor = AlwaysStoppedAnimation(target);
      return;
    }
    if (_cursor.value == target) return;
    _controller.duration = AppMotion.of(context).d(AppMotion.medium);
    _cursor = Tween(begin: _cursor.value, end: target)
        .animate(CurvedAnimation(parent: _controller, curve: AppMotion.enter));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _indexAt(double dx, double width) {
    final n = widget.series.days.length;
    if (n == 0 || width <= 0) return 0;
    return (dx / width * n).floor().clamp(0, n - 1);
  }

  void _select(int index, {bool haptic = false}) {
    if (index == widget.selectedIndex) return;
    if (haptic) HapticFeedback.selectionClick();
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = widget.series.days;
    final i = widget.selectedIndex;
    final dayName = days.isEmpty ? '' : widget.semanticDay(days[i]);

    return Semantics(
      container: true,
      slider: true,
      label: widget.semanticLabel(dayName),
      value: dayName,
      increasedValue:
          i + 1 < days.length ? widget.semanticDay(days[i + 1]) : null,
      decreasedValue: i > 0 ? widget.semanticDay(days[i - 1]) : null,
      onIncrease: i + 1 < days.length ? () => _select(i + 1) : null,
      onDecrease: i > 0 ? () => _select(i - 1) : null,
      child: ExcludeSemantics(
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(_indexAt(d.localPosition.dx, width)),
            onHorizontalDragStart: (d) =>
                _select(_indexAt(d.localPosition.dx, width), haptic: true),
            onHorizontalDragUpdate: (d) =>
                _select(_indexAt(d.localPosition.dx, width), haptic: true),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: Size(width, widget.height),
                painter: _BalanceLinePainter(
                  series: widget.series,
                  cursor: _cursor.value,
                  line: scheme.primary,
                  planned: scheme.primary.withValues(alpha: 0.55),
                  estimate: MoneyColors.forecast,
                  band: MoneyColors.forecast.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.18 : 0.12),
                  guide: scheme.outlineVariant,
                  cursorColor: scheme.onSurface.withValues(alpha: 0.28),
                  surface: scheme.surface,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BalanceLinePainter extends CustomPainter {
  final BalanceLineSeries series;
  final double cursor;
  final Color line;

  /// Planlı gelecek (soluk, düz basamak).
  final Color planned;

  /// Tahmin (mor): kesikli beklenen çizgi, imleç halkası.
  final Color estimate;
  final Color band;
  final Color guide;
  final Color cursorColor;
  final Color surface;

  _BalanceLinePainter({
    required this.series,
    required this.cursor,
    required this.line,
    required this.planned,
    required this.estimate,
    required this.band,
    required this.guide,
    required this.cursorColor,
    required this.surface,
  });

  static const double _padV = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final days = series.days;
    final range = series.valueRange;
    if (days.isEmpty) return;
    final step = size.width / days.length;
    double x(num i) => step * i + step / 2;

    canvas.drawLine(Offset(0, size.height - 0.5),
        Offset(size.width, size.height - 0.5), Paint()..color = guide);

    final todayIndex = series.todayIndex;
    if (todayIndex >= 0) {
      _dashedLine(canvas, Offset(x(todayIndex), 0),
          Offset(x(todayIndex), size.height), guide, 1, 2, 4);
    }
    if (range == null) return;

    var (lo, hi) = range;
    if (hi - lo < 1) {
      final pad = math.max(1.0, lo.abs() * 0.05);
      lo -= pad;
      hi += pad;
    } else {
      final pad = (hi - lo) * 0.08;
      lo -= pad;
      hi += pad;
    }
    double y(double v) =>
        _padV + (1 - (v - lo) / (hi - lo)) * (size.height - 2 * _padV);

    // Sıfır çizgisi (kart borcu, eksi bakiye): eşiği geçmek görünür olsun.
    if (lo < 0 && hi > 0) {
      _dashedLine(
          canvas, Offset(0, y(0)), Offset(size.width, y(0)), guide, 1, 3, 3);
    }

    final lastPast =
        days.lastIndexWhere((d) => !d.isFuture && d.balance != null);

    // Gelecek: bugünden (ya da dönemin ilk gününden) başlar.
    final futureIdx = [
      for (var i = 0; i < days.length; i++)
        if (days[i].isFuture && days[i].balance != null) i,
    ];
    if (futureIdx.isNotEmpty) {
      final anchor = lastPast >= 0 ? lastPast : null;
      final anchorValue = anchor == null ? null : days[anchor].balance!;

      if (series.estimates) {
        // Mor bant: tahminin ne kadar şaşabileceği.
        final hiPts = <Offset>[
          if (anchor != null) Offset(x(anchor), y(anchorValue!)),
          for (final i in futureIdx)
            Offset(x(i), y(days[i].high ?? days[i].balance!)),
        ];
        final loPts = <Offset>[
          for (final i in futureIdx.reversed)
            Offset(x(i), y(days[i].low ?? days[i].balance!)),
          if (anchor != null) Offset(x(anchor), y(anchorValue!)),
        ];
        canvas.drawPath(Path()..addPolygon([...hiPts, ...loPts], true),
            Paint()..color = band);
      }

      // Planlı basamak: yalnız kesin kalemler; ödeme gününde sıçrar.
      final plannedPath = Path();
      double? prev = anchorValue;
      if (anchor != null) plannedPath.moveTo(x(anchor), y(anchorValue!));
      for (final i in futureIdx) {
        final v = days[i].planned ?? days[i].balance!;
        if (prev == null) {
          plannedPath.moveTo(x(i), y(v));
        } else {
          plannedPath
            ..lineTo(x(i), y(prev))
            ..lineTo(x(i), y(v));
        }
        prev = v;
      }
      canvas.drawPath(
        plannedPath,
        Paint()
          ..color = planned
          ..style = PaintingStyle.stroke
          ..strokeWidth = series.estimates ? 1.5 : 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );

      if (series.estimates) {
        final expected = Path();
        var first = true;
        for (final p in [
          if (anchor != null) Offset(x(anchor), y(anchorValue!)),
          for (final i in futureIdx) Offset(x(i), y(days[i].balance!)),
        ]) {
          first ? expected.moveTo(p.dx, p.dy) : expected.lineTo(p.dx, p.dy);
          first = false;
        }
        _dashedPath(
            canvas,
            expected,
            Paint()
              ..color = estimate
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..strokeJoin = StrokeJoin.round,
            4,
            5);
      }
    }

    // Geçmiş: basamaklı çizgi + altında solan dolgu.
    if (lastPast >= 0) {
      final past = Path()..moveTo(x(0), y(days[0].balance!));
      for (var i = 1; i <= lastPast; i++) {
        past
          ..lineTo(x(i), y(days[i - 1].balance!))
          ..lineTo(x(i), y(days[i].balance!));
      }
      final area = Path.from(past)
        ..lineTo(x(lastPast), size.height)
        ..lineTo(x(0), size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, size.height),
            [line.withValues(alpha: 0.24), line.withValues(alpha: 0)],
          ),
      );
      canvas.drawPath(
        past,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // İmleç: seçili gün (kayarak gelir, bkz. [_BalanceLineChartState]).
    final cx = x(cursor);
    canvas.drawLine(
        Offset(cx, 0),
        Offset(cx, size.height),
        Paint()
          ..color = cursorColor
          ..strokeWidth = 1.5);
    final dotValue = _valueAt(cursor);
    if (dotValue != null) {
      final c = Offset(cx, y(dotValue));
      final isFuture = days[cursor.round().clamp(0, days.length - 1)].isFuture;
      canvas.drawCircle(c, 9, Paint()..color = line.withValues(alpha: 0.18));
      if (isFuture) {
        canvas.drawCircle(c, 5, Paint()..color = surface);
        canvas.drawCircle(
            c,
            5,
            Paint()
              ..color = series.estimates ? estimate : line
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      } else {
        canvas.drawCircle(c, 5.5, Paint()..color = line);
      }
    }
  }

  /// İmlecin (kesirli) konumundaki bakiye: iki komşu gün arasında doğrusal.
  double? _valueAt(double t) {
    final days = series.days;
    final a = t.floor().clamp(0, days.length - 1);
    final b = t.ceil().clamp(0, days.length - 1);
    final va = days[a].balance, vb = days[b].balance;
    if (va == null) return vb;
    if (vb == null) return va;
    return ui.lerpDouble(va, vb, t - a);
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
  bool shouldRepaint(covariant _BalanceLinePainter old) =>
      old.series != series ||
      old.cursor != cursor ||
      old.line != line ||
      old.planned != planned ||
      old.band != band ||
      old.surface != surface;
}

/// Grafiğin altındaki gün numaraları: hepsi değil, ÖNEMLİ olanlar —
/// seçili gün (dolu hap), bugün (vurgulu), dönemin ilk ve son günü. Ayın 30
/// günü 320dp'ye yazılınca hücre başına ~9dp kalıyordu; okunmayan 30 rakam
/// yerine okunan dört rakam.
class BalanceLineTicks extends StatelessWidget {
  final BalanceLineSeries series;
  final int selectedIndex;

  const BalanceLineTicks({
    super.key,
    required this.series,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    return SizedBox(
      height: scaler.scale(12) + 10,
      width: double.infinity,
      child: CustomPaint(
        painter: _TicksPainter(
          series: series,
          selected: selectedIndex,
          scaler: scaler,
          // Yazı tipi temadan: ressam TextPainter'ı DefaultTextStyle'ı
          // görmez, aile verilmezse platform varsayılanına düşer.
          base: DefaultTextStyle.of(context).style,
          text: scheme.onSurfaceVariant,
          today: scheme.primary,
          pill: scheme.onSurface,
          onPill: scheme.surface,
        ),
      ),
    );
  }
}

class _TicksPainter extends CustomPainter {
  final BalanceLineSeries series;
  final int selected;
  final TextScaler scaler;
  final TextStyle base;
  final Color text;
  final Color today;
  final Color pill;
  final Color onPill;

  _TicksPainter({
    required this.series,
    required this.selected,
    required this.scaler,
    required this.base,
    required this.text,
    required this.today,
    required this.pill,
    required this.onPill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final days = series.days;
    if (days.isEmpty) return;
    final step = size.width / days.length;
    final order = <int>[
      selected,
      if (series.todayIndex >= 0) series.todayIndex,
      0,
      days.length - 1,
    ];
    final placed = <Rect>[];
    for (final i in order.toSet()) {
      final isSel = i == selected;
      final isToday = i == series.todayIndex;
      final tp = TextPainter(
        text: TextSpan(
          text: '${days[i].day.day}',
          style: base.copyWith(
            fontSize: 12,
            fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? onPill : (isToday ? today : text),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final w = math.max(tp.width + 12, size.height);
      final cx = (step * i + step / 2)
          .clamp(w / 2, math.max(w / 2, size.width - w / 2))
          .toDouble();
      final rect = Rect.fromCenter(
          center: Offset(cx, size.height / 2), width: w, height: size.height);
      if (placed.any((r) => r.inflate(2).overlaps(rect))) continue;
      placed.add(rect);
      if (isSel) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
            Paint()..color = pill);
      }
      tp.paint(
          canvas, Offset(cx - tp.width / 2, (size.height - tp.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _TicksPainter old) =>
      old.series != series ||
      old.selected != selected ||
      old.scaler != scaler ||
      old.base != base ||
      old.text != text ||
      old.pill != pill;
}
