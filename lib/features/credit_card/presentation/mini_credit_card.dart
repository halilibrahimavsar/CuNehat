import 'package:flutter/material.dart';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';

/// Kartın rengi: cüzdan rengi (kurulumda koyu arduvaz), koyu köşegen
/// gradyanla — beyaz yazı her iki temada da okunur.
LinearGradient creditCardGradient(WalletEntity card) {
  final base = WalletColors.hexToColor(card.colorHex);
  final dark = Color.lerp(base, Colors.black, 0.45)!;
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.lerp(base, Colors.black, 0.1)!, dark],
  );
}

/// "Bonus · •••• 4321" — kart adı dışındaki kimlik satırı; boşsa boş dize.
String creditCardSubtitle(WalletEntity card) {
  final info = card.creditCard;
  if (info == null) return '';
  return [
    if (info.bankName != null) info.bankName!,
    if (info.last4 != null) '•••• ${info.last4}',
  ].join(' · ');
}

/// Kredi kartının küçük "fiziksel kart" görünümü: cüzdan listesindeki
/// yığında ve ödeme yöntemi seçicisinde.
///
/// Borç, kartın EKSİ bakiyesinin kendisi değil mutlak değeridir ("Borç
/// 8.420 ₺"); kart alacaklıysa (fazla ödeme) artı gösterilir.
class MiniCreditCard extends StatelessWidget {
  final WalletEntity card;

  /// Aktif bağlam bu kart mı (ince beyaz çerçeve).
  final bool active;

  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MiniCreditCard({
    super.key,
    required this.card,
    this.active = false,
    this.height = 64,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = creditCardSubtitle(card);
    final debt = card.balance < 0 ? -card.balance : card.balance;
    const white = Colors.white;
    return Semantics(
      button: onTap != null,
      selected: active,
      label: [card.name, subtitle].where((s) => s.isNotEmpty).join(', '),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: creditCardGradient(card),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: white.withValues(alpha: active ? 0.85 : 0.12),
              width: active ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // Çip
                  Container(
                    width: 26,
                    height: 19,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE6C77A), Color(0xFFB8913B)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: white.withValues(alpha: 0.75),
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MoneyText(
                    amount: debt,
                    currency: card.currency,
                    style: const TextStyle(
                      color: white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
