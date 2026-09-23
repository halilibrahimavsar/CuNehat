import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/credit_card/presentation/card_statement_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_setup_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/widgets/transfer_sheet.dart';

/// Borç sayfasının "Kredi kartları" sekmesi: kullanıcının TÜM kart
/// cüzdanları (aktif cüzdandan bağımsız), her biri için dönem borcu, son
/// ödeme, asgari, limit ve eylemler.
class CreditCardsTab extends StatelessWidget {
  final String userId;

  /// Yeni kartın birimi (ödeme cüzdanı seçilmezse).
  final String defaultCurrency;

  const CreditCardsTab({
    super.key,
    required this.userId,
    required this.defaultCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WalletBloc>().state;
    final wallets =
        state is WalletLoadedSt ? state.wallets : const <WalletEntity>[];
    final cards = [
      for (final w in wallets)
        if (w.isCreditCard && w.id != null) w,
    ];
    final convertible = [
      for (final w in wallets)
        if (!w.isCreditCard && w.id != null) w,
    ];
    final l10n = context.l10n;

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => CreditCardSetupSheet.show(
            context,
            userId: userId,
            wallets: wallets,
            defaultCurrency: defaultCurrency,
          ),
          icon: const Icon(Icons.add_card_rounded),
          label: Text(l10n.kkKartEkle),
        ),
        if (convertible.length > 1)
          TextButton(
            onPressed: () => _convert(context, wallets, convertible),
            child: Text(l10n.kkMevcutCevir),
          ),
      ],
    );

    if (cards.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Icon(Icons.credit_card_rounded,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            l10n.kkBosBaslik,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(l10n.kkBosAciklama, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          actions,
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final card in cards)
          CreditCardTile(
            key: ValueKey('card-${card.id}'),
            card: card,
            wallets: wallets,
          ),
        const SizedBox(height: 8),
        actions,
      ],
    );
  }

  Future<void> _convert(
    BuildContext context,
    List<WalletEntity> wallets,
    List<WalletEntity> convertible,
  ) async {
    final picked = await showModalBottomSheet<WalletEntity>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                context.l10n.kkCevirBaslik,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final w in convertible)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(w.name),
                subtitle: Text(formatMoney(w.balance, currency: w.currency)),
                onTap: () => Navigator.of(sheet).pop(w),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    await CreditCardSetupSheet.show(
      context,
      userId: userId,
      wallets: wallets,
      wallet: picked,
      defaultCurrency: defaultCurrency,
    );
  }
}

/// Tek kartın kutusu: durum defterden canlı türetilir (defter değişince
/// yeniden okunur).
class CreditCardTile extends StatefulWidget {
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
  State<CreditCardTile> createState() => _CreditCardTileState();
}

class _CreditCardTileState extends State<CreditCardTile> {
  List<TransactionEntity>? _ledger;
  StreamSubscription<TransactionsChange>? _changes;

