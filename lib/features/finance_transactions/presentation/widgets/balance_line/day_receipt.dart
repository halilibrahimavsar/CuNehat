import 'package:cunehat/config/theme/app_tokens.dart';
import 'dart:math' as math;

import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_day_notes.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_series.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_style.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_row_actions.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_sections.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dönem içindeki bir kategorinin gider özeti (fiş satırının ayrıntısı).
typedef CategoryPeriodStat = ({int count, double total});

/// Bir günün fişi: kalemler, toplamlar, gün sonu bakiyesi ve not.
///
/// **Neden fiş.** Liste görünümünde aynı gün bilgisi beş katmanda tekrar
/// ediyordu (özet şeridi, gün şeridi, başlık rozeti, kart, gün sonu satırı).
/// Fiş bunu tek bir nesnede, herkesin bildiği bir dille toplar: yukarıdan
/// aşağı kalemler, altta çizgi, toplam, "gün sonu". Ayrıntı satıra
/// dokununca fişin İÇİNDE açılır; ekran değişmez.
///
/// Tutarların hepsi [MoneyText] / [SignedMoneyText]'ten geçer: göz düğmesi
/// fişi de örter.
class DayReceipt extends StatefulWidget {
  final BalanceDay day;
  final String currency;
  final List<DayNote> notes;
  final Map<String, String> categoryLabels;
  final Map<String, IconData> categoryIcons;

  /// `tag` → dönemdeki gider sayısı ve toplamı.
  final Map<String, CategoryPeriodStat> categoryStats;

  /// Kayıtsız geçmiş güne "ekle"; verilmezse düğme çizilmez.
  final VoidCallback? onAdd;

  const DayReceipt({
    super.key,
    required this.day,
    required this.currency,
    required this.notes,
    required this.categoryLabels,
    required this.categoryIcons,
    required this.categoryStats,
    this.onAdd,
  });

  @override
  State<DayReceipt> createState() => _DayReceiptState();
}

class _DayReceiptState extends State<DayReceipt> {
  /// Açık satır; aynı anda tek satır açılır (fiş uzayıp kaybolmasın).
  String? _open;

