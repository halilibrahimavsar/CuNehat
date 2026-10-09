import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_bar_list.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Kategori dağılımının KEŞİF kartı: tek halkalı donut + sıralı liste, ve
/// içine inilen bir yol ("Giderler › Fatura").
///
/// **Neden iki halkalı çember kalktı:** iç halka ana, dış halka alt
/// kategorileri gösteriyordu ama 220dp'lik bir çemberde 26dp'lik dış bant
/// dokunulamayacak kadar inceydi, alt kategori dilimi yanlış (boş) detay
/// açıyordu ve "Diğer"e katlanan küçük köklerin alt kırılımı hiçbir yerden
/// görülmüyordu. Artık her seviye AYNI düzende çizilir: kökler → bir kökün
/// alt kategorileri (+ doğrudan harcaması) → "Diğer"in katladığı kalemler.
///
/// Kart KONTROLLÜ: yol sayfada durur, çünkü inilen düğüm üstteki zaman
/// çizgisini de süzer (bkz. `ReportTrendCard.focus`). [nodes] sayfanın
/// [ReportCategoryDataBuilder.resolvePath] ile çözdüğü geçerli yoldur.
class ReportCategoryExplorer extends StatefulWidget {
  final bool isExpense;

  /// Üst seviye kalemler (eşiklenmiş: küçükler "Diğer"de).
  final List<CategoryData> top;

  /// İnilmiş yol; boşsa üst seviyedeyiz.
  final List<CategoryData> nodes;

  final ValueChanged<List<CategoryPathStep>> onPathChanged;

  /// Bir kalemin işlemlerini açar (yaprak satır ya da "İşlemleri gör").
  final void Function(CategoryData node) onOpenTransactions;

  final ReportBudgetProgress? Function(String tag, double spent)?
      budgetProgressFor;

  /// `tag` → görünen ad.
  final Map<String, String> categoryLabels;

  const ReportCategoryExplorer({
    super.key,
    required this.isExpense,
    required this.top,
    required this.nodes,
    required this.onPathChanged,
    required this.onOpenTransactions,
    this.budgetProgressFor,
    this.categoryLabels = const {},
  });

  @override
  State<ReportCategoryExplorer> createState() => _ReportCategoryExplorerState();
}

class _ReportCategoryExplorerState extends State<ReportCategoryExplorer> {
  /// Donutta parmağın altındaki dilim (yalnız vurgu; seçim değil).
  int? _touched;

  List<CategoryData> get _items =>
      widget.nodes.isEmpty ? widget.top : widget.nodes.last.children;

  List<CategoryPathStep> get _path => [for (final n in widget.nodes) n.step];

  @override
  void didUpdateWidget(ReportCategoryExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Seviye değişince eski indeks başka bir kalemi gösterir.
    if (oldWidget.nodes.length != widget.nodes.length ||
        oldWidget.isExpense != widget.isExpense) {
      _touched = null;
    }
  }

  void _drill(CategoryData item) {
    setState(() => _touched = null);
    widget.onPathChanged([..._path, item.step]);
    _revealTop();
  }

  void _up([int? toDepth]) {
    final depth = toDepth ?? widget.nodes.length - 1;
    widget.onPathChanged(_path.take(depth < 0 ? 0 : depth).toList());
    _revealTop();
  }

  /// Seviye değişince kartın ÜSTÜ (yol + donut) görünür alana gelir.
  ///
  /// Listenin aşağısındaki bir satırdan inildiğinde yol çubuğu ekranın
  /// üstünde, görüş dışında kalıyordu: içerik değişiyor ama kullanıcı nerede
  /// olduğunu (ve nasıl geri döneceğini) göremiyordu. Kart zaten görünürse
  /// kaydırma yapılmaz.
  void _revealTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: AppMotion.of(context).d(AppMotion.medium),
        curve: AppMotion.standard,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  void _activate(CategoryData item) =>
      item.canDrill ? _drill(item) : widget.onOpenTransactions(item);

