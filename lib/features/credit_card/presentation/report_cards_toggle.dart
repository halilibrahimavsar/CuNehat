import 'package:flutter/material.dart';

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';

/// Hesabın raporunda "Kart harcamalarını dahil et": açıkken harcama
/// analizi (özet, kırılımlar, ödeme yerleri, akış) bağlı kartların
/// harcamalarını da kapsar; bakiye çizgisi hesabın kendi defterinde kalır.
class ReportCardsToggle extends StatelessWidget {
  final bool included;
  final int cardCount;
  final ValueChanged<bool> onChanged;

  const ReportCardsToggle({
    super.key,
    required this.included,
    required this.cardCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      section: AppSection.neutral,
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      elevated: false,
      child: Row(
        children: [
          Icon(Icons.credit_card_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.kkRaporKartlarDahil,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  included
                      ? context.l10n.kkRaporKartlarAcik(cardCount)
                      : context.l10n.kkRaporKartlarKapali(cardCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            key: const ValueKey('report-cards-toggle'),
            value: included,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
