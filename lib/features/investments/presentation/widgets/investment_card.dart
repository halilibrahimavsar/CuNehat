import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/gold_types.dart';
import 'package:flutter/material.dart';

class InvestmentCard extends StatelessWidget {
  final InvestmentEntity investment;

  /// Kaydın cüzdanının para birimi: maliyet, güncel değer ve kâr/zarar bu
  /// birimdedir (kayıtta ayrı bir değerleme birimi alanı yok).
  final String currency;

  const InvestmentCard({
    super.key,
    required this.investment,
    required this.currency,
  });

  IconData _getInvestmentIcon(InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return Icons.trending_up;
      case InvestmentType.gold:
        return Icons.monetization_on;
      case InvestmentType.custom:
        return Icons.account_balance_wallet;
    }
  }

  String _getInvestmentTypeText(BuildContext context, InvestmentType type) {
    switch (type) {
      case InvestmentType.stock:
        return context.l10n.yatirimTuruHisse;
      case InvestmentType.gold:
        return context.l10n.yatirimTuruAltin;
      case InvestmentType.custom:
        return context.l10n.yatirimTuruOzel;
    }
  }

  /// Kartın "kaç gramım var" satırı: miktar + birim, yanında birim fiyat.
  /// Miktar takibi olmayan kayıtta (özel varlık) satır hiç çizilmez.
  String? _quantityLine(BuildContext context) {
    final quantity = investment.quantity;
    if (quantity == null || quantity <= 0) return null;
    final unit = investmentUnitLabel(context, investment);
    if (unit == null) return null;
    // Adet hassas kalır (0,125 gr); paradan farklı olarak 4 hane.
    final qtyText = formatAmountForInput(quantity, decimalDigits: 4);
    final line = context.l10n.kartMiktarBirim(qtyText, unit);
    final unitValue = investment.unitValue;
    if (unitValue == null) return line;
    return '$line · '
        '${context.l10n.kartBirimFiyat(formatMoney(unitValue, currency: currency))}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = investment.color;
    final profitColor = investment.isProfitable ? Colors.green : Colors.red;
    final quantityLine = _quantityLine(context);

    return AppCard(
      accent: accent,
      child: Row(
        children: [
          // İkon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getInvestmentIcon(investment.type),
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        investment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (investment.symbol != null)
                      // Rozet ESNEK: "Gram Altın" gibi uzun etiketler dar
                      // kartta (hedef grubunun içinde 104px) taşırıyordu.
                      // Ad değil rozet kısalır — ad kaydın kimliği.
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            // Altında ham anahtar ("gram-altin") değil adı;
                            // hissede sembolün kendisi zaten okunur (AAPL).
                            investment.type == InvestmentType.gold
                                ? goldTypeLabel(context, investment.symbol!)
                                : investment.symbol!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getInvestmentTypeText(context, investment.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (quantityLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    quantityLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // İki sütun da ESNEK: serbest bıraktığında büyük tutarlar
                // (ölçüldü: hedef grubunun içinde 204px alanda 124px taşma)
                // kartı taşırıyordu. Tutarlar kırpılmaz, sığmazsa küçülür —
                // parada üç nokta rakam kaybıdır.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.mevcutDeger,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              formatMoney(investment.currentValue,
                                  currency: currency),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            context.l10n.karZarar,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              formatMoney(investment.profit,
                                  currency: currency),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: profitColor,
                              ),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              context.l10n
                                  .investmentProfitpercentageTostringasfixed(
                                      investment.profitPercentage
                                          .toStringAsFixed(2)),
                              style: TextStyle(
                                fontSize: 11,
                                color: profitColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
