import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

// Timeline yerleşim sabitleri (önceki magic offset'ler yerine).
const double _kNodeSize = 32;
const double _kLineLeft = 15;
const double _kItemIndent = 36;

class DetailedListView extends StatefulWidget {
  final List<TransactionWithBalance> transactions;
  final FinanceMode mode;
  final Map<String, IconData> categoryIcons;

  /// `tag` → görünen ad (bkz. `buildCategoryLabelMap`).
  final Map<String, String> categoryLabels;
  final bool showDayEndBalance;

  /// [categoryIcons] ve [categoryLabels] TEK bir indeksin iki yarısıdır ve
  /// birlikte yüklenir; ikisi de zorunludur. Varsayılanlı olduklarında
  /// ikonları geçip adları unutmak sessizce derleniyordu: rapor detay
  /// sheet'inde başlık yeni adı, altındaki kartlar eski adı gösteriyordu.
  const DetailedListView({
    super.key,
    required this.transactions,
    required this.categoryIcons,
    required this.categoryLabels,
    this.mode = FinanceMode.compare,
    this.showDayEndBalance = true,
  });

  @override
  State<DetailedListView> createState() => _DetailedListViewState();
}

class _DetailedListViewState extends State<DetailedListView> {
  final Map<DateTime, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    final filtered = widget.mode == FinanceMode.compare
        ? widget.transactions
        : widget.transactions
            .where((item) => widget.mode == FinanceMode.income
                ? item.transaction.isIncome
                : item.transaction.isExpense)
            .toList();

    // Tarihe göre grupla (gün bazında).
    final grouped = <DateTime, List<TransactionWithBalance>>{};
    for (final item in filtered) {
      final d = item.transaction.date;
      final date = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }
    for (final date in grouped.keys) {
      _expandedStates.putIfAbsent(date, () => true);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // Tipli düz liste (lazy render için).
    final rows = <_Row>[];
    for (var i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final items = grouped[date]!;
      final isExpanded = _expandedStates[date] ?? true;
      final isLastDate = i == sortedDates.length - 1;

      rows.add(_HeaderRow(date, items, isExpanded, isLastDate));

      if (isExpanded) {
        // Gün sonu bakiyesi = o günün en yeni işleminden sonraki bakiye.
        final dayEndBalance = items.first.balanceAfter;
        for (var j = 0; j < items.length; j++) {
          final isLastItem = j == items.length - 1;
          rows.add(_ItemRow(
            item: items[j],
            isLastDate: isLastDate,
            isLastItem: isLastItem,
            dayEndBalance:
                (isLastItem && widget.showDayEndBalance) ? dayEndBalance : null,
          ));
        }
      } else {
        rows.add(_SpacerRow(isLastDate));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return _EntranceAnimation(
          index: index,
          child: _buildRow(context, row),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, _Row row) {
    final accent = widget.mode.primaryColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dikey timeline çizgisi.
        Positioned(
          left: _kLineLeft,
          top: row is _HeaderRow ? 40 : 0,
          bottom: 0,
          child: Container(
            width: 1.5,
            color: row.isLastDate
                ? Colors.transparent
                : accent.withValues(alpha: 0.15),
          ),
        ),

        if (row is _HeaderRow)
          _buildDateHeaderRow(context, row.date, row.items, row.isExpanded)
        else if (row is _ItemRow)
          Padding(
            padding: EdgeInsets.only(
              left: _kItemIndent,
              top: 4,
              bottom: row.isLastItem ? 16 : 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TransactionCard(
                  context: context,
                  item: row.item,
                  isListView: true,
                  categoryIcon: widget.categoryIcons[row.item.transaction.tag],
                  categoryLabel:
                      widget.categoryLabels[row.item.transaction.tag],
                ),
                if (row.dayEndBalance != null)
                  _buildDayEndBalance(context, row.dayEndBalance!),
              ],
            ),
          )
        else if (row is _SpacerRow)
          const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDayEndBalance(BuildContext context, double balance) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.gunSonu,
            style: TextStyle(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          MoneyText(
            amount: balance,
            currency: context.activeWalletCurrency,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: balance >= 0 ? scheme.onSurfaceVariant : AppGradients.debt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeaderRow(
    BuildContext context,
    DateTime date,
    List<TransactionWithBalance> items,
    bool isExpanded,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = widget.mode.primaryColor;

    final dailyIncome = items
        .where((e) => e.transaction.isIncome)
        .fold(0.0, (sum, e) => sum + e.transaction.amount);
    final dailyExpense = items
        .where((e) => e.transaction.isExpense)
        .fold(0.0, (sum, e) => sum + e.transaction.amount);
    final dailyNet = dailyIncome - dailyExpense;

    return GestureDetector(
      onTap: () => setState(() => _expandedStates[date] = !isExpanded),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: _kNodeSize,
              height: _kNodeSize,
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.8),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppFormatters.dateLong.format(date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildDailySummaryRow(
                      context, dailyIncome, dailyExpense, dailyNet),
                ],
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryRow(
    BuildContext context,
    double income,
    double expense,
    double net,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String money(double v) =>
        formatMoney(v, currency: context.activeWalletCurrency);
    final netColor = net >= 0 ? AppGradients.savings : AppGradients.debt;

    return Row(
      children: [
        if (income > 0) ...[
          Icon(Icons.arrow_upward_rounded,
              size: 11, color: AppGradients.savings.withValues(alpha: 0.8)),
          const SizedBox(width: 2),
          Text(
            money(income),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (expense > 0) ...[
          Icon(Icons.arrow_downward_rounded,
              size: 11, color: AppGradients.debt.withValues(alpha: 0.8)),
          const SizedBox(width: 2),
          Text(
            money(expense),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
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
                '${net >= 0 ? "+" : ""}${money(net)}'),
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
}

// ============================================================ Tipli satır modeli

sealed class _Row {
  bool get isLastDate;
}

class _HeaderRow extends _Row {
  final DateTime date;
  final List<TransactionWithBalance> items;
  final bool isExpanded;
  @override
  final bool isLastDate;
  _HeaderRow(this.date, this.items, this.isExpanded, this.isLastDate);
}

class _ItemRow extends _Row {
  final TransactionWithBalance item;
  @override
  final bool isLastDate;
  final bool isLastItem;
  final double? dayEndBalance;
  _ItemRow({
    required this.item,
    required this.isLastDate,
    required this.isLastItem,
    this.dayEndBalance,
  });
}

class _SpacerRow extends _Row {
  @override
  final bool isLastDate;
  _SpacerRow(this.isLastDate);
}

// ============================================================ Giriş animasyonu

/// Satır ilk göründüğünde hafif fade + yukarı kayma. ListView eleman geri
/// dönüşümü sayesinde scroll'da tekrar oynamaz (State örnek başına bir kez).
class _EntranceAnimation extends StatefulWidget {
  final int index;
  final Widget child;

  const _EntranceAnimation({required this.index, required this.child});

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    // İlk ekranda kademeli; sonraki satırlar gecikmesiz.
    final delayMs = (widget.index.clamp(0, 8)) * 40;
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
