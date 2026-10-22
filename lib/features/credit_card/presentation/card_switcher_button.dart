import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/credit_card/presentation/card_status.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_tile.dart';
import 'package:cunehat/features/credit_card/presentation/mini_credit_card.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart'
    show AppBorderRadius;
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

/// Üst çubuğun sağındaki KART DÜĞMESİ: hesap ile ona bağlı kartlar arasında
/// geçiş.
///
/// Eskiden geçiş İşlemler ekranının üstündeki hap satırındaydı; hangi hapın
/// seçili olduğu (özellikle hesap hapında) zor okunuyordu ve satır ekranın
/// üstünde sabit yer tutuyordu (kullanıcı şikâyeti, 12 Eki 2026). Şimdi:
///
/// - **Tek kart:** dokunmak hesap ↔ kart arasında geçirir (tek hareket).
/// - **Birden çok kart:** dokunmak seçim sayfasını açar ([CardSwitchSheet]).
/// - Uzun basmak her durumda seçim sayfasını açar (kart ayrıntısına yol).
///
/// Seçili bağlam İKİ yerde birden görünür: düğme dolar ve onay rozeti alır,
/// üst çubuğun zemini kartın rengine bürünür (bkz. `AppBarBackground`).
class CardSwitcherButton extends StatelessWidget {
  /// Hesap (kartların sahibi).
  final WalletEntity owner;

  /// Hesaba bağlı kartlar (en az bir).
  final List<WalletEntity> cards;

  /// Etkin bağlam: [owner] ya da [cards]'tan biri.
  final WalletEntity active;

  const CardSwitcherButton({
    super.key,
    required this.owner,
    required this.cards,
    required this.active,
  });

  /// Etkin bağlam bir kartsa o kart.
  WalletEntity? get _activeCard =>
      active.id != owner.id && active.isCreditCard ? active : null;

  void _select(BuildContext context, WalletEntity target) {
    if (target.id == null || target.id == active.id) return;
    HapticFeedback.selectionClick();
    context.read<WalletBloc>().add(SetActiveWalletEvent(
          userId: target.userId,
          walletId: target.id!,
          // Değişimi düğmenin ve çubuğun kendisi gösteriyor.
          announce: false,
        ));
  }

  void _openSheet(BuildContext context) {
    CardSwitchSheet.show(
      context,
      owner: owner,
      cards: cards,
      activeId: active.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activeCard = _activeCard;
    final single = cards.length == 1;
    final tint = creditCardGradient(activeCard ?? cards.first).colors.first;

    final label = activeCard != null
        ? l10n.kkGecisHesabaDon(owner.name)
        : single
            ? l10n.kkGecisKartaGec(cards.first.name)
            : l10n.kkGecisKartSec(cards.length);

    return Semantics(
      button: true,
      selected: activeCard != null,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('card-switcher'),
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            onTap: () {
              if (!single) return _openSheet(context);
              _select(context, activeCard == null ? cards.first : owner);
            },
            onLongPress: () => _openSheet(context),
            child: AnimatedContainer(
              duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                // Kart seçiliyken DOLU beyaz: "şu an karttasın".
                color: Colors.white
                    .withValues(alpha: activeCard != null ? 0.95 : 0.2),
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    size: 24,
                    color: activeCard != null ? tint : Colors.white,
                  ),
                  if (activeCard != null)
                    const Positioned(
                      right: 5,
                      bottom: 5,
                      child: _Badge(
                        key: ValueKey('card-switcher-active'),
                        child: Icon(Icons.check_rounded,
                            size: 10, color: Colors.white),
                      ),
                    )
                  else if (!single)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: _Badge(
                        child: Text(
                          '${cards.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
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

class _Badge extends StatelessWidget {
  final Widget child;
  const _Badge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

/// Hesap + kartlarının seçim sayfası: her satır büyük bir dokunma hedefi;
/// kartlarda toplam borç ve dönem durumu yazar. Dokunmak seçer ve kapatır.
class CardSwitchSheet extends StatelessWidget {
  final WalletEntity owner;
  final List<WalletEntity> cards;
  final String? activeId;

  const CardSwitchSheet({
    super.key,
    required this.owner,
    required this.cards,
    required this.activeId,
  });

  static Future<void> show(
    BuildContext context, {
    required WalletEntity owner,
    required List<WalletEntity> cards,
    required String? activeId,
  }) {
    // Sayfa kendi rotasında açılır; cüzdan bloc'u onun üstünde değildir.
    final bloc = context.read<WalletBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CardSwitchSheet(owner: owner, cards: cards, activeId: activeId),
      ),
    );
  }

  void _select(BuildContext context, WalletEntity target) {
    Navigator.of(context).pop();
    if (target.id == null || target.id == activeId) return;
    context.read<WalletBloc>().add(SetActiveWalletEvent(
          userId: target.userId,
          walletId: target.id!,
          announce: false,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ownerActive = owner.id == activeId;
    final money =
        MoneyWriter(currency: owner.currency, visible: context.amountsVisible);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 16).plusSystemBottom(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.kkGecisBaslik,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(l10n.kkGecisAciklama,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 14),
            // Hesabın kendisi.
            Semantics(
              button: true,
              selected: ownerActive,
              child: Material(
                color: ownerActive
                    ? cs.primary.withValues(alpha: 0.10)
                    : cs.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: ValueKey('card-switch-${owner.id}'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _select(context, owner),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ownerActive ? cs.primary : cs.outlineVariant,
                        width: ownerActive ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.getIconData(owner.iconName),
                            color: WalletColors.hexToColor(owner.colorHex)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                owner.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              Text(
                                l10n.kkGecisHesap,
                                style: TextStyle(
                                    fontSize: 11, color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          money(owner.balance),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        if (ownerActive) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded,
                              size: 20, color: cs.primary),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CardsStatusBuilder(
              cards: cards,
              builder: (context, statuses, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final card in cards) ...[
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        MiniCreditCard(
                          key: ValueKey('card-switch-${card.id}'),
                          card: card,
                          active: card.id == activeId,
                          onTap: () => _select(context, card),
                        ),
                        if (card.id == activeId)
                          const Positioned(
                            top: 6,
                            right: 8,
                            child: IgnorePointer(
                              child: Icon(Icons.check_circle_rounded,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        // Çip kalan genişliği alır, "Ayrıntılar" her satırda
                        // SAĞA yaslanır. (`Flexible` + `Spacer` boşluğu ikiye
                        // bölüyor, düğme çipin genişliğine göre satırdan
                        // satıra kayıyordu — cihazda görüldü.)
                        if (statuses[card.id] case final status?)
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: CardDueChip(status: status),
                            ),
                          )
                        else
                          const Spacer(),
                        TextButton(
                          key: ValueKey('card-switch-details-${card.id}'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            // Ayrıntı, seçim sayfasının YERİNE açılır: sayfa
                            // üstüne sayfa yığılmasın. Bloc bu sayfadan
                            // taşınır — gezginin bağlamında yoktur.
                            final navigator = Navigator.of(context);
                            final bloc = context.read<WalletBloc>();
                            navigator.pop();
                            showModalBottomSheet<void>(
                              context: navigator.context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              showDragHandle: true,
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: CardDetailsSheet(card: card),
                              ),
                            );
                          },
                          child: Text(l10n.kkGecisAyrintilar),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