  @override
  void initState() {
    super.initState();
    _load();
    if (getIt.isRegistered<TransactionsChangedNotifier>()) {
      _changes = getIt<TransactionsChangedNotifier>().stream.listen((c) {
        if (c.walletId == null || c.walletId == widget.card.id) _load();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CreditCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Bakiye değiştiyse defter de değişmiştir (transfer, harcama).
    if (oldWidget.card.balance != widget.card.balance) _load();
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!getIt.isRegistered<TransactionsRepository>()) return;
    final result = await getIt<TransactionsRepository>().getTransactions(
      userId: widget.card.userId,
      walletId: widget.card.id!,
    );
    if (!mounted) return;
    setState(() => _ledger = result.getOrElse(() => const []));
  }

  CardStatus? get _status {
    final ledger = _ledger;
    final info = widget.card.creditCard;
    if (ledger == null || info == null) return null;
    return computeCardStatus(
      card: info,
      openingBalance: widget.card.openingBalance,
      walletCreatedAt: widget.card.createdAt,
      ledger: ledger,
      today: widget.today ?? DateTime.now(),
    );
  }

  String _money(double v) => formatMoney(v, currency: widget.card.currency);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final card = widget.card;
    final info = card.creditCard!;
    final status = _status;

    final subtitle = [
      if (info.bankName != null) info.bankName!,
      if (info.last4 != null) '•••• ${info.last4}',
    ].join(' · ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card_rounded, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (status != null) _dueChip(context, status),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 12),
          if (status == null)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Text(l10n.kkKalanDonemBorcu, style: theme.textTheme.bodySmall),
            Text(
              _money(status.remainingStatementDebt),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: status.isOverdue ? cs.error : cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _row(l10n.kkDonemBorcu, _money(status.statementDebt)),
            if (status.remainingMinimum != null)
              _row(l10n.kkKalanAsgari, _money(status.remainingMinimum!)),
            _row(l10n.kkToplamBorc, _money(status.currentDebt)),
            if (status.availableLimit != null)
              _row(l10n.kkKullanilabilirLimit, _money(status.availableLimit!)),
            if (status.futureInstallments > 0)
              _row(l10n.kkKalanTaksit, _money(status.futureInstallments)),
            _row(
              l10n.kkSonrakiKesimEtiket,
              AppFormatters.dateShort.format(status.nextClosing),
            ),
            ..._notes(context, status),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: status == null ? null : () => _pay(context, status),
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
                onPressed: () => _openCard(context),
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: Text(l10n.kkHarcamalar),
              ),
              TextButton.icon(
                onPressed: () => CreditCardSetupSheet.show(
                  context,
                  userId: card.userId,
                  wallets: widget.wallets,
                  wallet: card,
                  defaultCurrency: card.currency,
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(l10n.kkAyarlar),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
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

  Widget _dueChip(BuildContext context, CardStatus s) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final paid = !s.isOverdue && s.remainingStatementDebt <= 0;
    final text = paid
        ? l10n.kkSonOdeme(AppFormatters.dateShort.format(s.dueDate))
        : s.daysToDue > 0
            ? l10n.kkGunKaldi(s.daysToDue)
            : s.daysToDue == 0
                ? l10n.kkBugunSonGun
                : l10n.kkGecikti(-s.daysToDue);
    final color = s.isOverdue
        ? cs.error
        : (!paid && s.daysToDue <= 3 ? Colors.orange : cs.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  List<Widget> _notes(BuildContext context, CardStatus s) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final gap = s.reconciliationGap;
    final String? note;
    if (gap != null) {
      note = l10n.kkFarkUyarisi(_money(gap.abs()));
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

  void _pay(BuildContext context, CardStatus status) {
    final l10n = context.l10n;
    final card = widget.card;
    final payers = [
      for (final w in widget.wallets)
        if (w.id != null && w.id != card.id && !w.isCreditCard) w,
    ];
    if (payers.isEmpty) {
      AppMessenger.info(l10n.kkOdemeIcinCuzdanYok);
      return;
    }
    final preferred = card.creditCard?.paymentWalletId;
    final from = payers.firstWhere(
      (w) => w.id == preferred,
      orElse: () => payers.first,
    );
    TransferSheet.show(
      context,
      wallets: [...payers, card],
      initialFrom: from,
      initialTo: card,
      amountSuggestions: [
        if (status.remainingStatementDebt > 0)
          TransferAmountSuggestion(
            label: l10n.kkKalanDonemBorcu,
            amount: status.remainingStatementDebt,
          ),
        if ((status.remainingMinimum ?? 0) > 0)
          TransferAmountSuggestion(
            label: l10n.kkKalanAsgari,
            amount: status.remainingMinimum!,
          ),
      ],
    );
  }

  void _openCard(BuildContext context) {
    final card = widget.card;
    context.read<WalletBloc>().add(SetActiveWalletEvent(
          userId: card.userId,
          walletId: card.id!,
        ));
    AppMessenger.info(context.l10n.kkKartAktifOldu(card.name));
  }
}
