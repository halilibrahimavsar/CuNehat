import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DebtHistoryPage extends StatelessWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  const DebtHistoryPage({
    super.key,
    required this.userId,
    required this.walletId,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<DebtBloc>()..add(GetDebtsEvent(walletId)),
      child: _DebtHistoryView(showAppBar: showAppBar),
    );
  }
}

class _DebtHistoryView extends StatelessWidget {
  final bool showAppBar;

  const _DebtHistoryView({required this.showAppBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Borç Geçmişi'),
              centerTitle: true,
            )
          : null,
      body: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          if (state is DebtLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final debts = state is DebtLoaded ? state.debts : <DebtEntity>[];
          // "Ödenmiş" tek kural: borç açıkça ödendi olarak işaretlenmiş.
          // (Ödeme tamamlanınca DebtPaymentDialog isPaid=true yapıyor.)
          final paidDebts = debts.where((d) => d.isPaid).toList();

          if (paidDebts.isEmpty) {
            return _buildEmptyState();
          }

          final totalPaid = paidDebts.fold<double>(
            0.0,
            (sum, d) => sum + d.totalPaidAmount,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Borç Geçmişi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildSummary(totalPaid, paidDebts.length),
              const SizedBox(height: 16),
              ...paidDebts.map((debt) => _buildDebtCard(debt)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(double totalPaid, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count borç kapandı',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '₺').format(totalPaid),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(DebtEntity debt) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.receipt_long, color: Colors.green),
        ),
        title: Text(
          debt.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(debt.counterparty),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat.currency(symbol: '₺')
                  .format(debt.totalPaidAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ödendi',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.blueGrey.shade200),
          const SizedBox(height: 12),
          const Text(
            'Henüz kapanan borç yok',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
