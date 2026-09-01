import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:flutter/material.dart';

/// Kategorilerin YATAY çubuklarla sıralanmış listesi — pasta kartının "çubuk"
/// görünümü.
///
/// **Neden fl_chart'lı dikey çubuk değil:** eskiden bu görünüm bir `BarChart`
/// idi ve ölçüldü — `leftTitles`, `bottomTitles`, `gridData` HEPSİ kapalıydı.
/// Yani ekranda ne isim ne değer taşıyan, yatay kaydırılan (kaydırma
/// göstergesi de olmayan) renkli çubuklar duruyordu; her şeyi altındaki
/// efsaneyle renk eşleştirerek okumak gerekiyordu.
///
/// Yatay düzen bu veriye daha uygun: kategori adları Türkçede uzun
/// ("Ulaşım", "Sağlık", "Ev ve Kira") ve dikey eksende kesiliyorlar; yatayda
/// her satır tam genişlik alır, kaydırma gerekmez, çubuk uzunlukları ortak
/// tabandan kıyaslanabilir. Satırın kendisi aynı zamanda dokunma hedefidir —
/// 28dp'lik bir çubuğa nişan almak gerekmez.
///
/// Bu görünüm efsanenin YERİNE geçer: ad, tutar ve pay zaten satırda.
///
/// Alt kategorisi olan satırlar AÇILIR: chevron'a dokununca çocuklar girintili
/// alt çubuklar olarak açılır ve kendi içlerinde (ana kalemin toplamına göre)
/// ölçeklenir. Hiyerarşi eskiden yalnız detay sayfasındaki düz metin
/// satırlarında görünüyordu.
class ReportCategoryBarList extends StatefulWidget {
  final List<CategoryData> data;

  /// Payların paydası. Dilimlerin toplamı verilir; sıfır ya da negatifse
  /// yüzdeler yazılmaz.
  final double total;

  final void Function(CategoryData category) onCategoryTap;

  /// `tag` → görünen ad.
  final Map<String, String> categoryLabels;

  /// Kategorinin bütçe ilerlemesi (yalnız gider tarafında verilir).
  final ({double progress, bool isExceeded, double limit})? Function(
      String tag, double spent)? budgetProgressFor;

  const ReportCategoryBarList({
    super.key,
    required this.data,
    required this.total,
    required this.onCategoryTap,
    this.categoryLabels = const {},
    this.budgetProgressFor,
  });

  /// Çubuk kalınlığı — mark tavanı 24dp (bkz. karşılaştırma kartı).
  static const double barHeight = 8;

  /// Alt çubuk daha ince: hiyerarşi kalınlıkla da okunur.
  static const double childBarHeight = 5;

  @override
  State<ReportCategoryBarList> createState() => _ReportCategoryBarListState();
}

class _ReportCategoryBarListState extends State<ReportCategoryBarList> {
  /// Açık ana kategorilerin id'leri. Liste değişince (dönem/mod) temizlenir.
  final Set<String> _expanded = {};

  @override
  void didUpdateWidget(ReportCategoryBarList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final names = {for (final c in widget.data) c.name};
    _expanded.removeWhere((id) => !names.contains(id));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);

    // Çubuk uzunlukları EN BÜYÜK KALEME göre ölçeklenir, toplama göre değil:
    // toplamla ölçeklenince %8'lik bir kalem 26dp'ye iniyor ve kalemler
    // arasındaki fark okunmuyordu. Paylar zaten satırda yazılı.
    final maxAmount = widget.data
        .fold<double>(0, (m, c) => c.totalAmount > m ? c.totalAmount : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in widget.data) ...[
          _Row(
            item: item,
            fraction: maxAmount <= 0 ? 0 : item.totalAmount / maxAmount,
            percent: widget.total <= 0
                ? null
                : item.totalAmount / widget.total * 100,
            money: money,
            scheme: scheme,
            theme: theme,
            label: item.labelIn(context, widget.categoryLabels),
            budget: widget.budgetProgressFor?.call(item.name, item.totalAmount),
            expanded: _expanded.contains(item.name),
            onToggleExpanded: item.children.isEmpty
                ? null
                : () => setState(() {
                      if (!_expanded.remove(item.name)) {
                        _expanded.add(item.name);
                      }
                    }),
            onTap: () => widget.onCategoryTap(item),
          ),
          if (_expanded.contains(item.name))
            _ChildRows(
              parent: item,
              money: money,
              scheme: scheme,
              theme: theme,
              categoryLabels: widget.categoryLabels,
              budgetProgressFor: widget.budgetProgressFor,
              onCategoryTap: widget.onCategoryTap,
            ),
        ],
      ],
    );
  }
}

/// Bir ana kategorinin açılmış alt kırılımı.
///
/// Alt çubuklar ANA KALEMİN toplamına göre ölçeklenir, listenin en büyüğüne
/// göre değil: kırılımın sorusu "bu 4.240 TL'nin içinde ne var", "Kira'ya
/// göre ne kadar" değil.
class _ChildRows extends StatelessWidget {
  final CategoryData parent;
  final MoneyWriter money;
  final ColorScheme scheme;
  final ThemeData theme;
  final Map<String, String> categoryLabels;
  final ({double progress, bool isExceeded, double limit})? Function(
      String tag, double spent)? budgetProgressFor;
  final void Function(CategoryData category) onCategoryTap;

