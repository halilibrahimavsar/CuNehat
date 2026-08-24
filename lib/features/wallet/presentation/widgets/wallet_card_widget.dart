import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class WalletCardWidget extends StatelessWidget {
  final WalletEntity wallet;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WalletCardWidget({
    super.key,
    required this.wallet,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = WalletColors.hexToColor(wallet.colorHex);
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      accent: color,
      selected: wallet.isActive,
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // İkon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  AppIcons.getIconData(wallet.iconName),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // İsim & Bakiye
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MoneyText(
                      amount: wallet.balance,
                      currency: wallet.currency,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: wallet.balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    // Döviz cüzdanında son bilinen kurla TL karşılığı;
                    // kur hiç yoksa satır gizlenir (yanıltıcı 0 yazmayız).
                    if (wallet.currency != kDefaultCurrency)
                      if (getIt<ExchangeRateService>()
                              .cachedRateToTry(wallet.currency)
                          case final double rate)
                        Text(
                          context.l10n.yaklasikKarsilikFormat(
                              formatMoney(wallet.balance * rate)),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    Text(
                      context.l10n.olusturulmaAppformattersDateshortFormat(
                          AppFormatters.dateShort.format(wallet.createdAt)),
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Aktif göstergesi
              if (wallet.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.aktif,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Stat satırı (Birikim, Alacak, Borç)
          if (wallet.debt > 0 ||
              wallet.credit > 0 ||
              wallet.investment > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(context.l10n.birikimLabel, wallet.investment,
                      Colors.green, Icons.savings, scheme),
                  _buildStatItem(context.l10n.alacakLabel, wallet.credit,
                      Colors.teal, Icons.arrow_upward, scheme),
                  _buildStatItem(context.l10n.borcLabel, wallet.debt,
                      Colors.red, Icons.arrow_downward, scheme),
                ],
              ),
            ),
          ],

          // Aksiyon butonları
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: IboGlassButton(
                  text: context.l10n.duzenle,
                  onPressed: onEdit,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  foregroundColor: Colors.blue,
                  borderColor: Colors.blue.withValues(alpha: 0.3),
                  borderWidth: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: 6),
                      Text(context.l10n.duzenle),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!wallet.isActive)
                Expanded(
                  child: IboGlassButton(
                    text: context.l10n.sil,
                    onPressed: onDelete,
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    foregroundColor: Colors.red,
                    borderColor: Colors.red.withValues(alpha: 0.3),
                    borderWidth: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete, size: 18),
                        const SizedBox(width: 6),
                        Text(context.l10n.sil),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    double amount,
    Color color,
    IconData icon,
    ColorScheme scheme,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        MoneyText(
          amount: amount,
          currency: wallet.currency,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
