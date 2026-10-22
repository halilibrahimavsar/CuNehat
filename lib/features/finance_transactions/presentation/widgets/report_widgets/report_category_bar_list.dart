import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_bar_width.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_change_badge.dart';
import 'package:flutter/material.dart';

/// Kategorilerin YATAY çubuklarla sıralanmış listesi — kategori keşfinin
/// (bkz. `ReportCategoryExplorer`) efsanesi ve dokunma yüzeyi.
///
/// **Neden fl_chart'lı dikey çubuk değil:** eskiden bu görünüm bir `BarChart`
/// idi ve ölçüldü — `leftTitles`, `bottomTitles`, `gridData` HEPSİ kapalıydı.
/// Yatay düzen bu veriye daha uygun: kategori adları Türkçede uzun ve dikey
/// eksende kesiliyor; yatayda her satır tam genişlik alır, çubuk uzunlukları
/// ortak tabandan kıyaslanabilir. Satırın kendisi dokunma hedefidir.
///
/// **İniş modeli:** alt kategorisi olan satır (ya da "Diğer" kovası) İNER —
/// keşif kartı o kalemin kırılımını gösterir. Yaprak satır işlemlerini açar.
/// Eskiden satır içinde açılan alt satırlar vardı; alt satıra dokunmak boş
/// bir detay açıyordu ve iki ayrı dokunma hedefi (satır + chevron) aynı
/// satırda yarışıyordu.
class ReportCategoryBarList extends StatelessWidget {
  final List<CategoryData> data;

  /// Payların paydası. Dilimlerin toplamı verilir; sıfır ya da negatifse
  /// yüzdeler yazılmaz.
  final double total;

  /// Yaprak kalemin (ya da doğrudan dilimin) işlemlerini açar.
  final void Function(CategoryData category) onCategoryTap;

  /// İnilebilir kalemin kırılımına iner; null ise her satır [onCategoryTap].
  final void Function(CategoryData category)? onDrill;

  /// Doğrudan dilimin etiketi için üst kalemin adı ("Doğrudan "Fatura"").
  final String? parentLabel;

  /// `tag` → görünen ad.
  final Map<String, String> categoryLabels;

  /// Kategorinin bütçe ilerlemesi (yalnız gider tarafında verilir).
  final ReportBudgetProgress? Function(String tag, double spent)?
      budgetProgressFor;

  /// Artışın İYİ mi kötü mü olduğu — değişim rozetinin rengi buna bağlı.
  /// Gelir tarafında artış iyidir, gider tarafında kötü.
  final bool increaseIsGood;

  const ReportCategoryBarList({
    super.key,
    required this.data,
    required this.total,
    required this.onCategoryTap,
    this.onDrill,
    this.parentLabel,
    this.categoryLabels = const {},
    this.budgetProgressFor,
    this.increaseIsGood = false,
  });

  /// Çubuk kalınlığı — mark tavanı 24dp (bkz. karşılaştırma kartı).
  static const double barHeight = 8;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);

    // Çubuk uzunlukları EN BÜYÜK KALEME göre ölçeklenir, toplama göre değil:
    // toplamla ölçeklenince %8'lik bir kalem 26dp'ye iniyor ve kalemler
    // arasındaki fark okunmuyordu. Paylar zaten satırda yazılı.
    final maxAmount =
        data.fold<double>(0, (m, c) => c.totalAmount > m ? c.totalAmount : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in data)
          _Row(
            item: item,
            fraction: maxAmount <= 0 ? 0 : item.totalAmount / maxAmount,
            percent: total <= 0 ? null : item.totalAmount / total * 100,
            money: money,
            scheme: scheme,
            theme: theme,
            label: item.isDirect && parentLabel != null
                ? context.l10n.dogrudanKategoriSec(parentLabel!)
                : item.labelIn(context, categoryLabels),
            // Doğrudan dilim kökle aynı kimliği taşır; kökün bütçesini onun
            // altında yazmak yanlış olurdu.
            budget: item.isDirect || item.isOther
                ? null
                : budgetProgressFor?.call(item.name, item.totalAmount),
            increaseIsGood: increaseIsGood,
            drills: onDrill != null && item.canDrill,
            onTap: onDrill != null && item.canDrill
                ? () => onDrill!(item)
                : () => onCategoryTap(item),
          ),
      ],
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
  final ReportBudgetProgress? budget;
  final VoidCallback onTap;

  /// Satır bir kırılıma mı iner (yoksa işlemleri mi açar)? İnen satır
  /// sağda `›` taşır.
  final bool drills;

  final bool increaseIsGood;

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
    this.increaseIsGood = false,
    this.drills = false,
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
      label: drills
          ? '$label, $amountText. ${context.l10n.reportDrillInto(label)}'
          : '$label, $amountText',
      excludeSemantics: true,
      onTap: onTap,
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
                  // Wrap: sığarsa ad solda, rozet + tutar sağda; sığmazsa
                  // rozet + tutar alt satıra iner. Row'da 320dp + büyük
                  // yazıda ad "Ye…" diye iki harfe iniyordu.
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReportChangeBadge(
                              percent: item.changePercent,
                              increaseIsGood: increaseIsGood,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              amountText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (drills)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
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
                      width: visibleBarWidth(
                        maxWidth: constraints.maxWidth,
                        fraction: fraction,
                      ),
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
                                ? MoneyColors.expense
                                : MoneyColors.income,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${formatPercent(budget!.ratio * 100)} / '
                      '${money(budget!.limit)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: budget!.isExceeded
                            ? MoneyColors.expense
                            : MoneyColors.income,
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