  @override
  Widget build(BuildContext context) {
    final p = ReceiptPalette.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final day = widget.day;

    final base = TextStyle(
      fontFamily: receiptFontFamily,
      color: p.ink,
      fontSize: 12,
      height: 1.35,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final date = upperForLocale(
      DateFormat('d MMMM y · EEEE', locale.toLanguageTag()).format(day.day),
      locale,
    );
    final count = day.entryCount;

    return DefaultTextStyle(
      style: base,
      child: PhysicalShape(
        clipper: const _ZigzagClipper(),
        color: p.paper,
        elevation: 2,
        shadowColor: p.shadow,
        // Satırların InkWell dalgası kâğıdın ÜSTÜNE boyansın: PhysicalShape
        // bir Material değil, dalga yoksa alttaki sayfaya (kâğıdın arkasına)
        // çizilirdi.
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _up(context, l10n.blReceiptTitle),
                      textAlign: TextAlign.center,
                      style: base.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count > 0
                          ? '$date · ${_up(context, l10n.blReceiptItems(count))}'
                          : date,
                      textAlign: TextAlign.center,
                      style: base.copyWith(fontSize: 12, color: p.muted),
                    ),
                    _Rule(color: p.rule, top: 12, bottom: 6),
                    if (day.isEmpty)
                      _empty(context, p, base)
                    else ...[
                      for (final e in day.items) _txRow(context, e, p, base),
                      for (final e in day.events)
                        _eventRow(context, e, p, base),
                      _Rule(color: p.rule, top: 8, bottom: 8),
                      ..._totals(context, p, base),
                    ],
                    _endLine(context, p, base),
                    if (widget.notes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: '${_up(context, l10n.blNoteLead)} ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: dayNotesText(l10n, widget.notes)),
                        ]),
                        style: base.copyWith(fontSize: 12, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
              if (day.isFuture && !day.isEmpty)
                Positioned(
                  top: 12,
                  right: 10,
                  child: Transform.rotate(
                    angle: -0.16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: p.stamp, width: 2),
                        borderRadius: AppRadius.controlAll,
                      ),
                      child: Text(
                        _up(context, l10n.blStampPlanned),
                        style: base.copyWith(
                          color: p.stamp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, ReceiptPalette p, TextStyle base) {
    final l10n = context.l10n;
    final future = widget.day.isFuture;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(
            future
                ? _up(context, l10n.blReceiptNoPlans)
                : _up(context, l10n.blReceiptEmpty),
            textAlign: TextAlign.center,
            style: base.copyWith(
                fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1.5),
          ),
          if (!future) ...[
            const SizedBox(height: 6),
            Text(
              l10n.blReceiptEmptyNote,
              textAlign: TextAlign.center,
              style: base.copyWith(fontSize: 12, color: p.muted, height: 1.5),
            ),
            if (widget.onAdd != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onAdd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.ink, width: 1.5),
                  minimumSize: const Size(0, 44),
                  shape: const StadiumBorder(),
                  textStyle: base.copyWith(fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(_up(context, l10n.blReceiptAdd)),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Satır bu genişliğin (yazı ölçeğiyle büyütülmüş) altındaysa saat
  /// sütunu kalkar, saat etiket satırına iner.
  static const double _compactBelow = 250;

  /// Saat sütununun genişliği yazı ölçeğiyle büyür.
  double _timeWidth(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(38);

  Color _amountColor(ReceiptPalette p,
          {required bool moved, required bool income}) =>
      moved ? p.moved : (income ? p.income : p.expense);

  Widget _txRow(BuildContext context, TransactionWithBalance e,
      ReceiptPalette p, TextStyle base) {
    final l10n = context.l10n;
    final t = e.transaction;
    final moved = !isSpendingMovement(t);
    final id = t.id ?? '${t.hashCode}';
    final open = _open == id;
    final label = t.tag.isEmpty
        ? l10n.txKategoriSec
        : widget.categoryLabels[t.tag] ?? context.translateSystemTag(t.tag);
    final locale = Localizations.localeOf(context);
    final time = (t.date.hour == 0 && t.date.minute == 0)
        ? ''
        : DateFormat('HH:mm').format(t.date);
    final tags = <String>[
      upperForLocale(label, locale),
      if (t.installmentNo != null &&
          t.installmentCount != null &&
          t.installmentCount! > 1)
        _up(context,
            l10n.blTagInstallment(t.installmentNo!, t.installmentCount!)),
      if (t.importBatchId != null) _up(context, l10n.blTagImported),
      if (t.receiptFileName != null) _up(context, l10n.blTagReceipt),
    ];
    final amountStyle = base.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: _amountColor(p, moved: moved, income: t.isIncome),
    );
    final accent = MoneyColors.of(t, Theme.of(context).brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: InkWell(
            onTap: () => setState(() => _open = open ? null : id),
            onLongPress: () => showTransactionRowActions(context, e, accent),
            borderRadius: AppRadius.controlAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _line(
                context,
                time: time,
                title: t.title,
                amount: SignedMoneyText(
                  amount: t.amount,
                  isExpense: t.isExpense,
                  currency: widget.currency,
                  style: amountStyle,
                ),
                sub: tags.join(' · '),
                p: p,
                base: base,
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.of(context).d(AppMotion.medium),
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: open
              ? _facts(context, e, label, moved, p, base)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _eventRow(
      BuildContext context, ForecastEvent e, ReceiptPalette p, TextStyle base) {
    final l10n = context.l10n;
    final moved =
        !e.countsAsSpending && e.kind != ForecastEventKind.recurringIncome;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _line(
        context,
        time: _up(context, l10n.blTimePlan),
        title: forecastEventTitle(l10n, e),
        amount: SignedMoneyText(
          amount: e.amount.abs(),
          isExpense: e.amount < 0,
          currency: widget.currency,
          style: base.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _amountColor(p, moved: moved, income: e.amount > 0),
          ),
        ),
        sub: e.certainty == ForecastCertainty.known
            ? _up(context, l10n.blTagPlanned)
            : _up(context, l10n.blTagEstimated),
        p: p,
        base: base,
      ),
    );
  }

  /// Saat · başlık ······ tutar / altında etiketler.
  Widget _line(
    BuildContext context, {
    required String time,
    required String title,
    required Widget amount,
    required String sub,
    required ReceiptPalette p,
    required TextStyle base,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      // Dar satırda (320dp ya da büyük yazı) saat sütunu başlığa yer
      // bırakmıyordu ("Telef…", görüntüde): saat etiket satırının başına
      // taşınır, başlık tüm genişliği alır.
      final compact = constraints.maxWidth <
          MediaQuery.textScalerOf(context).scale(_compactBelow);
      final timeWidth = compact ? 0.0 : _timeWidth(context);
      final subLine = compact && time.isNotEmpty
          ? (sub.isEmpty ? time : '$time · $sub')
          : sub;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!compact) ...[
                SizedBox(
                  width: timeWidth,
                  child: Text(time,
                      maxLines: 1,
                      style: base.copyWith(fontSize: 12, color: p.muted)),
                ),
                const SizedBox(width: 6),
              ],
              // Noktalı kılavuz satırın tamamına çizilir, başlık kâğıt
              // renginde zeminle ÜSTÜNE oturur. Başlık + kılavuzu iki esnek
              // çocuk olarak dizmek alanı yarı yarıya bölüyordu: "Simit
              // Sarayı" bomboş satırda "Simit Sa…" oluyordu (görüntüde).
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Positioned(
                      left: 0,
                      right: 6,
                      bottom: 4,
                      child: CustomPaint(
                        size: const Size.fromHeight(1.5),
                        painter: _DottedPainter(p.rule),
                      ),
                    ),
                    ColoredBox(
                      color: p.paper,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: base.copyWith(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: amount,
                ),
              ),
            ],
          ),
          if (subLine.isNotEmpty)
            Padding(
              padding:
                  EdgeInsets.only(left: compact ? 0 : timeWidth + 6, top: 2),
              child: Text(
                subLine,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                    fontSize: 12, color: p.muted, letterSpacing: 0.3),
              ),
            ),
        ],
      );
    });
  }

  Widget _facts(BuildContext context, TransactionWithBalance e, String label,
      bool moved, ReceiptPalette p, TextStyle base) {
    final l10n = context.l10n;
    final t = e.transaction;
    final style = base.copyWith(fontSize: 12, height: 1.4);
    final valueStyle = style.copyWith(fontWeight: FontWeight.w700);
    final stat = widget.categoryStats[t.tag];

    Widget fact(String k, Widget v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(k, style: style.copyWith(color: p.muted))),
              const SizedBox(width: 8),
              Flexible(child: v),
            ],
          ),
        );

