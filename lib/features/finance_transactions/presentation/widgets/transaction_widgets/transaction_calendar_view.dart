import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/services/daily_spending_summary_service.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Takvim görünümü: işlemleri ay/hafta düzeninde gösterir. Her gün hücresi
/// harcama yoğunluğuna göre ısı-haritası tonu + net tutar + işlem-sayısı
/// noktası taşır. Bir güne dokununca o günün işlemleri takvimin altında
/// listelenir (mevcut [TransactionCard] yeniden kullanılır).
///
/// **Zaman ekseni paylaşılır.** Takvim eskiden kendi ay/hafta gezinmesini
/// tutuyordu ve filtrenin tarih aralığı bu görünümde hiçbir şey yapmıyordu —
/// kullanıcı "Bu Hafta" seçip Uygula'ya bastığında ekran değişmiyordu. Artık:
/// - ay/hafta değiştirmek (ok yerine SAYFA kaydırma) dönemi [onRangeChanged]
///   ile YAZAR, böylece listeye geçince aynı dönem görünür;
/// - dışarıdan gelen dönem takvimi oraya ODAKLAR ve dönem dışındaki günler
///   soluklaşır.
///
/// Dönemin ileri/geri okları ve etiketi üst çubuktadır ([TransactionTopBar]);
/// burada tekrarlanmaz.
///
/// [transactions]: cüzdanın TAM geçmişi, mod/kategori/tutar/arama filtreleri
/// uygulanmış — dönem penceresi UYGULANMAMIŞ. Kullanıcı dönem dışına da
/// gezinebilmeli.
class TransactionCalendarView extends StatefulWidget {
  final List<TransactionWithBalance> transactions;
  final Map<String, IconData> categoryIcons;

  /// `tag` → görünen ad (bkz. `buildCategoryLabelMap`).
  final Map<String, String> categoryLabels;

  /// Etkin dönem — üst çubuk ve liste görünümüyle ortak.
  final DateTimeRange range;

  /// Takvimde gezinildiğinde yeni dönem.
  final ValueChanged<DateTimeRange> onRangeChanged;

  const TransactionCalendarView({
    super.key,
    required this.transactions,
    required this.range,
    required this.onRangeChanged,
    this.categoryIcons = const {},
    this.categoryLabels = const {},
  });

  @override
  State<TransactionCalendarView> createState() =>
      _TransactionCalendarViewState();
}

class _TransactionCalendarViewState extends State<TransactionCalendarView> {
  static const _service = DailySpendingSummaryService();

  CalendarFormat _format = CalendarFormat.month;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;

  /// Gün → gelir/gider/sayı özeti (ısı-haritası + rozetler için).
  Map<DateTime, DaySummary> _summaries = {};

  /// Gün → o günün işlemleri (alt panel kartları için).
  Map<DateTime, List<TransactionWithBalance>> _byDay = {};

  @override
  void initState() {
    super.initState();
    _format = periodKindOf(widget.range) == PeriodKind.week
        ? CalendarFormat.week
        : CalendarFormat.month;
    _focusedDay = focusDayFor(widget.range);
    _selectedDay = _focusedDay;
    _rebuildIndexes();
  }

  @override
  void didUpdateWidget(covariant TransactionCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // İşlem listesi her build'de YENİ bir List örneği olarak geliyor; kimlik
    // karşılaştırması her seferinde indeksleri baştan kurardı. İçeriğe bak.
    if (!_sameLedger(oldWidget.transactions, widget.transactions)) {
      _rebuildIndexes();
    }

    if (widget.range != oldWidget.range) {
      // Sınırlar dönemi de kapsar (bkz. _recomputeBounds); yeniden
      // hesaplanmazsa veri aralığının dışına atlayan bir dönem
      // ("geçen yıl") _clamp tarafından geri çekilir ve takvim yanlış aya
      // odaklanır.
      setState(_recomputeBounds);
      _syncToRange();
    }
  }

  /// Dönem dışarıdan değişti: odağı oraya taşı. Aynı dönem içinde kalan bir
  /// değişimde (takvimin kendi yazdığı aralık geri döndüğünde) odağa DOKUNMA,
  /// yoksa sayfa animasyonu ortasında geri zıplar.
  void _syncToRange() {
    final target = focusDayFor(widget.range);
    if (_inFocusedPeriod(target)) return;
    setState(() {
      _focusedDay = _clamp(target);
      if (!_inFocusedPeriod(_selectedDay)) _selectedDay = _focusedDay;
    });
  }

