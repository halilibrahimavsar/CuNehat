import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/date_math.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/services/daily_spending_summary_service.dart';
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
/// [transactions]: cüzdanın TAM geçmişi, mod/kategori/fiyat filtreleri
/// uygulanmış — tarih penceresi UYGULANMAMIŞ. Takvim tarih eksenini kendi
/// navigasyonuyla yönetir.
class TransactionCalendarView extends StatefulWidget {
  final List<TransactionWithBalance> transactions;
  final Map<String, IconData> categoryIcons;

  /// `tag` → görünen ad (bkz. `buildCategoryLabelMap`).
  final Map<String, String> categoryLabels;

  const TransactionCalendarView({
    super.key,
    required this.transactions,
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
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
    _rebuildIndexes();
  }

  @override
  void didUpdateWidget(covariant TransactionCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions) {
      _rebuildIndexes();
    }
  }

  /// İşlem listesi değiştiğinde özet + gün indekslerini ve takvim sınırlarını
  /// yeniden kur.
  void _rebuildIndexes() {
    _summaries = _service.buildDailySummaries(
        widget.transactions.map((e) => e.transaction).toList());

    final byDay = <DateTime, List<TransactionWithBalance>>{};
    for (final item in widget.transactions) {
      final d = item.transaction.date;
      final key = DateTime(d.year, d.month, d.day);
      byDay.putIfAbsent(key, () => []).add(item);
    }
    _byDay = byDay;

    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    DateTime earliest = todayDay;
    for (final item in widget.transactions) {
      final d = item.transaction.date;
      final day = DateTime(d.year, d.month, d.day);
      if (day.isBefore(earliest)) earliest = day;
    }
    _firstDay = DateTime(earliest.year, earliest.month, 1);
    if (_firstDay.isAfter(todayDay)) {
      _firstDay = DateTime(todayDay.year - 1, todayDay.month, 1);
    }
    _lastDay = DateTime(todayDay.year + 1, todayDay.month + 1, 0);

    _focusedDay = _clamp(_focusedDay);
    _selectedDay = _clamp(_selectedDay);
  }

  DateTime _clamp(DateTime d) {
    if (d.isBefore(_firstDay)) return _firstDay;
    if (d.isAfter(_lastDay)) return _lastDay;
    return d;
  }

  DateTime _weekStart(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    return date.subtract(Duration(days: (date.weekday - DateTime.monday) % 7));
  }

  bool _inFocusedPeriod(DateTime day) {
    if (_format == CalendarFormat.month) {
      return day.year == _focusedDay.year && day.month == _focusedDay.month;
    }
    final start = _weekStart(_focusedDay);
    final end = start.add(const Duration(days: 6));
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Görünen dönemdeki (ay/hafta) en yüksek günlük gider — ısı-haritası
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

  DaySummary _periodTotals() {
    double inc = 0, exp = 0;
    int cnt = 0;
    for (final e in _summaries.entries) {
      if (_inFocusedPeriod(e.key)) {
        inc += e.value.income;
        exp += e.value.expense;
        cnt += e.value.count;
      }
    }
    return DaySummary(income: inc, expense: exp, count: cnt);
  }

  void _goPrev() {
    setState(() {
      final next = _format == CalendarFormat.month
          ? addMonthsClamped(_focusedDay, -1)
          : _focusedDay.subtract(const Duration(days: 7));
      _focusedDay = _clamp(next);
    });
  }

  void _goNext() {
    setState(() {
      final next = _format == CalendarFormat.month
          ? addMonthsClamped(_focusedDay, 1)
          : _focusedDay.add(const Duration(days: 7));
      _focusedDay = _clamp(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selKey =
        DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
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
                        context: context,
                        item: dayItems[index],
                        isListView: true,
                        categoryIcon: widget
                            .categoryIcons[dayItems[index].transaction.tag],
                        categoryLabel: widget
                            .categoryLabels[dayItems[index].transaction.tag],
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
          // Başlık: ‹  Ay Yıl  ›  +  Ay/Hafta toggle
          Row(
            children: [
              _navButton(Icons.chevron_left_rounded, _goPrev),
              Expanded(
                child: Text(
                  _periodTitle(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              _navButton(Icons.chevron_right_rounded, _goNext),
              const SizedBox(width: 4),
              _buildFormatToggle(),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildSummaryRow(period),
          ),
          const SizedBox(height: 4),
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
            onPageChanged: (focused) => setState(() => _focusedDay = focused),
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
    final key = DateTime(day.year, day.month, day.day);
    final summary = _summaries[key];

    final isOutside = kind == _CellKind.outside;
    final isToday = kind == _CellKind.today;
    final isSelected = kind == _CellKind.selected;

    final expense = summary?.expense ?? 0;
    double tintAlpha = 0;
    if (!isOutside && expense > 0) {
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

    final Color dayColor = isOutside
        ? scheme.onSurfaceVariant.withValues(alpha: 0.35)
        : (isSelected || isToday)
            ? AppGradients.transactions
            : scheme.onSurface;

    final hasData = !isOutside && summary != null && !summary.isEmpty;

    return Container(
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
              if (hasData) ...[
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
    final money = AppFormatters.currencyFor(context.activeWalletCurrency);
    final netColor = s.net >= 0 ? AppGradients.savings : AppGradients.debt;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.income > 0) ...[
          Icon(Icons.arrow_upward_rounded,
              size: 11, color: AppGradients.savings.withValues(alpha: 0.85)),
          const SizedBox(width: 2),
          Text(
            money.format(s.income),
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (s.expense > 0) ...[
          Icon(Icons.arrow_downward_rounded,
              size: 11, color: AppGradients.debt.withValues(alpha: 0.85)),
          const SizedBox(width: 2),
          Text(
            money.format(s.expense),
            style: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
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
                '${s.net >= 0 ? "+" : ""}${money.format(s.net)}'),
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
    return GestureDetector(
      onTap: () => setState(() => _format = format),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 24, color: scheme.onSurfaceVariant),
      ),
    );
  }

  String _periodTitle() {
    final locale = Intl.defaultLocale;
    if (_format == CalendarFormat.month) {
      return DateFormat.yMMMM(locale).format(_focusedDay);
    }
    final start = _weekStart(_focusedDay);
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month) {
      return '${start.day} – ${end.day} ${DateFormat.MMMM(locale).format(start)}';
    }
    return '${start.day} ${DateFormat.MMM(locale).format(start)} – '
        '${end.day} ${DateFormat.MMM(locale).format(end)}';
  }
}

enum _CellKind { normal, today, selected, outside }
