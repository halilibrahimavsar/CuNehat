import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/info_action_menu.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart';
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

class _DebtAndReceivablePageState extends State<DebtAndReceivablePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentIndex = 0;

  bool get _isDebtTab => _currentIndex == 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentIndex) {
        setState(() => _currentIndex = _tabController.index);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    final accent =
        _isDebtTab ? AppGradients.debt : AppGradients.savings;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          "Finansal Takip",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 4,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(icon: Icon(Icons.outbound), text: "Borçlarım"),
            Tab(icon: Icon(Icons.call_received), text: "Alacaklarım"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DebtListSection(walletId: widget.walletId, userId: widget.userId),
          ReceivableListSection(
              walletId: widget.walletId, userId: widget.userId),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        onPressed: () => _showAddSheet(isDebt: _isDebtTab),
        icon: const Icon(Icons.add),
        label: Text(
          _isDebtTab ? "Borç Ekle" : "Alacak Ekle",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showAddSheet({required bool isDebt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEntrySheet(
        walletId: widget.walletId,
        initialIsDebt: isDebt,
      ),
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
          IboSnackbar.showSuccess(context, state.message);
        } else if (state is DebtError) {
          IboSnackbar.showError(context, state.message);
        }
      },
      builder: (context, state) {
        if (state is DebtLoading || state is DebtOperationSuccess) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DebtLoaded) {
          final activeDebts = state.debts
              .where((debt) => !debt.isPaid && debt.remainingAmount > 0)
              .toList();

          if (activeDebts.isEmpty) {
            return const Center(child: Text("Henüz borç kaydı yok."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeDebts.length,
            itemBuilder: (context, index) {
              final debt = activeDebts[index];
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
            backgroundColor: Colors.transparent,
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
              principalAmount: debt.principalAmount,
              totalPaidAmount: debt.totalPaidAmount));
        }
      },
      child: AppCard(
        section: AppSection.debt,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.withValues(alpha: 0.15)
                        : Colors.blue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: isOverdue ? Colors.red : Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        debt.counterparty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'VADESİ GEÇMİŞ',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(symbol: '₺')
                          .format(debt.remainingAmount),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                            fontSize: 20,
                          ),
                    ),
                    if (debt.isPaid) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'ÖDENDİ',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: debt.progress,
                minHeight: 8,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.05),
                color: debt.isPaid ? Colors.green : Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Vade: ${debt.termMonths} Ay | ${debt.payments.length} Ödeme",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOverdue
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!debt.isPaid)
                  FilledButton.icon(
                    onPressed: () => DebtPaymentDialog.show(context, debt),
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text("Öde"),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.15),
                      foregroundColor: Colors.green,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
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
          IboSnackbar.showSuccess(context, state.message);
        } else if (state is ReceivableError) {
          IboSnackbar.showError(context, state.message);
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
            backgroundColor: Colors.transparent,
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
              amount: receivable.amount,
              isPaid: receivable.isPaid));
        }
      },
      child: AppCard(
        section: AppSection.savings,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: receivable.isPaid
                    ? Colors.green.withValues(alpha: 0.15)
                    : (isOverdue
                        ? Colors.orange.withValues(alpha: 0.15)
                        : Colors.blue.withValues(alpha: 0.15)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                receivable.isPaid ? Icons.check_circle : Icons.person,
                color: receivable.isPaid
                    ? Colors.green
                    : (isOverdue ? Colors.orange : Colors.blue),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receivable.debtorName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          decoration: receivable.isPaid
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Vade: ${DateFormat('dd MMM yyyy').format(receivable.dueDate)}",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (isOverdue && !receivable.isPaid) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'VADESİ GEÇMİŞ',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(symbol: '₺').format(receivable.amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: receivable.isPaid ? Colors.grey : Colors.green,
                      ),
                ),
                if (receivable.isPaid) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'ÖDENDİ',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
