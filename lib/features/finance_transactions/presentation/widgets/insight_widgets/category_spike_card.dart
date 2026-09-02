import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_analytics_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:flutter/material.dart';

/// Kategori bazlı harcama sıçraması uyarısı kartı.
///
/// Kıyas penceresi kartın kendi metninde yazar ([CategorySpike.windowDays]):
/// dönem ortasındayken karşılaştırma "geçen ay" değil, aralığın yaşanmış
/// kısmı kadar önceki penceredir.
class CategorySpikeCard extends StatelessWidget {
  final CategorySpike spike;
  final MoneyWriter money;

  /// `tag` → görünen ad; boşsa kategori id'si l10n'a düşer.
  final Map<String, String> categoryLabels;

  /// Verilirse kart dokunulabilir olur (kategorinin işlemlerini açar).
  final VoidCallback? onTap;

  const CategorySpikeCard({
    super.key,
    required this.spike,
    required this.money,
    this.categoryLabels = const {},
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final categoryName =
        context.categoryLabelForTag(spike.categoryName, labels: categoryLabels);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        accent: AppGradients.debt,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppGradients.debt.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: AppGradients.debt,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        context.l10n.insightSpikeTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppGradients.debt,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppGradients.debt.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          formatPercent(spike.percentIncrease, signed: true),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppGradients.debt,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$categoryName: ${money(spike.currentAmount)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.insightSpikeDesc(
                      spike.windowDays,
                      money(spike.previousAmount),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}