  String _label(BuildContext context, CategoryData item, {String? parent}) =>
      item.isDirect && parent != null
          ? context.l10n.dogrudanKategoriSec(parent)
          : item.labelIn(context, widget.categoryLabels);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);
    final sideTitle = widget.isExpense
        ? context.l10n.reportExpensesTitle
        : context.l10n.reportIncomesTitle;

    if (widget.top.isEmpty) {
      return AppCard(
        section: AppSection.transactions,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.donut_large_rounded,
                size: 44,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.titleIcinVeriYok(sideTitle),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = _items;
    final total = items.fold<double>(0, (s, c) => s + c.totalAmount);
    final parent = widget.nodes.isEmpty ? null : widget.nodes.last;
    final parentLabel = parent?.labelIn(context, widget.categoryLabels);
    final touched =
        _touched != null && _touched! < items.length ? items[_touched!] : null;
    final motion = AppMotion.of(context);

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Breadcrumb(
            rootLabel: sideTitle,
            crumbs: [
              for (final n in widget.nodes)
                n.labelIn(context, widget.categoryLabels),
            ],
            onUp: widget.nodes.isEmpty ? null : () => _up(),
            onCrumb: _up,
          ),
          const SizedBox(height: 8),
          // Seviye değişimi solarak olur: hangi seviyede olduğunu kullanıcı
          // yolun yanında içeriğin değişmesinden de okur.
          AnimatedSwitcher(
            duration: motion.d(AppMotion.medium),
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, if (current != null) current],
            ),
            child: Column(
              key: ValueKey(_path.map((s) => s.name).join('/')),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Donut(
                  items: items,
                  total: total,
                  touched: _touched,
                  centerLabel: touched == null
                      ? (parentLabel ?? context.l10n.reportTotalLabel)
                      : _label(context, touched, parent: parentLabel),
                  centerAmount: touched?.totalAmount ?? total,
                  centerColor: touched?.color,
                  money: money,
                  onTouched: (i) => setState(() => _touched = i),
                  onTap: (i) => _activate(items[i]),
                ),
                if (widget.nodes.isEmpty && items.any((c) => c.canDrill)) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      context.l10n.reportDrillHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                ReportCategoryBarList(
                  data: items,
                  total: total,
                  parentLabel: parentLabel,
                  categoryLabels: widget.categoryLabels,
                  increaseIsGood: !widget.isExpense,
                  budgetProgressFor:
                      widget.isExpense ? widget.budgetProgressFor : null,
                  onDrill: _drill,
                  onCategoryTap: widget.onOpenTransactions,
                ),
                if (parent != null) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onOpenTransactions(parent),
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: Text(context.l10n
                          .reportSeeTransactions(parent.transactions.length)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Giderler › Fatura" — her parça bir üst seviyeye götürür.
class _Breadcrumb extends StatelessWidget {
  final String rootLabel;
  final List<String> crumbs;
  final VoidCallback? onUp;
  final ValueChanged<int> onCrumb;

  const _Breadcrumb({
    required this.rootLabel,
    required this.crumbs,
    required this.onUp,
    required this.onCrumb,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labels = [rootLabel, ...crumbs];
    final active = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: scheme.onSurface,
    );
    final link = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.primary,
    );

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          if (onUp != null)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              tooltip: context.l10n.reportBreadcrumbUp,
              onPressed: onUp,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Derin yolda en sağdaki (bulunulan) seviye görünür kalsın.
              reverse: true,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0)
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: scheme.onSurfaceVariant),
                    if (i == labels.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(labels[i], style: active),
                      )
                    else
                      InkWell(
                        onTap: () => onCrumb(i),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          child: Text(labels[i], style: link),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek halkalı donut; merkezde seviyenin (ya da parmağın altındaki dilimin)
/// adı ve tutarı.
class _Donut extends StatelessWidget {
  final List<CategoryData> items;
  final double total;
  final int? touched;
  final String centerLabel;
  final double centerAmount;
  final Color? centerColor;
  final MoneyWriter money;
  final ValueChanged<int?> onTouched;
  final ValueChanged<int> onTap;

  const _Donut({
    required this.items,
    required this.total,
    required this.touched,
    required this.centerLabel,
    required this.centerAmount,
    required this.centerColor,
    required this.money,
    required this.onTouched,
    required this.onTap,
  });

  static const double _centerRadius = 52;
  static const double _band = 30;
  static const double _grow = 6;

  /// Yüzde etiketi için en düşük pay. Ölçüldü (eski çember, r≈61): "%3"
  /// etiketi 15,7px, %3'lük yay 11,5px — komşusuna biniyordu.
  static const double _minLabelPercent = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (total <= 0) return const SizedBox.shrink();

    return Semantics(
      label: context.l10n
          .reportDonutSemantics(items.length.toString(), money(total)),
      child: SizedBox(
        height: 2 * (_centerRadius + _band + _grow) + 4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 2,
                centerSpaceRadius: _centerRadius,
                borderData: FlBorderData(show: false),
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    final index =
                        response?.touchedSection?.touchedSectionIndex ?? -1;
                    final valid = index >= 0 && index < items.length;
                    if (event is FlTapUpEvent) {
                      onTouched(null);
                      if (valid) onTap(index);
                      return;
                    }
                    // Basılı tutup gezdirmek dilimi vurgular, merkez onu
                    // yazar — dokunmadan "bu dilim ne" sorusu cevaplanır.
                    if (!event.isInterestedForInteractions) {
                      onTouched(null);
                    } else if (valid && index != touched) {
                      onTouched(index);
                    }
                  },
                ),
                sections: [
                  for (var i = 0; i < items.length; i++)
                    () {
                      final percent = items[i].totalAmount / total * 100;
                      final isTouched = touched == i;
                      return PieChartSectionData(
                        value: items[i].totalAmount,
                        color: touched == null || isTouched
                            ? items[i].color
                            : items[i].color.withValues(alpha: 0.35),
                        radius: _band + (isTouched ? _grow : 0),
                        title: percent >= _minLabelPercent
                            ? formatPercent(percent)
                            : '',
                        titlePositionPercentageOffset: 0.55,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      );
                    }(),
                ],
              ),
            ),
            SizedBox(
              width: _centerRadius * 1.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    money.compact(centerAmount),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: centerColor ?? scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