    final left = (t.installmentNo != null && t.installmentCount != null)
        ? t.installmentCount! - t.installmentNo!
        : null;

    return Container(
      margin: EdgeInsets.only(left: _timeWidth(context) + 6, bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 2),
      decoration: BoxDecoration(
        color: p.factFill,
        borderRadius: AppRadius.controlAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fact(
            l10n.blFactAfter,
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: MoneyText(
                amount: e.balanceAfter,
                currency: widget.currency,
                style: valueStyle,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
          if (!moved && t.isExpense && stat != null)
            fact(
              l10n.blFactCategory(label),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${l10n.blFactTimes(stat.count)} · ',
                        style: valueStyle),
                    MoneyText(
                      amount: stat.total,
                      currency: widget.currency,
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
            ),
          if (left != null && left > 0)
            fact(l10n.blFactInstallmentsLeft,
                Text('$left', textAlign: TextAlign.right, style: valueStyle)),
          if (moved)
            fact(
                l10n.blFactReport,
                Text(l10n.blFactNotSpending,
                    textAlign: TextAlign.right, style: valueStyle)),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () => showTransactionRowActions(context, e,
                    MoneyColors.of(t, Theme.of(context).brightness)),
                style: TextButton.styleFrom(
                    foregroundColor: p.ink,
                    textStyle: valueStyle,
                    minimumSize: const Size(0, 44)),
                child: Text(l10n.blFactActions),
              ),
              TextButton(
                onPressed: () => openTransactionDetail(
                  context,
                  e,
                  categoryIcon: widget.categoryIcons[t.tag],
                  categoryLabel: widget.categoryLabels[t.tag],
                ),
                style: TextButton.styleFrom(
                    foregroundColor: p.ink,
                    textStyle: valueStyle,
                    minimumSize: const Size(0, 44)),
                child: Text('${l10n.blFactDetails} ›'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _totals(BuildContext context, ReceiptPalette p, TextStyle base) {
    final l10n = context.l10n;
    final day = widget.day;
    final style = base.copyWith(fontSize: 12);
    final value = style.copyWith(fontWeight: FontWeight.w700);

    Widget row(String k, double amount, {required bool isExpense}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          // spaceBetween: tutar sağa yaslanır. `Expanded` etiket + `Flexible`
          // tutar satırı ikiye bölüyor, tutar ortada kalıyordu (görüntüde).
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(k, style: style.copyWith(letterSpacing: 1))),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: SignedMoneyText(
                    amount: amount,
                    isExpense: isExpense,
                    currency: widget.currency,
                    style: value,
                  ),
                ),
              ),
            ],
          ),
        );

    if (day.isFuture) {
      final out = day.events
          .where((e) => e.amount < 0)
          .fold<double>(0, (s, e) => s - e.amount);
      final inn = day.events
          .where((e) => e.amount > 0)
          .fold<double>(0, (s, e) => s + e.amount);
      return [
        if (out > 0) row(_up(context, l10n.blTotalOut), out, isExpense: true),
        if (inn > 0) row(_up(context, l10n.blTotalIn), inn, isExpense: false),
      ];
    }
    return [
      if (day.expense > 0)
        row(_up(context, l10n.blTotalSpend), day.expense, isExpense: true),
      if (day.income > 0)
        row(_up(context, l10n.blTotalIncome), day.income, isExpense: false),
      if (day.moved != 0)
        row(_up(context, l10n.blTotalMoved), day.moved.abs(),
            isExpense: day.moved < 0),
    ];
  }

