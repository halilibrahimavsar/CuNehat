import 'package:cunehat/core/shared/widgets/dismissable_widget.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_chart.dart';
import 'package:cunehat/features/investments/presentation/widgets/summary_card.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
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
  /// true → sat (nakit gelir işlenir), false → yalnız kaydı sil, null → vazgeç.
  Future<bool?> _askDeleteMode(InvestmentEntity investment) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${investment.name} kaldırılsın mı?'),
        content: Text(
          'Sat: Güncel değer (${investment.currentValue.toStringAsFixed(2)} ₺) '
          'cüzdana gelir olarak işlenir.\n\n'
          'Kaydı Sil: Nakit etkisi olmaz; geçmiş alım işlemleri korunur '
          '(hatalı girişler için).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kaydı Sil'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sat'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInvestments();
  }

  @override
  void didUpdateWidget(covariant InvestmentMoneyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeWallet.id != oldWidget.activeWallet.id) {
      _loadInvestments();
    }
  }

  void _loadInvestments() {
    context.read<InvestmentBloc>().add(GetInvestmentsEvent(
          userId: widget.activeWallet.userId,
          walletId: widget.activeWallet.id!,
        ));
  }

  Future<bool> _deleteInvestment(InvestmentEntity investment) async {
    final sell = await _askDeleteMode(investment);
    if (sell != null && mounted) {
      context.read<InvestmentBloc>().add(DeleteInvestmentEvent(
            id: investment.id!,
            userId: widget.activeWallet.userId,
            walletId: widget.activeWallet.id!,
            amount: investment.amount,
            currentValue: investment.currentValue,
            recordSale: sell,
          ));
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvestmentBloc, InvestmentState>(
      listener: (context, state) {
        if (state is InvestmentActionSuccess) {
          IboSnackbar.showSuccess(context, state.message);
          _loadInvestments();
        } else if (state is InvestmentError) {
          IboSnackbar.showError(context, state.message);
        }
      },
      builder: (context, investmentState) {
        // Özet metrikler state üzerinde hazır (InvestmentLoaded getters).
        final loaded =
            investmentState is InvestmentLoaded ? investmentState : null;
        final investments = loaded?.investments ?? const <InvestmentEntity>[];
        final totalInvestment = loaded?.totalAmount ?? 0.0;
        final totalCurrentValue = loaded?.totalCurrentValue ?? 0.0;
        final totalProfit = loaded?.totalProfit ?? 0.0;
        final totalProfitPercentage = loaded?.totalProfitPercentage ?? 0.0;

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
                              DismissableWidget<InvestmentEntity>(
                                item: investment,
                                dismissKey: investment.id!,
                                onDelete: (item) async {
                                  return await _deleteInvestment(investment);
                                },
                                onEdit: (item) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AddInvestmentDialog(
                                      userId: investment.userId,
                                      walletId: investment.walletId,
                                      investmentToEdit:
                                          InvestmentModel.fromEntity(item),
                                      onSave: (updatedInvestment) {
                                        context
                                            .read<InvestmentBloc>()
                                            .add(UpdateInvestmentEvent(
                                              investment: updatedInvestment,
                                              userId:
                                                  widget.activeWallet.userId,
                                              walletId: widget.activeWallet.id!,
                                              prevAmount: item.amount,
                                              newAmount:
                                                  updatedInvestment.amount,
                                            ));
                                      },
                                    ),
                                  );
                                },
                                child: InvestmentCard(
                                  investment: investment,
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
