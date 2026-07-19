// lib/features/recurring_transactions/presentation/widgets/pending_recurring_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import '../bloc/pending_recurring_bloc.dart';
import '../bloc/pending_recurring_event.dart';
import '../bloc/pending_recurring_state.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

class PendingRecurringDialog extends StatelessWidget {
  const PendingRecurringDialog({super.key});

  static void showIfPending(BuildContext context) {
    final bloc = context.read<PendingRecurringBloc>();

    // Yalnızca bir kere göstermek için state'i kontrol et
    if (bloc.state is PendingRecurringInitial) {
      bloc.add(LoadPendingTransactionsEvent());
    }

    // Listener ile takip edip dialog'u açacağız
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PendingRecurringBloc, PendingRecurringState>(
      buildWhen: (previous, current) => current is PendingRecurringLoaded,
      builder: (context, state) {
        if (state is PendingRecurringLoaded &&
            state.pendingTransactions.isNotEmpty) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      size: 48, color: Colors.orangeAccent),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.bekleyenDuzenliIslemler,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.vadesiGelmisIslemlerinizVar,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.pendingTransactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = state.pendingTransactions[index];
                        final dateStr = DateFormat('dd MMM yyyy')
                            .format(tx.nextExecutionDate);
                        // Diyalog tüm cüzdanların vadesi gelen işlemlerini
                        // kapsar; kalem hangi cüzdana işlenecekse onu göster.
                        final wallet = context.walletById(tx.walletId);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (wallet != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 14,
                                        color: Colors.grey.shade700),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        wallet.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.titleTarihDatestrNtutarTx(
                                  dateStr,
                                  formatMoney(tx.amount,
                                      currency: wallet?.currency ??
                                          kDefaultCurrency),
                                ),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      context
                                          .read<PendingRecurringBloc>()
                                          .add(DeleteTransactionEvent(tx.id));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.blue),
                                    onPressed: () {
                                      _showEditDialog(context, tx);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next_outlined,
                                        color: Colors.orange),
                                    tooltip: context.l10n.tooltipBuVadeyiAtla,
                                    onPressed: () {
                                      context
                                          .read<PendingRecurringBloc>()
                                          .add(SkipTransactionEvent(tx));
                                    },
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      context
                                          .read<PendingRecurringBloc>()
                                          .add(ApproveTransactionEvent(tx));
                                    },
                                    child: Text(context.l10n.onayla),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.kapat),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

void _showEditDialog(BuildContext context, RecurringTransactionEntity tx) {
  final bloc = context.read<PendingRecurringBloc>();
  final amountController =
      TextEditingController(text: formatAmountForInput(tx.amount));
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.islemiDuzenle),
      content: TextField(
        controller: amountController,
        decoration: InputDecoration(labelText: context.l10n.labelYeniTutar),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [AmountInputFormatter()],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.iptal),
        ),
        FilledButton(
          onPressed: () {
            final newAmount = parseMoneyInput(amountController.text) ?? tx.amount;
            if (newAmount > 0) {
              // Tutar yalnızca bu vade için geçerli; şablon değişmez.
              bloc.add(ApproveTransactionEvent(tx, overrideAmount: newAmount));
              Navigator.pop(ctx);
            }
          },
          child: Text(context.l10n.kaydetVeOnayla),
        ),
      ],
    ),
  );
}
