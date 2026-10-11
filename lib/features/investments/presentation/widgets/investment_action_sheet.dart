import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
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
    return showRowActionSheet<InvestmentAction>(
      context,
      builder: (context) => InvestmentActionSheet(investment: investment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return RowActionSheet<InvestmentAction>(
      title: investment.name,
      icon: investment.type == InvestmentType.gold
          ? Icons.monetization_on_rounded
          : investment.type == InvestmentType.stock
              ? Icons.trending_up_rounded
              : Icons.account_balance_wallet_rounded,
      accent: investment.color,
      actions: [
        RowAction(
          value: InvestmentAction.contribute,
          icon: Icons.add_circle_outline_rounded,
          color: investment.color,
          title: investment.symbol != null
              ? l10n.varlikEkle
              : (investment.goalId != null
                  ? l10n.hedefeParaEkle
                  : l10n.paraEkle),
          subtitle: investment.symbol != null
              ? l10n.yeniAlimMiktarVeyaTutar
              : l10n.maliyeteVeDegereEklenir,
        ),
        if (investment.canRefreshPrice)
          RowAction(
            value: InvestmentAction.refreshPrice,
            icon: Icons.refresh_rounded,
            color: Colors.teal,
            title: l10n.fiyatiGuncelle,
            subtitle: l10n.canliFiyatGuncellemeAciklamasi,
          ),
        RowAction(
          value: InvestmentAction.edit,
          icon: Icons.edit_rounded,
          color: Colors.blueGrey,
          title: l10n.duzenle,
          subtitle: l10n.duzenleYatirimSubtitle,
        ),
        RowAction(
          value: InvestmentAction.sell,
          icon: Icons.sell_rounded,
          color: Colors.green,
          title: l10n.sat,
          subtitle: l10n.satSubtitle,
        ),
        RowAction(
          value: InvestmentAction.delete,
          icon: Icons.delete_outline_rounded,
          title: l10n.kaydiSil,
          subtitle: l10n.kaydiSilSubtitle,
          destructive: true,
        ),
      ],
    );
  }
}
