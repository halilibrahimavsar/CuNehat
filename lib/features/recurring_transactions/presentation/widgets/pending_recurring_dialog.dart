// lib/features/recurring_transactions/presentation/widgets/pending_recurring_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/pending_recurring_bloc.dart';
import '../bloc/pending_recurring_event.dart';
import '../bloc/pending_recurring_state.dart';

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
                  const Text(
                    'Bekleyen Düzenli İşlemler',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vadesi gelmiş işlemleriniz var. Onaylayarak deftere işlenmesini sağlayabilirsiniz.',
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
                              Text('Tarih: $dateStr\nTutar: ${tx.amount}'),
                          trailing: ElevatedButton(
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
                            child: const Text('Onayla'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kapat'),
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
