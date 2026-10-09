import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/credit_card/presentation/card_pay_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/card_status.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_tile.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

/// Borç sekmesinin başındaki "Kredi kartları" özeti: hesaba bağlı her kartın
/// güncel borcu, ekstre durumu ve "Öde".
///
/// **Neden burada (ve neden sekme DEĞİL):** borç iki yerde tutuluyor — borç
/// modülü (kredi, kişisel borç) ve kartın kendi defteri (eksi bakiye) — ve
/// Borç sekmesi yalnız ilkini gösteriyordu: kart borcu olan kullanıcı
/// "Henüz borç kaydı yok" görüyordu. Önceki "Kredi kartları" SEKMESİ kartı
/// ayrı bir cüzdan gibi yönettirdiği için kaldırılmıştı; bu bölüm salt
/// özettir. Kart verisi düzenlenmez, kayıt eklenmez; satıra dokunmak kartın
/// ayrıntısını açar.
///
/// Kart yoksa ya da bayrak kapalıysa hiç yer kaplamaz.
class CardDebtSummarySection extends StatelessWidget {
  /// Borç sekmesinin hesabı (kart değil, sahibi).
  final String accountId;

  const CardDebtSummarySection({super.key, required this.accountId});

  /// Hesaba bağlı, aynı birimdeki kartlar (Borç sekmesinin toplamıyla aynı
  /// küme; bkz. [debtOverview]).
  static List<WalletEntity> cardsFor(
      String accountId, List<WalletEntity> wallets) {
    final account = wallets.where((w) => w.id == accountId).firstOrNull;
    if (account == null) return const [];
    return [
      for (final c in cardsOf(accountId, wallets))
        if (c.currency == account.currency) c,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.creditCards) return const SizedBox.shrink();
    final WalletState state;
    try {
      state = context.watch<WalletBloc>().state;
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    if (state is! WalletLoadedSt) return const SizedBox.shrink();
    final wallets = state.wallets;
    final cards = cardsFor(accountId, wallets);
    if (cards.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    return CardsStatusBuilder(
      cards: cards,
      builder: (context, statuses, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.kkSekme,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.debtCardsSectionHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final c in cards)
            _CardDebtRow(
              key: ValueKey('debt-card-${c.id}'),
              card: c,
              status: statuses[c.id],
              wallets: wallets,
            ),
        ],
      ),
    );
  }
}

class _CardDebtRow extends StatelessWidget {
  final WalletEntity card;
  final CardStatus? status;
  final List<WalletEntity> wallets;

  const _CardDebtRow({
    super.key,
    required this.card,
    required this.status,
    required this.wallets,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final money =
        MoneyWriter(currency: card.currency, visible: context.amountsVisible);
    final s = status;
    final debt = card.balance < 0 ? -card.balance : 0.0;
    final last4 = card.creditCard?.last4;
    final due = s != null && moneyIsPositive(s.remainingStatementDebt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        section: AppSection.debt,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        onTap: () => CardDetailsSheet.show(context, card: card),
        child: Row(
          children: [
            Icon(Icons.credit_card_rounded, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          last4 == null ? card.name : '${card.name} ••$last4',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        money(debt),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: debt > 0 ? AppGradients.debt : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (s == null)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          due
                              ? l10n.kkKalanDonemSatiri(
                                  money(s.remainingStatementDebt))
                              : l10n.kkEkstreOdendi,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: s.isOverdue ? cs.error : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CardDueChip(status: s),
                      ],
                    ),
                ],
              ),
            ),
            if (s != null && moneyIsPositive(s.currentDebt)) ...[
              const SizedBox(width: 6),
              FilledButton.tonal(
                key: ValueKey('debt-card-pay-${card.id}'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: () => payCreditCard(context,
                    card: card, wallets: wallets, status: s),
                child: Text(l10n.kkOde),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
