import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/bank_import/data/link_hint.dart';
import 'package:cunehat/features/coupling/presentation/link_transaction_flow.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';

/// İçe aktarım bitiş ekranında: az önce yazılan satırlardan bir kayda
/// (birikim, borç ödemesi, kredi girişi) bağlanmaya aday görünenler, her
/// birinde "Bağla" (bkz. `startLinkTransactionFlow`).
///
/// Satır bağlanınca "Bağlandı" olur: defter değişikliği bildirimiyle
/// satırlar taze okunur (bağlama akışı sonucu kendi bildirir, bu kart yalnız
/// durumu yansıtır).
class LinkSuggestionsCard extends StatefulWidget {
  final List<LinkSuggestion> suggestions;
  final String currency;

  const LinkSuggestionsCard({
    super.key,
    required this.suggestions,
    required this.currency,
  });

  @override
  State<LinkSuggestionsCard> createState() => _LinkSuggestionsCardState();
}

class _LinkSuggestionsCardState extends State<LinkSuggestionsCard> {
  /// Satırın güncel hâli (bağlandı mı); ilk karede yazıldığı hâl.
  late Map<String, TransactionEntity> _current = {
    for (final s in widget.suggestions)
      if (s.transaction.id != null) s.transaction.id!: s.transaction,
  };

  StreamSubscription<TransactionsChange>? _changes;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<TransactionsChangedNotifier>()) {
      _changes =
          getIt<TransactionsChangedNotifier>().stream.listen((_) => _refresh());
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!getIt.isRegistered<TransactionsRepository>()) return;
    final repo = getIt<TransactionsRepository>();
    final next = <String, TransactionEntity>{};
    for (final id in _current.keys) {
      final read = await repo.getTransactionById(id);
      // Silinmiş satır (ör. geri alındı) listeden düşer.
      read.fold((_) {}, (t) => next[id] = t);
    }
    if (mounted) setState(() => _current = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final rows = [
      for (final s in widget.suggestions)
        if (_current[s.transaction.id] case final t?) (t, s.hint),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.bankImportLinkTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child:
                Text(l10n.bankImportLinkBody, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 4),
          for (final (t, hint) in rows) _row(context, t, hint),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, TransactionEntity t, LinkHint hint) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final hintText = switch (hint) {
      LinkHint.investment => l10n.linkHintInvestment,
      LinkHint.debtPayment => l10n.linkHintDebtPayment,
      LinkHint.loanDisbursement => l10n.linkHintLoan,
    };
    final linked = t.isSystem;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '${t.isIncome ? '+' : '−'}'
                  '${formatMoney(t.amount, currency: widget.currency)} · '
                  '${AppFormatters.dateShort.format(t.date)} · $hintText',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (linked)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 4),
                Text(l10n.bankImportLinked,
                    style: TextStyle(color: cs.primary, fontSize: 13)),
                const SizedBox(width: 8),
              ],
            )
          else
            TextButton(
              onPressed: () => startLinkTransactionFlow(
                context,
                transaction: t,
                currency: widget.currency,
              ),
              child: Text(l10n.bankImportLinkButton),
            ),
        ],
      ),
    );
  }
}
