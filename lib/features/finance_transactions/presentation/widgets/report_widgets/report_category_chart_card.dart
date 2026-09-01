import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_bar_list.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_sunburst_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReportCategoryChartCard extends StatefulWidget {
  final String title;
  final List<CategoryData> fullData;
  final List<CategoryData> pieData;
  final bool isExpense;
  final bool showBarChart;
  final ValueChanged<bool> onToggleBarChart;
  final void Function(CategoryData cat, ReportSliceMode sliceMode)
      onCategoryTap;
  final ({double progress, bool isExceeded, double limit})? Function(
      String tag, double spent) budgetProgressFor;

  /// `tag` → görünen ad. Dilim/çubuk anahtarı hep `CategoryData.name` (tag)
  /// kalır; bu harita yalnız etiket basarken kullanılır.
  final Map<String, String> categoryLabels;

  const ReportCategoryChartCard({
    super.key,
    required this.title,
    required this.fullData,
    required this.pieData,
    required this.isExpense,
    required this.showBarChart,
    required this.onToggleBarChart,
    required this.onCategoryTap,
    required this.budgetProgressFor,
    this.categoryLabels = const {},
  });

  @override
  State<ReportCategoryChartCard> createState() =>
      _ReportCategoryChartCardState();
}

class _ReportCategoryChartCardState extends State<ReportCategoryChartCard> {
  /// Çemberin iç halkasında odaklanılan ana kategori; null ise odak yok.
  int? _focusedRoot;

  /// Dilimlerden en az birinin alt kırılımı var mı? Yoksa dış halka da,
  /// onu anlatan ipucu da çizilmez.
  bool get _hasHierarchy => widget.pieData.any((c) => c.children.isNotEmpty);

  @override
  void didUpdateWidget(ReportCategoryChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dilim listesi değiştiğinde (tarih aralığı seçimi, işlem ekleme/silme)
    // eski indeks artık başka bir kategoriyi işaret eder; odak sıfırlanır.
    // Uzunluk yetmez: aynı sayıda ama farklı sıradaki kategoriler de kayar.
    if (!listEquals(
      [for (final c in oldWidget.pieData) c.name],
      [for (final c in widget.pieData) c.name],
    )) {
      _focusedRoot = null;
    }
  }

  /// Para yazıcısı build başında kurulur ve alt yardımcılara TAŞINIR:
  /// fl_chart'ın tooltip closure'ı build dışında çalışır, orada `watch`
  /// yapılamaz (bkz. [MoneyWriter]).
  late MoneyWriter _money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    _money = MoneyWriter.of(context);

    if (widget.fullData.isEmpty) {
      return AppCard(
        section: AppSection.transactions,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _money(0),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.titleIcinVeriYok(widget.title),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    final total = widget.fullData
        .fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    final activeData = widget.showBarChart ? widget.fullData : widget.pieData;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row DEĞİL Wrap: başlık + iki ikon + toplam tutar tek satıra
          // sığmadığında (büyük metin ölçeği, uzun İngilizce başlık, yedi
          // haneli tutar) taşmak yerine alta iner.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.pie_chart,
                      color: !widget.showBarChart
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    tooltip: context.l10n.reportViewPie,
                    onPressed: () => widget.onToggleBarChart(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.bar_chart,
                      color: widget.showBarChart
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    tooltip: context.l10n.reportViewBars,
                    onPressed: () => widget.onToggleBarChart(true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _money(total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.isExpense ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          widget.showBarChart
              ? const SizedBox.shrink()
              : ReportSunburstChart(
                  roots: widget.pieData,
                  categoryLabels: widget.categoryLabels,
                  focusedIndex: _focusedRoot,
                  onFocusChanged: (i) => setState(() => _focusedRoot = i),
                  onSliceTap: (slice) =>
                      widget.onCategoryTap(slice, ReportSliceMode.pie),
                ),
          if (!widget.showBarChart && _hasHierarchy) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.reportHierarchyHint,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Çubuk görünümü efsanenin YERİNE geçer (ad, tutar ve pay zaten
          // satırda); pasta görünümünde efsane dilimlerin okunmasını sağlar.
          if (widget.showBarChart)
            ReportCategoryBarList(
              data: widget.fullData,
              total: total,
              categoryLabels: widget.categoryLabels,
              budgetProgressFor:
                  widget.isExpense ? widget.budgetProgressFor : null,
              onCategoryTap: (cat) =>
                  widget.onCategoryTap(cat, ReportSliceMode.full),
            )
          else
            _buildLegend(context, theme, activeData, total),
        ],
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    ThemeData theme,
    List<CategoryData> data,
    double total,
  ) {
    final scheme = theme.colorScheme;
    return Column(
      children: data.map((item) {
        final percent = total == 0 ? 0 : (item.totalAmount / total) * 100;
        final budgetInfo = widget.isExpense
            ? widget.budgetProgressFor(item.name, item.totalAmount)
            : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onCategoryTap(
                item,
                widget.showBarChart
                    ? ReportSliceMode.full
                    : ReportSliceMode.pie),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.labelIn(context, widget.categoryLabels),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.formatMoneyItemTotalamountPercent(
                          _money(item.totalAmount), percent.toStringAsFixed(0)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (budgetInfo != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: budgetInfo.progress,
                        minHeight: 4,
                        backgroundColor:
                            scheme.onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          budgetInfo.isExceeded
                              ? Colors.redAccent
                              : Colors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
