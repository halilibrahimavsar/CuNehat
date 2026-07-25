// lib/features/recurring_transactions/presentation/widgets/pending_recurring_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import '../../domain/services/recurring_occurrences.dart';
import '../bloc/pending_recurring_bloc.dart';
import '../bloc/pending_recurring_event.dart';
import '../bloc/pending_recurring_state.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

/// Vadesi gelmiş düzenli işlemlerin onay diyaloğu.
///
/// Kapatma nedenini çağırana bildirir: kullanıcı "Kapat"a bastıysa `true`
/// döner ve HomePage aynı bekleyen küme için diyaloğu tekrar açmaz.
class PendingRecurringDialog extends StatelessWidget {
  const PendingRecurringDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<PendingRecurringBloc, PendingRecurringState>(
      // Son kalem onaylanınca diyalog kendini kapatır. `Navigator.pop`
      // yığının EN ÜSTÜNDEKİ route'u atar — araya başka bir diyalog girdiyse
      // yanlış olanı kapatırdı; removeRoute tam olarak bu route'u kaldırır.
      listenWhen: (_, current) =>
          current is PendingRecurringLoaded &&
          current.pendingTransactions.isEmpty,
      listener: (context, _) {
        final route = ModalRoute.of(context);
        if (route != null && route.isActive) {
          Navigator.of(context).removeRoute(route);
        }
      },
      child: BlocBuilder<PendingRecurringBloc, PendingRecurringState>(
        buildWhen: (previous, current) => current is PendingRecurringLoaded,
        builder: (context, state) {
          if (state is! PendingRecurringLoaded ||
              state.pendingTransactions.isEmpty) {
            return const SizedBox.shrink();
          }

          return AppDialogSurface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_active_rounded,
                    size: 44, color: scheme.primary),
                const SizedBox(height: 12),
                Text(
                  context.l10n.bekleyenDuzenliIslemler,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.vadesiGelmisIslemlerinizVar,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.pendingTransactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = state.pendingTransactions[index];
                      return _PendingRow(
                        template: tx,
                        busy: state.busyTemplateIds.contains(tx.id),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.l10n.kapat),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final RecurringTransactionEntity template;
  final bool busy;

  const _PendingRow({required this.template, required this.busy});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    // Diyalog tüm cüzdanların vadesi gelen işlemlerini kapsar; kalem hangi
    // cüzdana işlenecekse onu göster.
    final wallet = context.walletById(template.walletId);
    final backlog = RecurringOccurrences.dueCount(template, DateTime.now());
    final dateStr =
        DateFormat('dd MMM yyyy').format(template.nextExecutionDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  template.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (backlog > 1) _BacklogBadge(count: backlog),
            ],
          ),
          if (wallet != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            l10n.titleTarihDatestrNtutarTx(
              dateStr,
              formatMoney(template.amount,
                  currency: wallet?.currency ?? kDefaultCurrency),
            ),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Yıkıcı eylemler (sil) ve toplu onay taşma menüsünde: satırda
              // yan yana duran çöp kutusu, tek dokunuşla şablonun tamamını
              // siliyordu ve "atla" ile karışıyordu.
              _RowOverflowMenu(
                template: template,
                backlog: backlog,
                enabled: !busy,
              ),
              const Spacer(),
              TextButton(
                onPressed: busy
                    ? null
                    : () => context
                        .read<PendingRecurringBloc>()
                        .add(SkipTransactionEvent(template)),
                child: Text(l10n.buVadeyiAtla),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => context
                        .read<PendingRecurringBloc>()
                        .add(ApproveTransactionEvent(template)),
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.onayla),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BacklogBadge extends StatelessWidget {
  final int count;

  const _BacklogBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.bekleyenVadeSayisi(count),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

enum _RowAction { edit, approveAll, delete }

class _RowOverflowMenu extends StatelessWidget {
  final RecurringTransactionEntity template;
  final int backlog;
  final bool enabled;

  const _RowOverflowMenu({
    required this.template,
    required this.backlog,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return PopupMenuButton<_RowAction>(
      enabled: enabled,
      tooltip: '',
      icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
      onSelected: (action) => _handle(context, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _RowAction.edit,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.islemiDuzenle),
          ),
        ),
        if (backlog > 1)
          PopupMenuItem(
            value: _RowAction.approveAll,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.done_all),
              title: Text(l10n.tumunuOnayla),
            ),
          ),
        PopupMenuItem(
          value: _RowAction.delete,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: scheme.error),
            title: Text(
              l10n.sablonuSil,
              style: TextStyle(color: scheme.error),
            ),
            subtitle: Text(
              l10n.sablonuSilAciklama,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handle(BuildContext context, _RowAction action) async {
    final bloc = context.read<PendingRecurringBloc>();
    final l10n = context.l10n;

    switch (action) {
      case _RowAction.edit:
        await _showEditDialog(context, template);
      case _RowAction.approveAll:
        final confirmed = await ConfirmDialog.show(
          context,
          title: l10n.tumunuOnaylaBaslik,
          message: l10n.tumunuOnaylaAciklama(template.title, backlog),
          confirmText: l10n.tumunuOnayla,
        );
        if (confirmed) bloc.add(ApproveAllOccurrencesEvent(template));
      case _RowAction.delete:
        final confirmed = await ConfirmDialog.show(
          context,
          title: l10n.sablonuSil,
          message: l10n.templateTitleDuzenliIslemi(template.title),
          confirmText: l10n.sil,
          danger: true,
        );
        if (confirmed) bloc.add(DeleteTransactionEvent(template.id));
    }
  }
}

Future<void> _showEditDialog(
  BuildContext context,
  RecurringTransactionEntity template,
) {
  final bloc = context.read<PendingRecurringBloc>();
  final amountController =
      TextEditingController(text: formatAmountForInput(template.amount));

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AppDialogSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dialogContext.l10n.islemiDuzenle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: dialogContext.l10n.labelYeniTutar,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter()],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(dialogContext.l10n.iptal),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final newAmount = parseMoneyInput(amountController.text) ??
                        template.amount;
                    if (newAmount > 0) {
                      // Tutar yalnızca bu vade için geçerli; şablon değişmez.
                      bloc.add(ApproveTransactionEvent(template,
                          overrideAmount: newAmount));
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(dialogContext.l10n.kaydetVeOnayla),
                ),
              ],
            ),
          ],
        ),
      );
    },
  ).whenComplete(amountController.dispose);
}
