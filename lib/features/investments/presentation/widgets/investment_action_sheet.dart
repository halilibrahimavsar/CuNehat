import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

/// Yatırım kartına dokununca açılan eylem menüsü seçenekleri.
enum InvestmentAction { contribute, refreshPrice, edit, sell, delete }

/// Sat ve Kaydı Sil'i ayrı, açık eylemler olarak sunan menü.
/// Seçilen eylemi döndürür; iş mantığı çağıran sayfada kalır.
class InvestmentActionSheet extends StatelessWidget {
  final InvestmentEntity investment;

  const InvestmentActionSheet({super.key, required this.investment});

  static Future<InvestmentAction?> show(
    BuildContext context, {
    required InvestmentEntity investment,
  }) {
    return showModalBottomSheet<InvestmentAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => InvestmentActionSheet(investment: investment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: investment.color.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      investment.type == InvestmentType.gold
                          ? Icons.monetization_on_rounded
                          : investment.type == InvestmentType.stock
                              ? Icons.trending_up_rounded
                              : Icons.account_balance_wallet_rounded,
                      color: investment.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      investment.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            _tile(
              context,
              icon: Icons.add_circle_outline_rounded,
              color: investment.color,
              title: investment.symbol != null
                  ? context.l10n.varlikEkle
                  : (investment.isGoal
                      ? context.l10n.hedefeParaEkle
                      : context.l10n.paraEkle),
              subtitle: investment.symbol != null
                  ? context.l10n.yeniAlimMiktarVeOdenenTutar
                  : context.l10n.maliyeteVeDegereEklenir,
              action: InvestmentAction.contribute,
            ),
            if (investment.canRefreshPrice)
              _tile(
                context,
                icon: Icons.refresh_rounded,
                color: Colors.teal,
                title: context.l10n.fiyatiGuncelle,
                subtitle: context.l10n.canliFiyatGuncellemeAciklamasi,
                action: InvestmentAction.refreshPrice,
              ),
            _tile(
              context,
              icon: Icons.edit_rounded,
              color: Colors.blueGrey,
              title: context.l10n.duzenle,
              subtitle: context.l10n.duzenleYatirimSubtitle,
              action: InvestmentAction.edit,
            ),
            _tile(
              context,
              icon: Icons.sell_rounded,
              color: Colors.green,
              title: context.l10n.sat,
              subtitle: context.l10n.satSubtitle,
              action: InvestmentAction.sell,
            ),
            _tile(
              context,
              icon: Icons.delete_outline_rounded,
              color: Colors.red,
              title: context.l10n.kaydiSil,
              subtitle: context.l10n.kaydiSilSubtitle,
              action: InvestmentAction.delete,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required InvestmentAction action,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: action == InvestmentAction.delete ? Colors.red : cs.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      onTap: () => Navigator.pop(context, action),
    );
  }
}
