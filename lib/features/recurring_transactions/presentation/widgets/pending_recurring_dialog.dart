// lib/features/recurring_transactions/presentation/widgets/pending_recurring_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final tx = state.pendingTransactions[index];
                        final dateStr = DateFormat('dd MMM yyyy')
                            .format(tx.nextExecutionDate);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tx.title),
                          subtitle:
                              Text(context.l10n.titleTarihDatestrNtutarTx(dateStr, tx.amount.toString())),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  context.read<PendingRecurringBloc>().add(
                                      DeleteTransactionEvent(tx.id));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
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
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
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
  final amountController = TextEditingController(text: tx.amount.toString());
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.islemiDuzenle),
      content: TextField(
        controller: amountController,
        decoration: InputDecoration(labelText: context.l10n.labelYeniTutar),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.iptal),
        ),
        FilledButton(
          onPressed: () {
            final val = amountController.text.replaceAll(',', '.');
            final newAmount = double.tryParse(val) ?? tx.amount;
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
