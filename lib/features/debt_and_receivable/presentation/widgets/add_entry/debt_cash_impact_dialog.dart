import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Borç eklenirken kullanıcının seçtiği bakiye etkisi:
/// [cash] = nakit ele geçti (anapara gelir yazılır),
/// [product] = ürün/hizmet alındı (bakiye değişmez).
enum DebtCashImpact { cash, product }

/// Borç karşılığı nakit mi yoksa ürün/hizmet mi alındığını soran dialog.
class DebtCashImpactDialog extends StatelessWidget {
  final double amount;
  final Color accent;

  const DebtCashImpactDialog({
    super.key,
    required this.amount,
    required this.accent,
  });

  static Future<DebtCashImpact?> show(
    BuildContext context, {
    required double amount,
    required Color accent,
  }) {
    return showDialog<DebtCashImpact>(
      context: context,
      builder: (_) => DebtCashImpactDialog(amount: amount, accent: accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(context.l10n.borcNakitEtkiBaslik),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.borcNakitEtkiAciklama,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _CashImpactOption(
            impact: DebtCashImpact.cash,
            icon: Icons.payments_rounded,
            title: context.l10n.borcNakitSecenekBaslik,
            body: context.l10n.borcNakitSecenekGovde(
              AppFormatters.currency.format(amount),
            ),
            accent: accent,
          ),
          const SizedBox(height: 10),
          _CashImpactOption(
            impact: DebtCashImpact.product,
            icon: Icons.shopping_bag_rounded,
            title: context.l10n.borcUrunSecenekBaslik,
            body: context.l10n.borcUrunSecenekGovde,
            accent: accent,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.vazgec),
        ),
      ],
    );
  }
}

class _CashImpactOption extends StatelessWidget {
  final DebtCashImpact impact;
  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  const _CashImpactOption({
    required this.impact,
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => Navigator.pop(context, impact),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.onSurfaceVariant,
                      height: 1.35,
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
