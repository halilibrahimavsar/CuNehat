import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_day_notes.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_series.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/balance_line_style.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/balance_line/day_receipt.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// İşlemler ekranının varsayılan görünümü: bakiye hattı + gün fişi.
///
/// Soru "hangi gün ne yaptım?" değil, "param nereye gidiyor, ay sonunda
/// nerede olacağım?". Üstte dönemin bakiyesi gün gün (geçmiş düz, gelecek
/// kesikli + bant), altında seçili günün fişi. Gün; çizgiye dokunarak,
/// parmağı gezdirerek ya da ‹ › ile seçilir.
///
/// Liste görünümü kaybolmadı: başlıktaki düğme ona geçer; arama ve süzgeç
/// etkinken sayfa zaten listeyi gösterir (bkz. `TransactionsPage`).
class BalanceLineView extends StatefulWidget {
  final BalanceLineSeries series;

  /// Cüzdanın TAM defteri (yeniden eskiye): notların taban çizgisi.
  final List<TransactionWithBalance> ledger;

  final String currency;
  final Map<String, String> categoryLabels;
  final Map<String, IconData> categoryIcons;

  /// Gelecek günlerin tahmini hesaplanıyor mu.
  final bool forecastLoading;

  final ValueChanged<DateTime> onAddForDay;
  final VoidCallback onShowList;

  /// Verilirse üstte bir kerelik tanıtım şeridi çizilir ("Listeye dön" ve
  /// kapat); ikisi de bunu çağırır (görüldü).
  final VoidCallback? onDismissIntro;

  /// Dönem bugünü KAPSAMIYORSA "Bugün" düğmesinin eylemi (dönemi bugüne
  /// taşır). Kapsıyorsa düğme bugünü seçer, bu kullanılmaz.
  final VoidCallback? onJumpToToday;

  /// Yalnız test: "bugün".
  final DateTime? now;

  const BalanceLineView({
    super.key,
    required this.series,
    required this.ledger,
    required this.currency,
    required this.categoryLabels,
    required this.categoryIcons,
    required this.onAddForDay,
    required this.onShowList,
    this.forecastLoading = false,
    this.onJumpToToday,
    this.onDismissIntro,
    this.now,
  });

  @override
  State<BalanceLineView> createState() => _BalanceLineViewState();
}

class _BalanceLineViewState extends State<BalanceLineView> {
  late int _selected = widget.series.initialIndex;

  // Pahalı türevler: defter ya da dönem değişmedikçe yeniden kurulmaz.
  List<TransactionWithBalance>? _ledgerSource;
  Map<DateTime, double> _dailyExpense = const {};
  DateTime? _firstRecord;
  BalanceLineSeries? _statsSource;
  Map<String, CategoryPeriodStat> _categoryStats = const {};

  @override
  void didUpdateWidget(covariant BalanceLineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDays = oldWidget.series.days;
    final newDays = widget.series.days;
    final samePeriod = oldDays.isNotEmpty &&
        newDays.isNotEmpty &&
        oldDays.first.day == newDays.first.day &&
        oldDays.length == newDays.length;
    if (!samePeriod) {
      _selected = widget.series.initialIndex;
    } else {
      _selected = _selected.clamp(0, newDays.length - 1);
    }
  }

  void _select(int index) {
    if (index == _selected || index < 0) return;
    if (index >= widget.series.days.length) return;
    setState(() => _selected = index);
  }

