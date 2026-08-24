import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';

/// "Ne eklemek istersin?" — altın / hisse / özel varlık seçimi.
///
/// Ekleme akışı iki adıma bölündü: önce TÜR, sonra o türün formu. Böylece
/// hedefin içinden ("bu hedefe varlık ekle") ve boş durumdan aynı yol
/// kullanılabiliyor; her yere üç ayrı düğme koymak gerekmiyor.
class InvestmentTypeChooser extends StatelessWidget {
  const InvestmentTypeChooser({super.key});

  static Future<InvestmentType?> show(BuildContext context) {
    return showModalBottomSheet<InvestmentType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const InvestmentTypeChooser(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Material (Container değil): içerideki ListTile zeminini ve ink dalgasını
    // en yakın Material'a boyar; renkli bir DecoratedBox araya girerse dalga
    // görünmez olur ve Flutter debug'da assertion atar.
    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                  Expanded(
                    child: Text(
                      context.l10n.varlikTuruSec,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _tile(
              context,
              icon: Icons.monetization_on_rounded,
              color: Colors.amber.shade700,
              title: context.l10n.yeniAltinEkle,
              type: InvestmentType.gold,
            ),
            _tile(
              context,
              icon: Icons.trending_up_rounded,
              color: Colors.blue,
              title: context.l10n.yeniHisseEkle,
              type: InvestmentType.stock,
            ),
            _tile(
              context,
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.purple,
              title: context.l10n.yeniOzelYatirimEkle,
              type: InvestmentType.custom,
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
    required InvestmentType type,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: cs.onSurface,
        ),
      ),
      onTap: () => Navigator.pop(context, type),
    );
  }
}
