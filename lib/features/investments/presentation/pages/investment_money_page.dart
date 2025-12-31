import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_investment_dialog.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_chart.dart';
import 'package:cunehat/features/investments/presentation/widgets/summary_card.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SaveMoneyPage extends StatefulWidget {
  const SaveMoneyPage({super.key});

  @override
  State<SaveMoneyPage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<SaveMoneyPage> {
  void _addInvestment(InvestmentEntity newInvestment) {
    context.read<InvestmentBloc>().add(CreateInvestmentEvent(newInvestment));
  }

  void _showAddInvestmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddInvestmentDialog(
        onAddInvestment: _addInvestment,
      ),
    );
  }

  void _deleteInvestment(String id) {
    context.read<InvestmentBloc>().add(DeleteInvestmentEvent(id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvestmentBloc, InvestmentState>(
      listener: (context, state) {
        if (state is InvestmentOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message), backgroundColor: Colors.green),
          );
        } else if (state is InvestmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, investmentState) {
        // Verileri hazırla
        List<InvestmentEntity> investments = [];
        if (investmentState is InvestmentLoaded) {
          investments = investmentState.investments;
        }

        // Hesaplamalar
        final totalInvestment =
            investments.fold(0.0, (sum, item) => sum + item.amount);
        final totalCurrentValue =
            investments.fold(0.0, (sum, item) => sum + item.currentValue);
        final totalProfit = totalCurrentValue - totalInvestment;
        final totalProfitPercentage =
            totalInvestment > 0 ? (totalProfit / totalInvestment) * 100 : 0.0;

        return BlocBuilder<WalletBloc, WalletState>(
          builder: (context, walletState) {
            double walletSave = 0;
            String walletName = '';

            if (walletState is WalletLoadedSt) {
              walletSave = walletState.activeWallet!.save;
              walletName = walletState.activeWallet!.name;
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Birikim Takip',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddInvestmentDialog,
                  ),
                ],
              ),
              body: investmentState is InvestmentLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cüzdan Birikim Bilgisi
                            if (walletState is WalletLoadedSt) ...[
                              _buildWalletSaveInfo(walletName, walletSave),
                              const SizedBox(height: 24),
                            ],

                            // Özet Kartları
                            SummaryCard(
                              totalInvestment: totalInvestment,
                              totalCurrentValue: totalCurrentValue,
                              totalProfit: totalProfit,
                              totalProfitPercentage: totalProfitPercentage,
                            ),

                            const SizedBox(height: 24),

                            // Grafik
                            if (investments.isNotEmpty)
                              InvestmentChart(investments: investments),

                            const SizedBox(height: 24),

                            // Portföy Başlığı
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Portföyüm',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${investments.length} yatırım',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Yatırım Listesi
                            ...investments.map((investment) {
                              return Column(
                                children: [
                                  InvestmentCard(
                                    investment: investment,
                                    onDelete: () =>
                                        _deleteInvestment(investment.id!),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
              floatingActionButton: FloatingActionButton(
                onPressed: _showAddInvestmentDialog,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWalletSaveInfo(String walletName, double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$walletName Nakit Birikimi',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(2)} ₺',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