  void _syncDerived() {
    if (!identical(_ledgerSource, widget.ledger)) {
      _ledgerSource = widget.ledger;
      _dailyExpense = dailyExpenseOf(widget.ledger);
      _firstRecord = widget.ledger.isEmpty
          ? null
          : dateOnly(widget.ledger.last.transaction.date);
    }
    if (!identical(_statsSource, widget.series)) {
      _statsSource = widget.series;
      final stats = <String, CategoryPeriodStat>{};
      for (final d in widget.series.days) {
        for (final e in d.items) {
          final t = e.transaction;
          if (!t.isExpense || !isSpendingMovement(t) || t.tag.isEmpty) continue;
          final s = stats[t.tag];
          stats[t.tag] = (
            count: (s?.count ?? 0) + 1,
            total: (s?.total ?? 0) + t.amount,
          );
        }
      }
      _categoryStats = stats;
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    if (series.isEmpty) return const SizedBox.shrink();
    _syncDerived();

    final day = series.days[_selected];
    final motion = AppMotion.of(context);
    final shortScreen = MediaQuery.sizeOf(context).height < 700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onDismissIntro != null) ...[
            _intro(context),
            const SizedBox(height: 10),
          ],
          _header(context, day),
          const SizedBox(height: 12),
          BalanceLineChart(
            series: series,
            selectedIndex: _selected,
            onSelected: _select,
            height: shortScreen ? 112 : 150,
            semanticDay: (d) => _fullDate(context, d.day),
            semanticLabel: context.l10n.blChartLabel,
          ),
          const SizedBox(height: 6),
          BalanceLineTicks(series: series, selectedIndex: _selected),
          const SizedBox(height: 10),
          _navRow(context, day),
          const SizedBox(height: 14),
          _ReceiptSlot(
            // Kısa fişten uzun fişe geçerken boy sıçramasın.
            child: AnimatedSize(
              duration: motion.d(AppMotion.medium),
              curve: AppMotion.standard,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: motion.d(const Duration(milliseconds: 380)),
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                // Yalnız SON çıkan fiş çizilir: parmak çizgide hızla
                // gezerken her gün bir fiş bırakır, hepsi animasyon süresince
                // ayakta kalsa onlarca tam fiş aynı anda kurulurdu.
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (previous.isNotEmpty) previous.last,
                    if (current != null) current,
                  ],
                ),
                // Fiş yarıktan BASILIR: yukarıdan aşağı kayarak çıkar.
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, -0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: DayReceipt(
                  key: ValueKey(day.day),
                  day: day,
                  currency: widget.currency,
                  estimates: series.estimates,
                  notes: buildDayNotes(
                    day: day,
                    dailyExpense: _dailyExpense,
                    firstRecord: _firstRecord,
                    estimates: series.estimates,
                  ),
                  categoryLabels: widget.categoryLabels,
                  categoryIcons: widget.categoryIcons,
                  categoryStats: _categoryStats,
                  onAdd:
                      day.isFuture ? null : () => widget.onAddForDay(day.day),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Güncellemeyle gelen görünüm değişikliğini söyleyen tek seferlik şerit:
  /// liste kaybolmadı, bir dokunuş uzakta.
  Widget _intro(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey('bl-intro'),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.controlAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(l10n.blIntro, style: theme.textTheme.bodySmall),
          ),
          TextButton(
            key: const ValueKey('bl-intro-list'),
            onPressed: () {
              widget.onDismissIntro?.call();
              widget.onShowList();
            },
            child: Text(l10n.blIntroToList),
          ),
          IconButton(
            key: const ValueKey('bl-intro-close'),
            tooltip: l10n.kapat,
            onPressed: widget.onDismissIntro,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  String _fullDate(BuildContext context, DateTime d) =>
      DateFormat('d MMMM EEEE', Localizations.localeOf(context).toLanguageTag())
          .format(d);

  /// "Bugün / Dün / Yarın" — takvimden, `difference`ten değil (yaz saati
  /// geçişinde 23 saatlik gün `inDays == 0` verir).
  String? _relative(BuildContext context, BalanceDay day) {
    final l10n = context.l10n;
    if (day.isToday) return l10n.blRelToday;
    final now = dateOnly(widget.now ?? DateTime.now());
    if (day.day == DateTime(now.year, now.month, now.day + 1)) {
      return l10n.blRelTomorrow;
    }
    if (day.day == DateTime(now.year, now.month, now.day - 1)) {
      return l10n.blRelYesterday;
    }
    return null;
  }

  Widget _header(BuildContext context, BalanceDay day) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final rel = _relative(context, day);
    final estimates = widget.series.estimates;
    // Tahmini gelecek gün: başlık ve rakam MOR (uygulamanın tahmin rengi).
    final estimated = day.isFuture && estimates;
    final violet = MoneyColors.forecastText(theme.brightness);
    final kicker = [
      upperForLocale(
          day.isFuture
              ? (estimates ? l10n.blKickerProjected : l10n.blKickerPlanned)
              : l10n.blKickerBalance,
          locale),
      if (rel != null) upperForLocale(rel, locale),
      upperForLocale(_fullDate(context, day.day), locale),
    ].join(' · ');

    final series = widget.series;
    final showToday = series.todayIndex >= 0
        ? _selected != series.todayIndex
        : widget.onJumpToToday != null;
    final motion = AppMotion.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kicker,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: receiptFontFamily,
                  fontSize: 12,
                  letterSpacing: 1,
                  height: 1.3,
                  color: estimated ? violet : scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (showToday)
              TextButton(
                key: const ValueKey('bl-today'),
                onPressed: series.todayIndex >= 0
                    ? () => _select(series.todayIndex)
                    : widget.onJumpToToday,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.blRelToday),
              ),
            // Yazılı düğme: yalnız ikonken listeye dönüş yolu bulunmuyordu
            // (QA O6).
            Tooltip(
              message: l10n.blShowList,
              child: TextButton.icon(
                key: const ValueKey('bl-show-list'),
                onPressed: widget.onShowList,
                icon: const Icon(Icons.view_list_rounded, size: 18),
                label: Text(l10n.blShowListShort),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onSurfaceVariant,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: day.balance == null
                ? Text('—',
                    style: theme.textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w700))
                // Gün değişince rakam SAYARAK yeni değerine gider: iki günün
                // farkı göz ucuyla okunur.
                : TweenAnimationBuilder<double>(
                    tween: Tween(end: day.balance),
                    duration: motion.d(const Duration(milliseconds: 420)),
                    curve: AppMotion.enter,
                    builder: (context, value, _) => MoneyText(
                      amount: value,
                      currency: widget.currency,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.2,
                        height: 1.1,
                        color: estimated ? violet : scheme.onSurface,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        _delta(context, day),
      ],
    );
  }

  Widget _delta(BuildContext context, BalanceDay day) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 14);

    Widget part(double amount, bool isExpense, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SignedMoneyText(
              amount: amount,
              isExpense: isExpense,
              currency: widget.currency,
              style: muted?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(' $label', style: muted),
          ],
        );

    final List<Widget> parts;
    if (day.isFuture) {
      if (day.balance == null) {
        parts = [
          Text(
              widget.forecastLoading
                  ? l10n.blDeltaLoading
                  : l10n.blDeltaNoForecast,
              style: muted)
        ];
      } else if (widget.series.estimates) {
        // MoneyText (görünürlük sarmalayıcısı) sınırlı genişlikte TÜM
        // satırı kaplar: Wrap içinde her parça ayrı satıra düşüyordu
        // (görüntüde). Sınırsız Row'da kendi boyuna iner; dar ekranda
        // FittedBox küçültür (eskiden 72px taşıyordu).
        final range =
            muted?.copyWith(color: MoneyColors.forecastText(theme.brightness));
        parts = [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${l10n.blDeltaRange} ', style: range),
                MoneyText(
                    amount: day.low ?? day.balance!,
                    currency: widget.currency,
                    style: range),
                Text(' – ', style: range),
                MoneyText(
                    amount: day.high ?? day.balance!,
                    currency: widget.currency,
                    style: range),
              ],
            ),
          ),
        ];
      } else {
        // Plan: günün kesin hareketleri (geçmiş günlerle aynı dil).
        parts = [
          if (day.expense > 0) part(day.expense, true, l10n.blDeltaSpend),
          if (day.income > 0) part(day.income, false, l10n.blDeltaIncome),
          if (day.moved.abs() > 0.005)
            part(day.moved.abs(), day.moved < 0, l10n.blDeltaMoved),
        ];
        if (parts.isEmpty) {
          parts.add(Text(l10n.blReceiptNoPlans, style: muted));
        }
      }
    } else {
      parts = [
        if (day.expense > 0) part(day.expense, true, l10n.blDeltaSpend),
        if (day.income > 0) part(day.income, false, l10n.blDeltaIncome),
        if (day.moved.abs() > 0.005)
          part(day.moved.abs(), day.moved < 0, l10n.blDeltaMoved),
      ];
      if (parts.isEmpty) parts.add(Text(l10n.blDeltaNone, style: muted));
    }
    return Wrap(spacing: 10, runSpacing: 2, children: parts);
  }

  /// ‹ [günün kategori çubuğu + açıklaması] ›
  Widget _navRow(BuildContext context, BalanceDay day) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final days = widget.series.days;

    final byLabel = <String, double>{};
    for (final e in day.items) {
      final t = e.transaction;
      if (!t.isExpense || !isSpendingMovement(t)) continue;
      final label = t.tag.isEmpty
          ? l10n.txKategoriSec
          : widget.categoryLabels[t.tag] ?? context.translateSystemTag(t.tag);
      byLabel[label] = (byLabel[label] ?? 0) + t.amount;
    }
    final ranked = byLabel.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = ranked.fold<double>(0, (s, e) => s + e.value);

    // Tek renk, AÇIKLIK basamakları: renk körlüğünde de sıra okunur ve
    // çubuk kategoriye "renk" uydurmaz (kategorilerin rengi yok).
    const alphas = [1.0, 0.66, 0.42, 0.24];
    final segments = <(double, double)>[];
    for (var i = 0; i < ranked.length; i++) {
      if (i < alphas.length - 1) {
        segments.add((ranked[i].value, alphas[i]));
      } else {
        final rest = ranked.skip(i).fold<double>(0, (s, e) => s + e.value);
        segments.add((rest, alphas.last));
        break;
      }
    }

    final String legend;
    if (ranked.isNotEmpty) {
      legend = ranked
          .take(3)
          .map((e) =>
              '${e.key} ${l10n.percentValue((e.value / total * 100).round().toString())}')
          .join(' · ');
    } else {
      legend = day.isFuture ? l10n.blLegendPlanned : l10n.blLegendNone;
    }

    return Row(
      children: [
        IconButton.outlined(
          key: const ValueKey('bl-prev'),
          tooltip: l10n.blPrevDay,
          onPressed: _selected > 0 ? () => _select(_selected - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: SizedBox(
                  height: 10,
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Row(
                      // Dilimlerin ÇOCUĞU yok: stretch olmadan yükseklikleri 0
                      // kalıyor, çubuk boş görünüyordu (görüntüde).
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < segments.length; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Expanded(
                            flex: (segments[i].$1 * 100)
                                .round()
                                .clamp(1, 1 << 30),
                            child: ColoredBox(
                              color: scheme.primary
                                  .withValues(alpha: segments[i].$2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                legend,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          key: const ValueKey('bl-next'),
          tooltip: l10n.blNextDay,
          onPressed:
              _selected < days.length - 1 ? () => _select(_selected + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Fişin çıktığı yarık: fiş onun ALTINDAN kayarak basılır.
class _ReceiptSlot extends StatelessWidget {
  final Widget child;

  const _ReceiptSlot({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Color.lerp(scheme.inverseSurface, Colors.black, 0.35),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        // Yarığın altından çıkıyor görünsün diye kırpılır: kayan fiş
        // yarığın üstüne taşmaz.
        ClipRect(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: child,
          ),
        ),
      ],
    );
  }
}