  const _ChildRows({
    required this.parent,
    required this.money,
    required this.scheme,
    required this.theme,
    required this.categoryLabels,
    required this.budgetProgressFor,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxChild = parent.children
        .fold<double>(0, (m, c) => c.totalAmount > m ? c.totalAmount : m);

    return Padding(
      padding: const EdgeInsets.only(left: 18, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final child in parent.children)
            _ChildRow(
              child: child,
              // Kökün doğrudan harcaması ayrı bir kategori DEĞİL; adı
              // "Doğrudan Fatura" biçiminde yazılır ve tıklanabilir olmaz.
              label: child.isDirect
                  ? context.l10n.dogrudanKategoriSec(
                      parent.labelIn(context, categoryLabels))
                  : child.labelIn(context, categoryLabels),
              fraction: maxChild <= 0 ? 0 : child.totalAmount / maxChild,
              percent: parent.totalAmount <= 0
                  ? null
                  : child.totalAmount / parent.totalAmount * 100,
              money: money,
              scheme: scheme,
              theme: theme,
              budget: child.isDirect
                  ? null
                  : budgetProgressFor?.call(child.name, child.totalAmount),
              onTap: child.isDirect ? null : () => onCategoryTap(child),
            ),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  final CategoryData child;
  final String label;
  final double fraction;
  final double? percent;
  final MoneyWriter money;
  final ColorScheme scheme;
  final ThemeData theme;
  final ({double progress, bool isExceeded, double limit})? budget;
  final VoidCallback? onTap;

  const _ChildRow({
    required this.child,
    required this.label,
    required this.fraction,
    required this.percent,
    required this.money,
    required this.scheme,
    required this.theme,
    required this.budget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amountText = percent == null
        ? money(child.totalAmount)
        : context.l10n.formatMoneyItemTotalamountPercent(
            money(child.totalAmount),
            percent!.toStringAsFixed(0),
          );

    return Semantics(
      button: onTap != null,
      label: '$label, $amountText',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right,
                      size: 13,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: child.isDirect ? FontStyle.italic : null,
                        color: scheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amountText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Container(
                        height: ReportCategoryBarList.childBarHeight,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        width: (constraints.maxWidth * fraction)
                            .clamp(3.0, constraints.maxWidth),
                        height: ReportCategoryBarList.childBarHeight,
                        decoration: BoxDecoration(
                          color: child.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (budget != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Text(
                    '${formatPercent(budget!.progress * 100)} / '
                    '${money(budget!.limit)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          budget!.isExceeded ? Colors.redAccent : Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final CategoryData item;
  final double fraction;
  final double? percent;
  final MoneyWriter money;
  final ColorScheme scheme;
  final ThemeData theme;
  final String label;
  final ({double progress, bool isExceeded, double limit})? budget;
  final VoidCallback onTap;

  /// Alt kırılım açık mı; [onToggleExpanded] null ise kırılım yoktur ve
  /// chevron çizilmez.
  final bool expanded;
  final VoidCallback? onToggleExpanded;

  const _Row({
    required this.item,
    required this.fraction,
    required this.percent,
    required this.money,
    required this.scheme,
    required this.theme,
    required this.label,
    required this.budget,
    required this.onTap,
    this.expanded = false,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final amountText = percent == null
        ? money(item.totalAmount)
        : context.l10n.formatMoneyItemTotalamountPercent(
            money(item.totalAmount),
            percent!.toStringAsFixed(0),
          );

    return Semantics(
      button: true,
      label: '$label, $amountText',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amountText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  // Chevron AYRI dokunma hedefi: satırın kendisi işlemleri
                  // açar, chevron kırılımı. İkisi tek jeste bindirilirse
                  // kırılıma bakmak isteyen kullanıcı her seferinde alt
                  // sayfayla karşılaşırdı.
                  if (onToggleExpanded != null)
                    Semantics(
                      button: true,
                      expanded: expanded,
                      label: context.l10n.reportBreakdownToggle(label),
                      child: InkWell(
                        onTap: onToggleExpanded,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              Icons.expand_more_rounded,
                              size: 20,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Çubuk: ortak sol taban, veri ucu yuvarlak.
              LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(
                      height: ReportCategoryBarList.barHeight,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      // En küçük kalem bile GÖRÜNÜR kalsın: sıfır genişlikli
                      // bir çubuk "veri yok" gibi okunur.
                      width: (constraints.maxWidth * fraction)
                          .clamp(4.0, constraints.maxWidth),
                      height: ReportCategoryBarList.barHeight,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              if (budget != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: budget!.progress,
                          minHeight: 4,
                          backgroundColor:
                              scheme.onSurface.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation(
                            budget!.isExceeded
                                ? Colors.redAccent
                                : Colors.green,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formatPercent(budget!.progress * 100)} / '
                      '${money(budget!.limit)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: budget!.isExceeded
                            ? Colors.redAccent
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
