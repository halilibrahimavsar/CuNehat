import 'package:cunehat/core/shared/widgets/info_action_menu.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DebtAndReceivablePage extends StatefulWidget {
  final String userId;
  final String walletId;
  const DebtAndReceivablePage(
      {super.key, required this.userId, required this.walletId});

  @override
  State<DebtAndReceivablePage> createState() => _DebtAndReceivablePageState();
}

class _DebtAndReceivablePageState extends State<DebtAndReceivablePage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant DebtAndReceivablePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.walletId != oldWidget.walletId) {
      _loadData();
    }
  }

  void _loadData() {
    context.read<DebtBloc>().add(GetDebtsEvent(widget.walletId));
    context.read<ReceivableBloc>().add(GetReceivablesEvent(widget.walletId));
    context.read<WalletBloc>().add(GetWalletsEvent(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Finansal Takip"),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.outbound), text: "Borçlarım"),
              Tab(icon: Icon(Icons.call_received), text: "Alacaklarım"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DebtListSection(walletId: widget.walletId, userId: widget.userId),
            ReceivableListSection(
                walletId: widget.walletId, userId: widget.userId),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context),
              label: const Text("Yeni Ekle"),
              icon: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddEntrySheet(walletId: widget.walletId),
    );
  }
}

// --- BORÇ LİSTESİ BÖLÜMÜ ---
class DebtListSection extends StatelessWidget {
  final String walletId;
  final String userId;
  const DebtListSection({
    super.key,
    required this.walletId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtBloc, DebtState>(
      listener: (context, state) {
        if (state is DebtOperationSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
        } else if (state is DebtError) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is DebtLoading || state is DebtOperationSuccess) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DebtLoaded) {
          if (state.debts.isEmpty) {
            return const Center(child: Text("Henüz borç kaydı yok."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.debts.length,
            itemBuilder: (context, index) {
              final debt = state.debts[index];
              return _buildDebtCard(context, debt);
            },
          );
        } else if (state is DebtError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<DebtBloc>().add(GetDebtsEvent(walletId)),
                  child: const Text("Tekrar Dene"),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDebtCard(BuildContext context, DebtEntity debt) {
    final isOverdue = debt.dueDate != null &&
        debt.dueDate!.isBefore(DateTime.now()) &&
        !debt.isPaid;

    return InfoActionMenu<String>(
      items: [
        const PopupMenuItem(
          value: 'payment',
          child: Row(
            children: [
              Icon(Icons.payment, color: Colors.green),
              SizedBox(width: 8),
              Text("Ödeme Yap", style: TextStyle(color: Colors.green)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text("Düzenle"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text("Sil", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'payment') {
          DebtPaymentDialog.show(context, debt);
        } else if (value == 'edit') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => AddEntrySheet(
              walletId: walletId,
              debtToEdit: debt,
            ),
          );
        } else if (value == 'delete') {
          context.read<DebtBloc>().add(DeleteDebtEvent(
              id: debt.id!,
              userId: debt.userId,
              walletId: debt.walletId,
              amount: debt.totalDebtAmount));
        }
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      isOverdue ? Colors.red.shade100 : Colors.blue.shade100,
                  child: Icon(Icons.account_balance_wallet,
                      color: isOverdue ? Colors.red : Colors.blue),
                ),
                title: Text(debt.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.counterparty),
                    if (isOverdue)
                      Text(
                        'VADESİ GEÇMİŞ!',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(symbol: '₺')
                          .format(debt.remainingAmount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red),
                    ),
                    if (debt.isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ÖDENDİ',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: debt.progress,
                  backgroundColor: Colors.grey.shade200,
                  color: debt.isPaid ? Colors.green : Colors.blue),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      "Vade: ${debt.termMonths} Ay | ${debt.payments.length} Ödeme",
                      style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey)),
                  if (!debt.isPaid)
                    TextButton.icon(
                      onPressed: () => DebtPaymentDialog.show(context, debt),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text("Öde"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- ALACAK LİSTESİ BÖLÜMÜ ---
class ReceivableListSection extends StatelessWidget {
  final String walletId;
  final String userId;
  const ReceivableListSection({
    super.key,
    required this.walletId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceivableBloc, ReceivableState>(
      listener: (context, state) {
        if (state is ReceivableOperationSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
        } else if (state is ReceivableError) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is ReceivableLoading || state is ReceivableOperationSuccess) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ReceivableLoaded) {
          if (state.receivables.isEmpty) {
            return const Center(child: Text("Henüz alacak kaydı yok."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.receivables.length,
            itemBuilder: (context, index) {
              final receivable = state.receivables[index];
              return _buildReceivableCard(context, receivable);
            },
          );
        } else if (state is ReceivableError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .read<ReceivableBloc>()
                      .add(GetReceivablesEvent(walletId)),
                  child: const Text("Tekrar Dene"),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildReceivableCard(
      BuildContext context, ReceivableEntity receivable) {
    final isOverdue =
        receivable.dueDate.isBefore(DateTime.now()) && !receivable.isPaid;

    return InfoActionMenu<String>(
      items: [
        if (!receivable.isPaid)
          const PopupMenuItem(
            value: 'mark_paid',
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text("Ödendi İşaretle", style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text("Düzenle"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text("Sil", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'mark_paid') {
          context
              .read<ReceivableBloc>()
              .add(MarkReceivableAsPaidEvent(receivable));
        } else if (value == 'edit') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => AddEntrySheet(
              walletId: walletId,
              receivableToEdit: receivable,
            ),
          );
        } else if (value == 'delete') {
          context.read<ReceivableBloc>().add(DeleteReceivableEvent(
              id: receivable.id!,
              userId: receivable.userId,
              walletId: receivable.walletId,
              amount: receivable.amount));
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            color: receivable.isPaid
                ? Colors.green.shade50
                : (isOverdue ? Colors.orange.shade50 : Colors.white),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: CircleAvatar(
              backgroundColor: receivable.isPaid
                  ? Colors.green.shade100
                  : (isOverdue ? Colors.orange.shade100 : Colors.blue.shade100),
              child: Icon(
                receivable.isPaid ? Icons.check_circle : Icons.person,
                color: receivable.isPaid
                    ? Colors.green
                    : (isOverdue ? Colors.orange : Colors.blue),
              ),
            ),
            title: Text(
              receivable.debtorName,
              style: TextStyle(
                decoration:
                    receivable.isPaid ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "Vade: ${DateFormat('dd MMM yyyy').format(receivable.dueDate)}"),
                if (isOverdue)
                  Text(
                    'VADESİ GEÇMİŞ!',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                if (receivable.isPaid)
                  Text(
                    'ÖDENDİ',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Text(
                NumberFormat.currency(symbol: '₺').format(receivable.amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: receivable.isPaid ? Colors.grey : Colors.green)),
          ),
        ),
      ),
    );
  }
}
