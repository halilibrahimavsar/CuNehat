import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/label_grouper.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';

/// Dönemin en çok harcanan YERLERİ — işlem başlıklarına göre.
///
/// **Neden kategori kırılımının yanına:** kategori "ne için" sorusunu
/// cevaplıyor ("Market 12.180 TL"), ama "nereye" sorusunu cevaplamıyor. Aynı
/// 12.180 TL'nin 8.400'ü tek bir zincire gidiyorsa bu, bütçe kararını
/// kategoriden daha çok değiştirir. Banka ekstresi başlıkları zaten üye işyeri
/// adını taşıyor (`TransactionEntity.title`).
///
/// **Gruplama ortak motordan gelir** (`core/utils/label_grouper.dart`):
/// "SOK-10419-USKUDAR" ile "SOK-22133-KADIKOY" tek kaleme iner. Motorun
/// ölçülmüş sınırı (ortak ön ek her zaman marka değildir) burada zararsızdır:
/// bu kart yalnız BİLGİ verir, hiçbir veriyi değiştirmez — ekstre tarafındaki
/// toplu atamanın aksine yanlış bir gruplamanın bedeli okuma hatasıdır.
///
/// Tek seferlik başlıklar (bir kez geçen "Kahve") grup kurmaz; onları
/// listelemek "en çok harcanan yer" sorusunu cevaplamaz, yalnız listeyi şişirir.
class ReportTopPayeesCard extends StatelessWidget {
  /// Dönemin GİDER işlemleri (sistem hareketleri süzülmüş olarak gelir).
  final List<TransactionEntity> transactions;

  /// Bir gruba dokunulduğunda o gruptaki işlemler.
  final void Function(String label, List<TransactionEntity> transactions)
      onGroupTap;

  const ReportTopPayeesCard({
    super.key,
    required this.transactions,
    required this.onGroupTap,
  });

  /// Kaç kalem gösterilir. Sekizden sonrası kaydırma gerektiriyor ve "en çok"
  /// sorusunun cevabı olmaktan çıkıyor.
  static const int maxRows = 8;

  /// Dönemin gider işlemlerinden grupları çıkarır.
  ///
  /// Görünürlük için ayrı: sayfa kartı çizmeden önce "grup var mı" diye
  /// sorabilsin (tek kalemlik bir kart yer kaplamasın).
  static List<({String label, double total, List<TransactionEntity> items})>
      buildGroups(List<TransactionEntity> transactions) {
    final expenses = [
      for (final t in transactions)
        if (t.isExpense) t,
    ];
    if (expenses.length < kMinGroupSize) return const [];

    final groups = groupSimilarLabels(
      [
        for (final t in expenses) (text: t.title, amount: t.amount, bucket: 0),
      ],
      // İLK anlamlı kelimede dur: marka orada. Derinlik sınırsızken
      // "SOK-10419-USKUDAR" ×2 + "SOK-22133-KADIKOY" ×1 girdisinde motor
      // Üsküdar dalına iniyor ve Kadıköy satırı listeden tamamen düşüyor
      // (ŞOK 790 yerine 510 görünüyor). Bkz. [groupSimilarLabels].
      maxDepth: 1,
    );

    return [
      for (final g in groups.take(maxRows))
        (
          label: g.label,
          total: g.totalAmount,
          items: [for (final i in g.indexes) expenses[i]],
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groups = buildGroups(transactions);
    if (groups.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = MoneyWriter.of(context);
    final maxTotal = groups.first.total;

    return AppCard(
      section: AppSection.transactions,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.reportTopPayeesHint,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 12),
          for (final group in groups)
            _PayeeRow(
              label: group.label,
              total: group.total,
              count: group.items.length,
              fraction: maxTotal <= 0 ? 0 : group.total / maxTotal,
              money: money,
              theme: theme,
              onTap: () => onGroupTap(group.label, group.items),
            ),
        ],
      ),
    );
  }
}

class _PayeeRow extends StatelessWidget {
  final String label;
  final double total;
  final int count;
  final double fraction;
  final MoneyWriter money;
  final ThemeData theme;
  final VoidCallback onTap;

  const _PayeeRow({
    required this.label,
    required this.total,
    required this.count,
    required this.fraction,
    required this.money,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final countText = context.l10n.reportPayeeCount('$count');

    return Semantics(
      button: true,
      label: '$label, ${money(total)}, $countText',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                    countText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    money(total),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Container(
                      // En küçük kalem de görünür kalsın.
                      width: (constraints.maxWidth * fraction)
                          .clamp(4.0, constraints.maxWidth),
                      height: 6,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
