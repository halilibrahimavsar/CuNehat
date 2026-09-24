import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_tile.dart';
import 'package:cunehat/features/credit_card/presentation/mini_credit_card.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

/// İşlemler ekranının üstünde "Maaş Hesabı | Bonus ••4321": cüzdanın
/// kendisi ile ona bağlı kartlar arasında geçiş. Kart, ayrı bir cüzdan gibi
/// seçilmez; cüzdanın İÇİNDE bir sekmedir (bkz. `card_family.dart`).
///
/// Kart seçiliyken altında kısa bir durum şeridi açılır: kalan dönem borcu,
/// son ödeme ve "Öde"; ayrıntılar için karta dokunulur.
///
/// Aile tek üyeliyse (kartı olmayan cüzdan) hiç yer kaplamaz.
class CardContextRail extends StatelessWidget {
  const CardContextRail({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.creditCards) return const SizedBox.shrink();
    final WalletState state;
    try {
      state = context.watch<WalletBloc>().state;
    } on ProviderNotFoundException {
      // WalletBloc'suz ağaç (yalıtılmış sayfa testleri): şerit yok sayılır,
      // gösterim hiçbir akışı kırmamalı (bkz. wallet_currency_context.dart).
      return const SizedBox.shrink();
    }
    if (state is! WalletLoadedSt) return const SizedBox.shrink();
    final active = state.activeWallet;
    if (active == null) return const SizedBox.shrink();
    final owner = accountOf(active, state.wallets);
    final cards = cardsOf(owner.id, state.wallets);
    if (cards.isEmpty) return const SizedBox.shrink();

    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final activeCard =
        active.isCreditCard && active.id != owner.id ? active : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final w in [owner, ...cards]) ...[
                  _ContextPill(
                    key: ValueKey('ctx-${w.id}'),
                    wallet: w,
                    selected: w.id == active.id,
                    onTap: () {
                      if (w.id == active.id) {
                        if (w.isCreditCard) {
                          CardDetailsSheet.show(context, card: w);
                        }
                        return;
                      }
                      context.read<WalletBloc>().add(SetActiveWalletEvent(
                            userId: w.userId,
                            walletId: w.id!,
                            // Aynı cüzdanın içinde sekme değişimi: şeridin
                            // kendisi zaten değişimi gösteriyor.
                            announce: false,
                          ));
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          AnimatedSize(
            duration:
                reduce ? Duration.zero : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration:
                  reduce ? Duration.zero : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: activeCard == null
                  ? const SizedBox(
                      key: ValueKey('ctx-strip-none'),
                      width: double.infinity,
                    )
                  : _CardStrip(
                      key: ValueKey('ctx-strip-${activeCard.id}'),
                      card: activeCard,
                      wallets: state.wallets,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextPill extends StatelessWidget {
  final WalletEntity wallet;
  final bool selected;
  final VoidCallback onTap;

  const _ContextPill({
    super.key,
    required this.wallet,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final isCard = wallet.isCreditCard;
    final last4 = wallet.creditCard?.last4;
    final label = last4 == null ? wallet.name : '${wallet.name} ••$last4';
    final tint = isCard
        ? creditCardGradient(wallet).colors.first
        : WalletColors.hexToColor(wallet.colorHex);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: selected && isCard ? creditCardGradient(wallet) : null,
            color: selected
                ? (isCard ? null : tint.withValues(alpha: 0.16))
                : cs.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? tint : cs.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCard
                    ? Icons.credit_card_rounded
                    : AppIcons.getIconData(wallet.iconName),
                size: 16,
                color: selected && isCard ? Colors.white : tint,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected && isCard ? Colors.white : cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kart bağlamındaki kısa durum şeridi; dokununca kart ayrıntısı açılır.
class _CardStrip extends StatelessWidget {
  final WalletEntity card;
  final List<WalletEntity> wallets;

  const _CardStrip({super.key, required this.card, required this.wallets});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const ValueKey('ctx-card-details'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => CardDetailsSheet.show(context, card: card),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: CardStatusBuilder(
              card: card,
              builder: (context, status) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.kkKalanDonemBorcu,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        // Dar ekranda çip tutarın altına kayar (360dp'de
                        // yan yana sığmıyordu: ölçüldü, 15px taşma).
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              status == null
                                  ? '…'
                                  : formatMoney(status.remainingStatementDebt,
                                      currency: card.currency),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: (status?.isOverdue ?? false)
                                    ? cs.error
                                    : cs.onSurface,
                              ),
                            ),
                            if (status != null) CardDueChip(status: status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.tonal(
                    key: const ValueKey('ctx-card-pay'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: status == null
                        ? null
                        : () => payCreditCard(context,
                            card: card, wallets: wallets, status: status),
                    child: Text(l10n.kkOde),
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