  Widget _endLine(BuildContext context, ReceiptPalette p, TextStyle base) {
    final l10n = context.l10n;
    final day = widget.day;
    final label = day.isFuture
        ? _up(context, l10n.blEndProjected)
        : day.isToday
            ? _up(context, l10n.blEndNow)
            : _up(context, l10n.blEndOfDay);
    final valueStyle = base.copyWith(fontSize: 16, fontWeight: FontWeight.w700);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.ink, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              style: base.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: day.balance == null
                  ? Text('—', style: valueStyle)
                  : MoneyText(
                      amount: day.balance!,
                      currency: widget.currency,
                      style: valueStyle,
                      alignment: Alignment.centerRight,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fişin "etiket" yazısı (başlık, toplamlar, damga, satır etiketleri)
/// BÜYÜK HARFLE çizilir — fiş metaforunun tipografisi. Metnin kendisi ARB'de
/// cümle düzeninde durur (bkz. copy_tone_guard): büyük harf bir GÖRÜNÜM
/// kararıdır, metin kararı değil; not cümlesi ve açıklamalar dokunulmaz.
String _up(BuildContext context, String text) =>
    upperForLocale(text, Localizations.localeOf(context));

/// Notları tek cümle dizisine döker.
String dayNotesText(AppLocalizations l10n, List<DayNote> notes) => [
      for (final n in notes)
        switch (n) {
          IncomeDayNote(:final title) => l10n.blNoteIncome(title),
          PaceNote() when n.isNear => l10n.blNoteNear,
          PaceNote(:final percent) => percent > 0
              ? l10n.blNoteAbove(percent)
              : l10n.blNoteBelow(-percent),
          MovedNote() => l10n.blNoteMoved,
          BiggestNote(:final title) => l10n.blNoteBiggest(title),
          StreakNote(:final days) => l10n.blNoteStreak(days),
          NoRecordsNote() => l10n.blNoteNoRecords,
          FutureNote(:final count) => l10n.blNoteFuture(count),
        },
    ].join(' ');

class _Rule extends StatelessWidget {
  final Color color;
  final double top;
  final double bottom;

  const _Rule({required this.color, required this.top, required this.bottom});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: bottom),
        child: CustomPaint(
          size: const Size.fromHeight(1.5),
          painter: _DashedRulePainter(color),
        ),
      );
}

class _DashedRulePainter extends CustomPainter {
  final Color color;
  const _DashedRulePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(
          Offset(x, y), Offset(math.min(x + 5, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRulePainter old) => old.color != color;
}

/// Başlık ile tutar arasındaki noktalı kılavuz (fişin "······").
class _DottedPainter extends CustomPainter {
  final Color color;
  const _DottedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final r = size.height / 2;
    for (var x = r; x < size.width; x += 4) {
      canvas.drawCircle(Offset(x, r), r * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedPainter old) => old.color != color;
}

/// Alt kenarı tırtıklı kâğıt.
class _ZigzagClipper extends CustomClipper<Path> {
  const _ZigzagClipper();

  static const double _tooth = 8;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - _tooth);
    final teeth = (size.width / (_tooth * 2)).ceil();
    final w = size.width / teeth;
    for (var i = teeth; i > 0; i--) {
      final x = i * w;
      path
        ..lineTo(x - w / 2, size.height)
        ..lineTo(x - w, size.height - _tooth);
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant _ZigzagClipper oldClipper) => false;
}