  static bool _sameLedger(
    List<TransactionWithBalance> a,
    List<TransactionWithBalance> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].transaction != b[i].transaction) return false;
    }
    return true;
  }

  /// İşlem listesi değiştiğinde özet + gün indekslerini yeniden kur.
  void _rebuildIndexes() {
    _summaries = _service.buildDailySummaries(
        widget.transactions.map((e) => e.transaction).toList());

    final byDay = <DateTime, List<TransactionWithBalance>>{};
    for (final item in widget.transactions) {
      final key = dayOf(item.transaction.date);
      byDay.putIfAbsent(key, () => []).add(item);
    }
    _byDay = byDay;

    _recomputeBounds();
  }

  /// Takvimin gezinebileceği en erken/en geç ay.
  void _recomputeBounds() {
    final todayDay = dayOf(DateTime.now());
    DateTime earliest = todayDay;
    for (final item in widget.transactions) {
      final day = dayOf(item.transaction.date);
      if (day.isBefore(earliest)) earliest = day;
    }
    // Dönem geçmişe kaydırıldıysa takvim oraya gidebilmeli; sınır yalnız
    // veriye bakarsa "Geçen yıl" seçen kullanıcı o aya ulaşamıyordu.
    final rangeStart = dayOf(widget.range.start);
    if (rangeStart.isBefore(earliest)) earliest = rangeStart;

    _firstDay = DateTime(earliest.year, earliest.month, 1);
    if (_firstDay.isAfter(todayDay)) {
      _firstDay = DateTime(todayDay.year - 1, todayDay.month, 1);
    }
    final rangeEnd = dayOf(widget.range.end);
    final horizon = DateTime(todayDay.year + 1, todayDay.month + 1, 0);
    _lastDay = rangeEnd.isAfter(horizon)
        ? DateTime(rangeEnd.year, rangeEnd.month + 1, 0)
        : horizon;

    _focusedDay = _clamp(_focusedDay);
    _selectedDay = _clamp(_selectedDay);
  }

  DateTime _clamp(DateTime d) {
    if (d.isBefore(_firstDay)) return _firstDay;
    if (d.isAfter(_lastDay)) return _lastDay;
    return d;
  }

  bool _inFocusedPeriod(DateTime day) {
    if (_format == CalendarFormat.month) {
      return day.year == _focusedDay.year && day.month == _focusedDay.month;
    }
    return isDayInRange(day, weekRangeOf(_focusedDay));
  }

  /// Görünen ızgaradaki (ay/hafta) en yüksek günlük gider — ısı-haritası
  /// normalizasyonu için. Böyle olunca her dönemin kendi içi okunur kalır.
  double _visibleMaxExpense() {
    double maxE = 0;
    for (final e in _summaries.entries) {
      if (_inFocusedPeriod(e.key) && e.value.expense > maxE) {
        maxE = e.value.expense;
      }
    }
    return maxE;
  }

  /// Özet satırı ETKİN DÖNEMİN toplamıdır (görünen ızgaranın değil): üst
  /// çubuktaki dönem etiketiyle ve liste görünümünün özet kartıyla aynı
  /// rakamı söylemeli.
  DaySummary _periodTotals() {
    double inc = 0, exp = 0;
    int cnt = 0;
    for (final e in _summaries.entries) {
      if (isDayInRange(e.key, widget.range)) {
        inc += e.value.income;
        exp += e.value.expense;
        cnt += e.value.count;
      }
    }
    return DaySummary(income: inc, expense: exp, count: cnt);
  }

  /// Takvimde gezinme dönemi YAZAR.
  void _emitPeriodFor(DateTime focused) {
    widget.onRangeChanged(
      _format == CalendarFormat.month
          ? monthRangeOf(focused)
          : weekRangeOf(focused),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selKey = dayOf(_selectedDay);
    final dayItems = _byDay[selKey] ?? const <TransactionWithBalance>[];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _buildCalendarBlock(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
            child: _buildDayPanelHeader(selKey),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
          sliver: dayItems.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyDay())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TransactionCard(
                        item: dayItems[index],
                        categoryIcon: widget
                            .categoryIcons[dayItems[index].transaction.tag],
                        categoryLabel: widget
                            .categoryLabels[dayItems[index].transaction.tag],
                        enableSwipeActions: true,
                      ),
                    ),
                    childCount: dayItems.length,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCalendarBlock() {
    final scheme = Theme.of(context).colorScheme;
    final maxExpense = _visibleMaxExpense();
    final period = _periodTotals();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryRow(period)),
              const SizedBox(width: 8),
              _buildFormatToggle(),
            ],
          ),
          const SizedBox(height: 6),
          TableCalendar<TransactionWithBalance>(
            firstDay: _firstDay,
            lastDay: _lastDay,
            focusedDay: _focusedDay,
            calendarFormat: _format,
            locale: Intl.defaultLocale,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerVisible: false,
            rowHeight: 58,
            daysOfWeekHeight: 22,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Ay',
              CalendarFormat.week: 'Hafta',
            },
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              setState(() {
                _focusedDay = focused;
                // Alt panel eski ayda kalmasın: seçili gün artık görünmeyen
                // bir aya aitse dönemin doğal başlangıcına kayar.
                if (!_inFocusedPeriod(_selectedDay)) {
                  final today = dayOf(DateTime.now());
                  _selectedDay = _inFocusedPeriod(today) ? today : focused;
                }
              });
              _emitPeriodFor(focused);
            },
            calendarStyle: const CalendarStyle(outsideDaysVisible: true),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              weekendStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppGradients.debt.withValues(alpha: 0.7),
              ),
            ),
            calendarBuilders: CalendarBuilders<TransactionWithBalance>(
              defaultBuilder: (c, day, foc) =>
                  _buildCell(day, _CellKind.normal, maxExpense),
              todayBuilder: (c, day, foc) =>
                  _buildCell(day, _CellKind.today, maxExpense),
              selectedBuilder: (c, day, foc) =>
                  _buildCell(day, _CellKind.selected, maxExpense),
              outsideBuilder: (c, day, foc) =>
                  _buildCell(day, _CellKind.outside, maxExpense),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(DateTime day, _CellKind kind, double maxExpense) {
    final scheme = Theme.of(context).colorScheme;
    final key = dayOf(day);
    final summary = _summaries[key];

    final isOutside = kind == _CellKind.outside;
    final isToday = kind == _CellKind.today;
    final isSelected = kind == _CellKind.selected;
    // Dönem dışındaki günler görünür ama SOLUK: hangi günlerin özet
    // rakamlarına girdiği hücreye bakınca anlaşılmalı.
    final isOutOfPeriod = !isDayInRange(day, widget.range);
    final dimmed = isOutside || isOutOfPeriod;

    final expense = summary?.expense ?? 0;
    double tintAlpha = 0;
    if (!dimmed && expense > 0) {
      final intensity =
          maxExpense <= 0 ? 0.0 : (expense / maxExpense).clamp(0.0, 1.0);
      tintAlpha = 0.10 + 0.32 * intensity;
    }

    final Color bg = isSelected
        ? AppGradients.transactions.withValues(alpha: 0.16)
        : (tintAlpha > 0
            ? AppGradients.debt.withValues(alpha: tintAlpha)
            : Colors.transparent);

    final Border? border = isSelected
        ? Border.all(color: AppGradients.transactions, width: 1.5)
        : isToday
            ? Border.all(
                color: AppGradients.transactions.withValues(alpha: 0.6),
                width: 1.2)
            : null;

    final Color dayColor = dimmed
        ? scheme.onSurfaceVariant.withValues(alpha: 0.35)
        : (isSelected || isToday)
            ? AppGradients.transactions
            : scheme.onSurface;

    final hasData = summary != null && !summary.isEmpty;

    return Opacity(
      opacity: isOutOfPeriod && !isOutside ? 0.45 : 1,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (isToday || isSelected)
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: dayColor,
                  ),
                ),
                if (hasData && !isOutside) ...[
                  const SizedBox(height: 1),
                  Text(
                    formatMoneyCompact(summary.net, symbol: false),
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: summary.net >= 0
                          ? AppGradients.savings
                          : AppGradients.debt,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _countDots(summary.count),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _countDots(int count) {
    final n = count.clamp(1, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        n,
        (_) => Container(
          width: 3.5,
          height: 3.5,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: AppGradients.transactions.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDayPanelHeader(DateTime selKey) {
    final scheme = Theme.of(context).colorScheme;
    final summary = _summaries[selKey];

    return Row(
      children: [
        Expanded(
          child: Text(
            AppFormatters.dateLong.format(selKey),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (summary != null && !summary.isEmpty) _buildSummaryRow(summary),
      ],
    );
  }

  /// [DetailedListView]'deki günlük özet satırıyla aynı dil: ↑gelir ↓gider +
  /// net rozeti. Tutarlar aktif cüzdan birimiyle (liste ile birebir).
  Widget _buildSummaryRow(DaySummary s) {
    final scheme = Theme.of(context).colorScheme;
    String money(double v) =>
        formatMoney(v, currency: context.activeWalletCurrency);
    final netColor = s.net >= 0 ? AppGradients.savings : AppGradients.debt;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.income > 0) ...[
          Icon(Icons.arrow_upward_rounded,
              size: 11, color: AppGradients.savings.withValues(alpha: 0.85)),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              money(s.income),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (s.expense > 0) ...[
          Icon(Icons.arrow_downward_rounded,
              size: 11, color: AppGradients.debt.withValues(alpha: 0.85)),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              money(s.expense),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: netColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: netColor.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Text(
            context.l10n.netNetAppformattersCurrency(
                '${s.net >= 0 ? "+" : ""}${money(s.net)}'),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: netColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDay() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded,
              size: 40, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            context.l10n.buGuneAitIslemYok,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatToggle() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatChip(context.l10n.takvimAy, CalendarFormat.month),
          _formatChip(context.l10n.takvimHafta, CalendarFormat.week),
        ],
      ),
    );
  }

  Widget _formatChip(String label, CalendarFormat format) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _format == format;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: () {
          if (selected) return;
          setState(() => _format = format);
          // Biçim değişimi dönemi de değiştirir: haftaya geçince "bu hafta",
          // aya geçince "bu ay" filtreye yazılır.
          _emitPeriodFor(_focusedDay);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppGradients.transactions : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CellKind { normal, today, selected, outside }
