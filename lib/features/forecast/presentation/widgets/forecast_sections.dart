import 'dart:math' as math;

import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/budgets/presentation/widgets/temp_budget_widgets.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_path_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ------------------------------------------------------------------ dönem

/// Dönem sonu: beklenen gider (aralıkla), gelir, net ve giderin üç parçası —
/// gerçekleşen · planlı · tahmini. Parçalar AYRI çizilir: kullanıcı hangi
/// kısmın kesin, hangisinin tahmin olduğunu tek bakışta görür.
class ForecastPeriodCard extends StatelessWidget {
  final PeriodOutlook period;
  final MoneyWriter money;
  final bool hasPace;

  const ForecastPeriodCard({
    super.key,
    required this.period,
    required this.money,
    required this.hasPace,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = period;
    final net = p.expectedNet;
    final showRange =
        hasPace && (p.expectedExpenseHigh - p.expectedExpenseLow) > 0.5;

    return AppCard(
      key: const ValueKey('forecast-period-card'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppFormatters.dayMonth.format(p.start)} – '
            '${AppFormatters.dayMonth.format(p.end)}',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(l10n.forecastExpectedExpense,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '~${money(p.expectedExpense)}',
              key: const ValueKey('forecast-period-expense'),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: AppType.strong),
            ),
          ),
          if (showRange)
            Text(
              l10n.forecastRangeLabel(
                  money(p.expectedExpenseLow), money(p.expectedExpenseHigh)),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          const SizedBox(height: 14),
          _StackedBar(
            parts: [
              (p.realizedExpense, MoneyColors.expense),
              (p.knownExpense, MoneyColors.expense.withValues(alpha: 0.55)),
              (p.paceExpense, MoneyColors.expense.withValues(alpha: 0.22)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _Part(
                  color: MoneyColors.expense,
                  label: l10n.forecastPartRealized,
                  value: money(p.realizedExpense)),
              _Part(
                  color: MoneyColors.expense.withValues(alpha: 0.55),
                  label: l10n.forecastPartKnown,
                  value: money(p.knownExpense)),
              if (hasPace)
                _Part(
                    color: MoneyColors.expense.withValues(alpha: 0.22),
                    label: l10n.forecastPartPace,
                    value: money(p.paceExpense)),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: l10n.forecastExpectedIncome,
                  value: money(p.expectedIncome),
                  color: MoneyColors.incomeText(theme.brightness),
                ),
              ),
              Expanded(
                child: _Figure(
                  label: l10n.forecastExpectedNet,
                  value: money.withSign(net),
                  color: MoneyColors.signedText(net, theme.brightness),
                ),
              ),
            ],
          ),
          if (p.previousExpense != null && p.previousExpense! > 0) ...[
            const SizedBox(height: 10),
            Text(
              l10n.forecastPreviousPeriod(money(p.previousExpense!)),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _StackedBar extends StatelessWidget {
  final List<(double, Color)> parts;

  const _StackedBar({required this.parts});

  @override
  Widget build(BuildContext context) {
    final total = parts.fold(0.0, (s, p) => s + math.max(0, p.$1));
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: AppRadius.controlAll,
      child: SizedBox(
        height: 10,
        child: total <= 0
            ? ColoredBox(color: scheme.onSurface.withValues(alpha: 0.08))
            : Row(
                children: [
                  for (final (value, color) in parts)
                    if (value > 0)
                      Expanded(
                        flex: math.max(1, (value / total * 1000).round()),
                        child: ColoredBox(color: color),
                      ),
                ],
              ),
      ),
    );
  }
}

class _Part extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _Part({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text('$label $value', style: theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Figure(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: color, fontWeight: AppType.strong)),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ bütçe

/// Bütçe gidişatı: aylık ve tek seferlik bütçeler, her biri için gerçekleşen
/// (dolu) + beklenen (açık ton) + limit çizgisi ve tek cümlelik yorum.
class ForecastBudgetsCard extends StatelessWidget {
  final List<BudgetOutlook> budgets;
  final MoneyWriter money;
  final Map<String, String> categoryLabels;
  final DateTime today;

  const ForecastBudgetsCard({
    super.key,
    required this.budgets,
    required this.money,
    required this.today,
    this.categoryLabels = const {},
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('forecast-budgets-card'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          for (var i = 0; i < budgets.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            BudgetOutlookRow(
              outlook: budgets[i],
              money: money,
              today: today,
              categoryLabels: categoryLabels,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Tek bütçenin gidişat satırı (Gelecek ve Rapor ortak).
class BudgetOutlookRow extends StatelessWidget {
  final BudgetOutlook outlook;
  final MoneyWriter money;
  final DateTime today;
  final Map<String, String> categoryLabels;

  const BudgetOutlookRow({
    super.key,
    required this.outlook,
    required this.money,
    required this.today,
    this.categoryLabels = const {},
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final o = outlook;
    final temp = o.temp;
    final name = temp?.name ??
        context.categoryLabelForTag(o.categoryId ?? o.id,
            labels: categoryLabels);

    final (Color color, String status) = switch (o.status) {
      BudgetOutlookStatus.over => (
          MoneyColors.bad,
          moneyGreater(o.spent, o.limit)
              ? l10n.forecastBudgetOver
              : l10n.forecastBudgetFull
        ),
      BudgetOutlookStatus.atRisk => (
          MoneyColors.bad,
          o.fillDate == null
              ? l10n.forecastBudgetOver
              : l10n.forecastBudgetFillsOn(
                  forecastDayLabel(l10n, o.fillDate!, today))
        ),
      BudgetOutlookStatus.onTrack => (
          MoneyColors.good,
          l10n.forecastBudgetFits
        ),
      BudgetOutlookStatus.upcoming => (
          scheme.primary,
          temp == null
              ? ''
              : l10n.tempBudgetStartsIn(temp.daysUntilStartOn(today))
        ),
      BudgetOutlookStatus.finished => (
          moneyGreater(o.spent, o.limit) ? MoneyColors.bad : MoneyColors.good,
          temp == null
              ? ''
              : tempBudgetResultText(l10n, temp.copyWith(spentAmount: o.spent),
                  currency: money.currency)
        ),
    };

    final String? hint = switch (o.status) {
      BudgetOutlookStatus.upcoming =>
        o.paceRemaining > 0 || o.knownRemaining > 0
            ? l10n.forecastBudgetUpcoming(money(o.expectedEnd))
            : null,
      BudgetOutlookStatus.finished || BudgetOutlookStatus.over => null,
      _ => o.requiredDaily == null
          ? null
          : l10n.forecastBudgetRequiredDaily(money(o.requiredDaily!)),
    };

    final scale = math.max(o.limit, o.expectedEnd);
    double frac(double v) => scale <= 0 ? 0 : (v / scale).clamp(0.0, 1.0);

    return Padding(
      key: ValueKey('forecast-budget-${o.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (temp != null) ...[
                Icon(Icons.event_note_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: AppType.medium),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  status,
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: color, fontWeight: AppType.strong),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final limitX = frac(o.limit) * w;
              return SizedBox(
                height: 12,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.07),
                          borderRadius: AppRadius.controlAll,
                        ),
                      ),
                    ),
                    if (o.status != BudgetOutlookStatus.finished)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: frac(o.expectedEnd) * w,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.28),
                            borderRadius: AppRadius.controlAll,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: frac(o.spent) * w,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: AppRadius.controlAll,
                        ),
                      ),
                    ),
                    // Limit çizgisi: beklenen limiti aşınca çubuk limitin
                    // ötesine uzar; sınırın nerede olduğu görünmeli.
                    if (o.expectedEnd > o.limit || o.spent > o.limit)
                      Positioned(
                        left: math.max(0, limitX - 1),
                        top: -2,
                        bottom: -2,
                        width: 2,
                        child: ColoredBox(color: scheme.onSurface),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  o.status == BudgetOutlookStatus.finished
                      ? l10n.tempBudgetSpentOfLimit(
                          money(o.spent), money(o.limit))
                      : l10n.forecastBudgetExpectedEnd(
                          money(o.expectedEnd), money(o.limit)),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          if (hint != null)
            Text(hint,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  static bool moneyGreater(double a, double b) => a - b > 0.005;
}

// ------------------------------------------------------------- yaklaşanlar

/// Haftalara gruplu yaklaşan ödemeler/gelirler; en üstte gecikmişler.
class ForecastUpcomingCard extends StatefulWidget {
  final List<ForecastEvent> events;
  final List<ForecastEvent> overdue;
  final MoneyWriter money;
  final DateTime today;
  final int horizonDays;

  /// Tüm cüzdanlar görünümünde olay satırı cüzdan adını da yazar.
  final Map<String, String> walletNames;

  const ForecastUpcomingCard({
    super.key,
    required this.events,
    required this.overdue,
    required this.money,
    required this.today,
    required this.horizonDays,
    this.walletNames = const {},
  });

  @override
  State<ForecastUpcomingCard> createState() => _ForecastUpcomingCardState();
}

class _ForecastUpcomingCardState extends State<ForecastUpcomingCard> {
  static const _collapsedCount = 12;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (widget.events.isEmpty && widget.overdue.isEmpty) {
      return AppCard(
        key: const ValueKey('forecast-upcoming-card'),
        padding: const EdgeInsets.all(20),
        child: Text(
          l10n.forecastUpcomingEmpty(widget.horizonDays),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    final t = widget.today;
    // Hafta Pazartesi başlar; "bu hafta" Pazar'a kadar.
    final endOfWeek = DateTime(t.year, t.month, t.day + (7 - t.weekday));
    final endOfNextWeek =
        DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day + 7);

    final visible = _expanded
        ? widget.events
        : widget.events.take(_collapsedCount).toList();
    final groups = <String, List<ForecastEvent>>{};
    for (final e in visible) {
      final key = !e.date.isAfter(endOfWeek)
          ? l10n.forecastThisWeek
          : (!e.date.isAfter(endOfNextWeek)
              ? l10n.forecastNextWeek
              : l10n.forecastLater);
      (groups[key] ??= <ForecastEvent>[]).add(e);
    }

    Widget header(String text, {Color? color}) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color ?? scheme.onSurfaceVariant,
              fontWeight: AppType.strong,
            ),
          ),
        );

    return AppCard(
      key: const ValueKey('forecast-upcoming-card'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.overdue.isNotEmpty) ...[
            header(l10n.forecastOverdueTitle,
                color: MoneyColors.expenseText(theme.brightness)),
            for (final e in widget.overdue) _row(context, e, overdue: true),
          ],
          for (final g in groups.entries) ...[
            header(g.key),
            for (final e in g.value) _row(context, e),
          ],
          if (widget.events.length > _collapsedCount)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded
                  ? l10n.portfoyDahaAzGoster
                  : '+${widget.events.length - _collapsedCount}'),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ForecastEvent e, {bool overdue = false}) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final income = e.isIncome;
    final title = forecastEventTitle(l10n, e);
    final wallet = widget.walletNames[e.walletId];
    final date = overdue
        ? AppFormatters.dayMonth.format(e.date)
        : forecastDayLabel(l10n, e.date, widget.today);

    return ListTile(
      key: ValueKey('forecast-event-${e.kind.name}-${e.sourceId}-'
          '${e.date.toIso8601String()}-${e.walletId}'),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: (income ? MoneyColors.good : scheme.onSurface)
            .withValues(alpha: 0.08),
        child: Icon(_iconOf(e.kind),
            size: 18,
            color: income
                ? MoneyColors.incomeText(theme.brightness)
                : scheme.onSurfaceVariant),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        wallet == null ? date : '$date · $wallet',
        style: theme.textTheme.bodySmall?.copyWith(
          color: overdue
              ? MoneyColors.expenseText(theme.brightness)
              : scheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            e.certainty == ForecastCertainty.expected
                ? '~${widget.money.withSign(e.amount)}'
                : widget.money.withSign(e.amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: AppType.strong,
              color: income
                  ? MoneyColors.incomeText(theme.brightness)
                  : scheme.onSurface,
            ),
          ),
          if (e.certainty == ForecastCertainty.expected)
            Text(
              e.kind == ForecastEventKind.receivable
                  ? l10n.forecastChipExpected
                  : l10n.forecastChipEstimated,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  static IconData _iconOf(ForecastEventKind kind) => switch (kind) {
        ForecastEventKind.recurringExpense => Icons.autorenew_rounded,
        ForecastEventKind.recurringIncome => Icons.payments_rounded,
        ForecastEventKind.scheduled => Icons.event_rounded,
        ForecastEventKind.cardPayment ||
        ForecastEventKind.cardStatementEstimate =>
          Icons.credit_card_rounded,
        ForecastEventKind.debtInstallment => Icons.account_balance_rounded,
        ForecastEventKind.receivable => Icons.call_received_rounded,
      };
}

/// Olay satırının başlığı.
String forecastEventTitle(AppLocalizations l10n, ForecastEvent e) {
  final title = switch (e.kind) {
    ForecastEventKind.cardStatementEstimate =>
      l10n.forecastEventCardStatement(e.title),
    ForecastEventKind.cardPayment => l10n.forecastEventCardPayment(e.title),
    ForecastEventKind.receivable => l10n.forecastEventReceivable(e.title),
    _ => e.title,
  };
  final no = e.installmentNo;
  final count = e.installmentCount;
  if (no != null && count != null && count > 1) {
    return l10n.forecastEventInstallment(title, no, count);
  }
  return title;
}

// ---------------------------------------------------------- kart ve hedef

class ForecastCardsCard extends StatelessWidget {
  final List<(String name, CardOutlook card)> cards;
  final MoneyWriter money;
  final DateTime today;
  final bool hasPace;

  const ForecastCardsCard({
    super.key,
    required this.cards,
    required this.money,
    required this.today,
    this.hasPace = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      key: const ValueKey('forecast-cards-card'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.credit_card_rounded,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(cards[i].$1,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: AppType.medium)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (cards[i].$2.pendingAmount > 0)
              Text(
                l10n.forecastCardPending(
                  money(cards[i].$2.pendingAmount),
                  forecastDayLabel(l10n, cards[i].$2.pendingDue, today),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cards[i].$2.pendingOverdue
                      ? MoneyColors.expenseText(theme.brightness)
                      : scheme.onSurface,
                ),
              ),
            Text(
              l10n.forecastCardEstimate(money(cards[i].$2.statementEstimate)),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: AppType.strong),
            ),
            Text(
              l10n.forecastCardClosingDue(
                AppFormatters.dayMonth.format(cards[i].$2.nextClosing),
                AppFormatters.dayMonth.format(cards[i].$2.nextDue),
              ),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              l10n.forecastCardBreakdown(
                money(cards[i].$2.spentSoFar),
                money(cards[i].$2.installmentsUntilClosing),
                money(cards[i].$2.paceUntilClosing),
              ),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class ForecastGoalsCard extends StatelessWidget {
  final List<GoalOutlook> goals;
  final MoneyWriter money;

  const ForecastGoalsCard(
      {super.key, required this.goals, required this.money});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final monthYear = DateFormat.yMMMM(Intl.defaultLocale);
    return AppCard(
      key: const ValueKey('forecast-goals-card'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < goals.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 18, color: goals[i].goal.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(goals[i].goal.name,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: AppType.medium)),
                ),
                Text(
                  '${money(goals[i].saved)} / ${money(goals[i].goal.targetAmount)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              goals[i].reached
                  ? l10n.forecastGoalReached
                  : goals[i].arrival != null
                      ? l10n.forecastGoalArrival(
                          monthYear.format(goals[i].arrival!))
                      : goals[i].monthlyContribution > 0
                          ? l10n.forecastGoalTooFar
                          : l10n.forecastGoalNoContribution,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: AppType.strong),
            ),
            if (!goals[i].reached && goals[i].monthlyContribution > 0)
              Text(
                l10n.forecastGoalMonthly(money(goals[i].monthlyContribution)),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- açıklama

/// "Nasıl hesaplandı?" — tahminin her varsayımı açıkça yazılır. Kullanıcı
/// "bu sayı nereden çıktı" diye sorabilmeli; cevapsız bir tahmin güven
/// vermez.
Future<void> showForecastExplanation(
  BuildContext context, {
  required WalletForecast forecast,
  required MoneyWriter money,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) {
      final l10n = context.l10n;
      final theme = Theme.of(context);
      final pace = forecast.pace;
      final paragraphs = <String>[
        if (pace != null)
          l10n.forecastHowPace(pace.observedDays, money(pace.dailyMean)),
        l10n.forecastHowExcluded,
        l10n.forecastHowIncome,
        l10n.forecastHowRange,
        l10n.forecastHowReceivable,
        l10n.forecastHowCard,
        l10n.forecastHowGoals,
        l10n.forecastHowLegacy,
      ];
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.forecastHowTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final p in paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(p)),
                  ],
                ),
              ),
            if (pace != null && pace.oneOffs.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(l10n.forecastHowOneOffs(pace.oneOffs.length),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: AppType.strong)),
              for (final t in pace.oneOffs)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${AppFormatters.dayMonth.format(t.date)} · ${t.title} · '
                    '${money(t.amount)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );
}
