import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_chart.dart';
import 'package:cunehat/features/investments/presentation/widgets/summary_card.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_investment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InvestmentMoneyPage extends StatefulWidget {
  final WalletEntity activeWallet;

  const InvestmentMoneyPage({super.key, required this.activeWallet});

  @override
  State<InvestmentMoneyPage> createState() => _InvestmentMoneyPageState();
}

class _InvestmentMoneyPageState extends State<InvestmentMoneyPage> {
  void _deleteInvestment(String id) {
    context.read<InvestmentBloc>().add(DeleteInvestmentEvent(
          id: id,
          userId: widget.activeWallet.userId,
          walletId: widget.activeWallet.id!,
        ));
  }

  void _loadInvestments() {
    context.read<InvestmentBloc>().add(GetInvestmentsEvent(
          userId: widget.activeWallet.userId,
          walletId: widget.activeWallet.id!,
        ));
    context.read<WalletBloc>().add(GetWalletsEvent(widget.activeWallet.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvestmentBloc, InvestmentState>(
      listener: (context, state) {
        if (state is InvestmentActionSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
          _loadInvestments();
        } else if (state is InvestmentError) {
          SnackbarHelper.showError(context, state.message);
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

        return Scaffold(
          body: investmentState is InvestmentLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AddInvestmentDialog(
                                      investmentToEdit:
                                          InvestmentModel.fromEntity(
                                              investment),
                                      onSave: (updatedInvestment) {
                                        context.read<InvestmentBloc>().add(
                                              UpdateInvestmentEvent(
                                                investment: updatedInvestment,
                                                userId:
                                                    widget.activeWallet.userId,
                                                walletId:
                                                    widget.activeWallet.id!,
                                              ),
                                            );
                                      },
                                    ),
                                  );
                                },
                                child: InvestmentCard(
                                  investment: investment,
                                  onDelete: () =>
                                      _deleteInvestment(investment.id!),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
