import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/credit_card/presentation/card_pay_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/card_statement_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/card_status.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_tile.dart';
import 'package:cunehat/features/credit_card/presentation/mini_credit_card.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
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
  /// Yalnız hap satırı: durum şeridi/bantlar ve tanıtım turu YOK.
  ///
  /// İçgörü ve Rapor'da kullanılır. Oradaki iş bağlamı göstermek ve kart
  /// değiştirmek; borç/ödeme şeridi yapışkan bölgeyi ekranın ~%45'ine
  /// çıkarıyordu (cihazda ölçüldü). Tanıtım turunun anahtarı bir GlobalKey:
  /// dikey geçişte İşlemler'deki şeritle alt sayfadaki aynı anda ağaçta
  /// olur, iki kopya aynı anahtarı taşıyamaz.
  final bool pillsOnly;

  const CardContextRail({super.key, this.pillsOnly = false});

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

    Widget pills() => SingleChildScrollView(
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
              );

    if (pillsOnly) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: pills(),
      );
    }

    return OnboardingTour(
      flow: OnboardingFlow.cardRail,
      keys: [OnboardingKeys.cardRail],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Showcase(
              key: OnboardingKeys.cardRail,
              title: context.l10n.onboardingCardRailTitle,
              description: context.l10n.onboardingCardRailDesc,
              child: pills(),
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
                    ? _DueBands(
                        key: const ValueKey('ctx-due-bands'),
                        cards: cards,
                        wallets: state.wallets,
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
              builder: (context, status) {
                // Kart son kesimden SONRA eklendi ve bu dönemin ekstresi
                // girilmedi: dönem borcu defterden çıkarılamaz (açılış borcu
                // tahmindir). Tutar "≈" ile soluk yazılır ve ekstreyi girme
                // yolu şeridin kendisinde sunulur — not eskiden yalnız
                // ayrıntı sayfasındaydı, şerit kesinmiş gibi görünüyordu.
                final guessed = status != null &&
                    status.declared == null &&
                    !status.derivedReliable;
                // Ekstre ödendiyse (ve tahmin değilse) "Kalan dönem borcu
                // 0,00" yerine bir sonraki ekstreye girecek harcama yazılır.
                // Başlıktaki "BORÇ 1.200" ile şeritteki "0,00" yan yana iki
                // açıklamasız borç sayısıydı; şimdi biri toplam, öbürü bu
                // dönemin harcaması.
                final cycleView = status != null &&
                    !guessed &&
                    !moneyIsPositive(status.remainingStatementDebt);
                final shownAmount = status == null
                    ? null
                    : cycleView
                        ? status.spentSinceClosing
                        : status.remainingStatementDebt;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cycleView
                                ? l10n.kkBuDonemHarcanan
                                : l10n.kkKalanDonemBorcu,
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
                                shownAmount == null
                                    ? '…'
                                    : '${guessed ? '≈ ' : ''}${MoneyWriter(currency: card.currency, visible: context.amountsVisible)(shownAmount)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: guessed
                                      ? cs.onSurfaceVariant
                                      : (status?.isOverdue ?? false)
                                          ? cs.error
                                          : cs.onSurface,
                                ),
                              ),
                              if (status != null) CardDueChip(status: status),
                              if (guessed)
                                ActionChip(
                                  key: const ValueKey('ctx-card-statement'),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  avatar: const Icon(Icons.receipt_long_rounded,
                                      size: 16),
                                  label: Text(l10n.kkEkstreyiGir),
                                  onPressed: () => CardStatementSheet.show(
                                    context,
                                    card: card,
                                    status: status,
                                  ),
                                ),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Hesap bağlamında yaklaşan kart ödemeleri: kalan dönem borcu olan ve son
/// ödemesine [dueSoonDays] gün ya da daha az kalmış (veya gecikmiş) her kart
/// için ince bir bant. Kullanıcı çoğu zaman kartta değil hesapta durur;
/// son ödeme bilgisi yalnız kart bağlamında görünseydi kaçardı.
class _DueBands extends StatelessWidget {
  final List<WalletEntity> cards;
  final List<WalletEntity> wallets;

  const _DueBands({super.key, required this.cards, required this.wallets});

  static const int dueSoonDays = 3;

  @override
  Widget build(BuildContext context) {
    return CardsStatusBuilder(
      cards: cards,
      builder: (context, statuses, _) {
        final due = [
          for (final c in cards)
            if (statuses[c.id] case final s?
                when s.remainingStatementDebt > 0 &&
                    (s.isOverdue || s.daysToDue <= dueSoonDays))
              (card: c, status: s),
        ];
        if (due.isEmpty) return const SizedBox(width: double.infinity);
        return Column(
          children: [
            for (final d in due)
              _DueBand(
                key: ValueKey('ctx-due-${d.card.id}'),
                card: d.card,
                status: d.status,
                wallets: wallets,
              ),
          ],
        );
      },
    );
  }
}

class _DueBand extends StatelessWidget {
  final WalletEntity card;
  final CardStatus status;
  final List<WalletEntity> wallets;

  const _DueBand({
    super.key,
    required this.card,
    required this.status,
    required this.wallets,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = status.isOverdue ? cs.error : Colors.orange.shade800;
    final last4 = card.creditCard?.last4;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tone.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 18, color: tone),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    last4 == null ? card.name : '${card.name} ••$last4',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  CardDueChip(status: status),
                  Text(
                    // Göz düğmesi bu tutarı da gizlemeli: `formatMoney`
                    // doğrudan çağrılınca şerit gizliyken açık kalıyordu.
                    MoneyWriter(
                      currency: card.currency,
                      visible: context.amountsVisible,
                    )(status.remainingStatementDebt),
                    style: TextStyle(fontWeight: FontWeight.w900, color: tone),
                  ),
                ],
              ),
            ),
            TextButton(
              key: ValueKey('ctx-due-pay-${card.id}'),
              onPressed: () => payCreditCard(context,
                  card: card, wallets: wallets, status: status),
              child: Text(context.l10n.kkOde),
            ),
          ],
        ),
      ),
    );
  }
}
