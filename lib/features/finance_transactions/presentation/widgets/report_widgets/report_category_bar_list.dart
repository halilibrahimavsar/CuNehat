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
class ReportCategoryBarList extends StatelessWidget {
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
  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);

    // Çubuk uzunlukları EN BÜYÜK KALEME göre ölçeklenir, toplama göre değil:
    // toplamla ölçeklenince %8'lik bir kalem 26dp'ye iniyor ve kalemler
    // arasındaki fark okunmuyordu. Paylar zaten satırda yazılı.
    final maxAmount = data.fold<double>(
        0, (m, c) => c.totalAmount > m ? c.totalAmount : m);

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
            label: item.labelIn(context, categoryLabels),
            budget: budgetProgressFor?.call(item.name, item.totalAmount),
            onTap: () => onCategoryTap(item),
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
  final ({double progress, bool isExceeded, double limit})? budget;
  final VoidCallback onTap;

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
                ],
              ),
              const SizedBox(height: 6),
              // Çubuk: ortak sol taban, veri ucu yuvarlak.
              LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(
                      height: ReportCategoryBarList._barHeight,
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
                      height: ReportCategoryBarList._barHeight,
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
                        color:
                            budget!.isExceeded ? Colors.redAccent : Colors.green,
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
