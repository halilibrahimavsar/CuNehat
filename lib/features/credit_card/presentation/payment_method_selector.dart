import 'package:flutter/material.dart';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/credit_card/presentation/mini_credit_card.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';

/// Gider formunda "Nereden ödendi?": hesabın kendisi ya da ona bağlı bir
/// kredi kartı. Kullanıcı karta "geçmeden" kart harcaması girer; kayıt
/// seçilen cüzdanın defterine yazılır.
///
/// Seçim [selected]'a yazılır; seçenekler hep aynı birimdedir (çağıran
/// süzer).
class PaymentMethodSelector extends StatelessWidget {
  final List<WalletEntity> options;
  final ValueNotifier<String> selected;
  final Color accent;

  const PaymentMethodSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.kkOdemeYontemi,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<String>(
          valueListenable: selected,
          builder: (context, current, _) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in options)
                _MethodPill(
                  key: ValueKey('pay-${w.id}'),
                  wallet: w,
                  selected: w.id == current,
                  accent: accent,
                  onTap: () => selected.value = w.id!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MethodPill extends StatelessWidget {
  final WalletEntity wallet;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _MethodPill({
    super.key,
    required this.wallet,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final last4 = wallet.creditCard?.last4;
    final label = last4 == null ? wallet.name : '${wallet.name} ••$last4';

    final Widget leading = wallet.isCreditCard
        ? Container(
            width: 22,
            height: 15,
            decoration: BoxDecoration(
              gradient: creditCardGradient(wallet),
              borderRadius: BorderRadius.circular(3),
            ),
          )
        : Icon(
            AppIcons.getIconData(wallet.iconName),
            size: 18,
            color: WalletColors.hexToColor(wallet.colorHex),
          );

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : cs.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? accent : cs.onSurface,
                  ),
                ),
              ),
              AnimatedSize(
                duration:
                    reduce ? Duration.zero : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child:
                            Icon(Icons.check_rounded, size: 16, color: accent),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
