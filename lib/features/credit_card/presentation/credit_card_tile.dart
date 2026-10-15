import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/credit_card/presentation/card_pay_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/installments.dart';
import 'package:cunehat/features/credit_card/presentation/card_statement_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/card_status.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_setup_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/mini_credit_card.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

/// Son ödeme çipi: "5 gün kaldı" / "Son gün bugün" / "3 gün gecikti" /
/// asgarisi ödenip kalanı devreden ekstrede "Asgari ödendi" / ödenecek bir
/// şey kalmadıysa "Sonraki kesim: 15 Eki". Son 3 gün turuncu, gecikme
/// kırmızı.
///
/// Ödenmiş dönemde eskiden "Son ödeme: 25.09" yazıyordu: 9 Ekim'de geçmiş
/// bir tarih, kullanıcıya bir şey kaçırmış gibi okunuyordu. Ödeme bittiyse
/// sıradaki olay bir sonraki kesimdir.
class CardDueChip extends StatelessWidget {
  final CardStatus status;

  const CardDueChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final s = status;
    final paid = !s.isOverdue && s.remainingStatementDebt <= 0;
    final text = paid
        // Ay adıyla: "15.10.26" gün/ay sırası belirsiz okunuyordu ve dar
        // satırda ikiye kırılıyordu.
        ? l10n.kkSonrakiKesim(AppFormatters.dayMonth.format(s.nextClosing))
        : s.isCarrying
            ? l10n.kkAsgariOdendi
            : s.daysToDue > 0
                ? l10n.kkGunKaldi(s.daysToDue)
                : s.daysToDue == 0
                    ? l10n.kkBugunSonGun
                    : l10n.kkGecikti(-s.daysToDue);
    final color = s.isOverdue
        ? cs.error
        : (!paid && !s.isCarrying && s.daysToDue <= 3
            ? Colors.orange
            : cs.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Kartın ayrıntı kutusu: kalan dönem borcu, dönem borcu, asgari, toplam
/// borç, limit, taksitler, sonraki kesim + eylemler (Öde, Ekstre bilgisi,
/// Ayarlar). Kart ayrıntı sayfasının gövdesi.
class CreditCardTile extends StatelessWidget {
  final WalletEntity card;
  final List<WalletEntity> wallets;

  /// "Bugün" — test edilebilirlik için.
  final DateTime? today;

  const CreditCardTile({
    super.key,
    required this.card,
    required this.wallets,
    this.today,
  });

  @override
  Widget build(BuildContext context) {
    return CardStatusBuilder(
      card: card,
      today: today,
      builder: (context, status) => _body(context, status),
    );
  }

  String _money(double v) => formatMoney(v, currency: card.currency);

  Widget _body(BuildContext context, CardStatus? status) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status == null)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.kkKalanDonemBorcu,
                        style: theme.textTheme.bodySmall),
                    // Rakam değişince yumuşak geçiş (karta ödeme sonrası).
                    if (!status.statementKnown)
                      Text(
                        l10n.kkBilinmiyor,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    else
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: status.remainingStatementDebt),
                        duration:
                            (MediaQuery.maybeDisableAnimationsOf(context) ??
                                    false)
                                ? Duration.zero
                                : const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => Text(
                          _money(v),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: status.isOverdue ? cs.error : cs.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CardDueChip(status: status),
              ),
            ],
          ),
          if (status.availableLimit != null && card.creditCard?.limit != null)
            _LimitBar(
              used: card.creditCard!.limit! - status.availableLimit!,
              limit: card.creditCard!.limit!,
              money: _money,
            ),
          const SizedBox(height: 8),
          _row(
              context,
              l10n.kkDonemBorcu,
              status.statementKnown
                  ? _money(status.statementDebt)
                  : l10n.kkBilinmiyor),
          if (status.remainingMinimum != null)
            _row(context, l10n.kkKalanAsgari, _money(status.remainingMinimum!)),
          _row(context, l10n.kkToplamBorc, _money(status.currentDebt)),
          if (status.availableLimit != null)
            _row(context, l10n.kkKullanilabilirLimit,
                _money(status.availableLimit!)),
          if (status.futureInstallments > 0)
            _row(
                context, l10n.kkKalanTaksit, _money(status.futureInstallments)),
          // Kalan taksitlerin hangi alışverişlerden geldiği: eskiden yalnız
          // tek bir toplam vardı ("Kalan taksitler 4.000 ₺ — neyin?").
          if (status.installmentPlans.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(l10n.kkTaksitliAlisverisler,
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            for (final plan in status.installmentPlans)
              _row(
                context,
                installmentBaseTitle(plan.items.first.title),
                l10n.kkTaksitPlanSatiri(
                  plan.left,
                  _money(plan.remaining),
                ),
              ),
          ],
          _row(
            context,
            l10n.kkSonrakiKesimEtiket,
            AppFormatters.dayMonthYear.format(status.nextClosing),
          ),
          ..._interestNotes(context, status),
          ..._notes(context, status),
        ],
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: [
            TextButton.icon(
              onPressed: status == null
                  ? null
                  : () => payCreditCard(context,
                      card: card, wallets: wallets, status: status),
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: Text(l10n.kkOde),
            ),
            TextButton.icon(
              onPressed: status == null
                  ? null
                  : () => CardStatementSheet.show(
                        context,
                        card: card,
                        status: status,
                      ),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(l10n.kkEkstreBilgisi),
            ),
            TextButton.icon(
              onPressed: () => CreditCardSetupSheet.show(
                context,
                userId: card.userId,
                wallets: wallets,
                wallet: card,
                defaultCurrency: card.currency,
              ),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(l10n.kkAyarlar),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// Faiz TAHMİNİ (oran kart ayarlarında girildiyse): dönem borcundan ödenecek
  /// bir şey varken "yalnız asgariyi ödersen" ve gecikmedeyse gecikme faizi.
  List<Widget> _interestNotes(BuildContext context, CardStatus s) {
    final l10n = context.l10n;
    final info = card.creditCard;
    if (info == null || !moneyIsPositive(s.remainingStatementDebt)) {
      return const [];
    }
    final minimum = s.remainingMinimum;
    final carry = estimateCarryInterest(
      remainingStatementDebt: s.remainingStatementDebt,
      // Asgari bilinmiyorsa "hiç ödenmezse" tahmini.
      payment: minimum ?? 0,
      monthlyRatePercent: info.monthlyInterestRate,
    );
    final late = s.isOverdue
        ? estimateLateInterest(
            overdueMinimum: minimum,
            lateRatePercent: info.lateInterestRate,
          )
        : null;
    final lines = <String>[
      if (carry != null)
        minimum == null
            ? l10n.kkFaizTahminiOdenmezse(
                _money(carry.carried), _money(carry.interest))
            : l10n.kkFaizTahminiAsgari(
                _money(carry.carried), _money(carry.interest)),
      if (late != null && minimum != null)
        l10n.kkGecikmeFaiziTahmini(_money(minimum), _money(late)),
    ];
    if (lines.isEmpty) return const [];
    final theme = Theme.of(context);
    return [
      Padding(
        key: const ValueKey('kk-interest-estimate'),
        padding: const EdgeInsets.only(top: 6, right: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.percent_rounded,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(lines.join('\n'), style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _notes(BuildContext context, CardStatus s) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final gap = s.reconciliationGap;
    final String? note;
    if (gap != null) {
      // Yön söylenir: beyan defterden büyükse kartta yazılmamış harcama,
      // küçükse çift ya da bu ekstreye girmeyen kayıt aranır. Eskiden iki
      // durum aynı "eksik ya da fazla" cümlesini alıyordu (smoke C-40/41).
      note = gap > 0
          ? l10n.kkFarkUyarisiEksik(_money(gap))
          : l10n.kkFarkUyarisiFazla(_money(-gap));
    } else if (s.declared == null && !s.derivedReliable) {
      note = l10n.kkDefterGuvenilmez;
    } else if (s.declared == null) {
      note = l10n.kkEkstreGirilmedi;
    } else {
      note = null;
    }
    if (note == null) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6, right: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(child: Text(note, style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    ];
  }
}

/// Limit kullanım çubuğu; açılışta 0'dan dolar. %80 üstü turuncu, aşımda
/// kırmızı.
class _LimitBar extends StatelessWidget {
  final double used;
  final double limit;

  /// Kartın para biriminde biçimleyici (erişilebilirlik değeri için).
  final String Function(double) money;

  const _LimitBar({
    required this.used,
    required this.limit,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final color = used > limit
        ? cs.error
        : ratio >= 0.8
            ? Colors.orange
            : cs.primary;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          // Etiketsiz çubuk ekran okuyucuda yalnız "7" diye okunuyordu.
          // İlerleme çubuğunun kendi semanticsValue'su yalnız SAYI kabul
          // ediyor; etiket ve tutarlar dıştaki düğüme yazılır.
          child: Semantics(
            label: context.l10n.kkLimitKullanimi,
            value: '${formatPercent(ratio * 100)} · '
                '${money(used)} / ${money(limit)}',
            excludeSemantics: true,
            child: LinearProgressIndicator(
              value: v,
              minHeight: 6,
              color: color,
              backgroundColor: cs.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kart ayrıntı sayfası: üstte kartın kendisi, altında [CreditCardTile] ve
/// "Kartı sil".
class CardDetailsSheet extends StatelessWidget {
  final WalletEntity card;

  const CardDetailsSheet({super.key, required this.card});

  static Future<void> show(BuildContext context, {required WalletEntity card}) {
    final bloc = context.read<WalletBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: CardDetailsSheet(card: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Canlı: ödeme/ayar değişince sayfa açıkken de tazelenir.
    final state = context.watch<WalletBloc>().state;
    final wallets =
        state is WalletLoadedSt ? state.wallets : const <WalletEntity>[];
    final live = wallets.where((w) => w.id == card.id).firstOrNull;
    if (live == null || !live.isCreditCard) {
      // Silindi ya da karttan çıkarıldı.
      return const SizedBox(height: 120);
    }
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MiniCreditCard(card: live, height: 84),
            const SizedBox(height: 16),
            CreditCardTile(card: live, wallets: wallets),
            const Divider(height: 24),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () =>
                  deleteCreditCard(context, card: live, closeSheet: true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(context.l10n.kkKartiSil),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartı (cüzdanını ve defterini) iki adımlı onayla siler. Kart aktif
/// bağlamsa önce sahibine geçilir — aktif cüzdan silinemez. [closeSheet]
/// ise silmeden sonra çağıranın sayfası (kart ayrıntısı) kapatılır.
Future<void> deleteCreditCard(
  BuildContext context, {
  required WalletEntity card,
  bool closeSheet = false,
}) async {
  final l10n = context.l10n;
  final bloc = context.read<WalletBloc>();
  final navigator = Navigator.of(context);
  final step1 = await ConfirmDialog.show(
    context,
    title: l10n.kkKartiSil,
    message: l10n.deleteWalletConfirmMessage(card.name),
    confirmText: l10n.sil,
  );
  if (!step1 || !context.mounted) return;
  final step2 = await ConfirmDialog.show(
    context,
    title: l10n.irreversibleActionTitle,
    message: l10n.deleteWalletDangerMessage(card.name),
    confirmText: l10n.sil,
    danger: true,
    countdownSeconds: 5,
  );
  if (!step2 || !context.mounted) return;

  final state = bloc.state;
  if (state is WalletLoadedSt && state.activeWallet?.id == card.id) {
    final owner = cardOwner(card, state.wallets) ??
        state.wallets
            .where((w) => w.id != card.id && !w.isCreditCard)
            .firstOrNull;
    if (owner == null) return;
    bloc.add(SetActiveWalletEvent(userId: card.userId, walletId: owner.id!));
    // Olaylar eşzamanlı işlenir: silme, aktif değişimi yazıldıktan SONRA.
    await bloc.stream
        .firstWhere(
            (s) => s is WalletLoadedSt && s.activeWallet?.id == owner.id)
        .timeout(const Duration(seconds: 5), onTimeout: () => bloc.state);
  }
  bloc.add(DeleteWalletEvent(card.id!));
  if (closeSheet && navigator.canPop()) navigator.pop();
}
