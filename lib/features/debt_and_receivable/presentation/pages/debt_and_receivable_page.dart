import 'package:cunehat/core/shared/widgets/info_action_menu.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MainDashboard extends StatefulWidget {
  final String userId;
  final String walletId;
  const MainDashboard(
      {super.key, required this.userId, required this.walletId});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında verileri mevcut cüzdan ID'sine göre çekiyoruz
    _loadDebt();
  }

  @override
  void didUpdateWidget(covariant MainDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.walletId != oldWidget.walletId) {
      _loadDebt();
    }
  }

  void _loadDebt() {
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
            DebtListSection(walletId: widget.walletId),
            ReceivableListSection(walletId: widget.walletId),
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

  // Ekleme Modalını Açan Fonksiyon
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
  const DebtListSection({super.key, required this.walletId});

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
        // Loading veya Success durumunda (Success sonrası reload olacağı için) loading göster
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
      items: const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text("Düzenle"),
            ],
          ),
        ),
        PopupMenuItem(
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
        if (value == 'edit') {
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
                subtitle: Text(debt.counterparty),
                trailing: Text(
                    NumberFormat.currency(symbol: '₺')
                        .format(debt.remainingAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red)),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                  value: debt.progress, backgroundColor: Colors.grey.shade200),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      "Vade: ${debt.termMonths} Ay | ${debt.payments.length} Taksit",
                      style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey)),
                  TextButton(
                      onPressed: () => _showPaymentDialog(context, debt),
                      child: const Text("Ödeme Yap")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, DebtEntity debt) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ödeme Yap"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Kalan Borç: ${debt.remainingAmount} ₺"),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Ödenecek Tutar",
                  border: OutlineInputBorder(),
                  suffixText: "₺",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  final newRemaining = debt.remainingAmount - amount;
                  // Basitçe kalan tutarı güncelliyoruz.
                  // İdealde PaymentEntity oluşturup listeye eklenmeli.
                  final updatedDebt =
                      debt.copyWith(principalAmount: newRemaining);
                  context.read<DebtBloc>().add(UpdateDebtEvent(updatedDebt));
                  Navigator.pop(context);
                }
              },
              child: const Text("Öde"),
            ),
          ],
        );
      },
    );
  }
}

// --- ALACAK LİSTESİ BÖLÜMÜ ---
class ReceivableListSection extends StatelessWidget {
  final String walletId;
  const ReceivableListSection({super.key, required this.walletId});

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
    return InfoActionMenu<String>(
      items: const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text("Düzenle"),
            ],
          ),
        ),
        PopupMenuItem(
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
        if (value == 'edit') {
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
              id: receivable.id!, walletId: receivable.walletId));
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: Colors.green.shade50,
          leading: const Icon(Icons.person, color: Colors.green),
          title: Text(receivable.debtorName),
          subtitle: Text(
              "Vade: ${DateFormat('dd MMM yyyy').format(receivable.dueDate)}"),
          trailing: Text(
              NumberFormat.currency(symbol: '₺').format(receivable.amount),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green)),
        ),
      ),
    );
  }
}
