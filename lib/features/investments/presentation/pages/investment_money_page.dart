import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/shared/widgets/dismissable_widget.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/contribute_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_action_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_chart.dart';
import 'package:cunehat/features/investments/presentation/widgets/summary_card.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_gold_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_stock_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_custom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;

class InvestmentMoneyPage extends StatefulWidget {
  final WalletEntity activeWallet;

  const InvestmentMoneyPage({super.key, required this.activeWallet});

  @override
  State<InvestmentMoneyPage> createState() => _InvestmentMoneyPageState();
}

class _InvestmentMoneyPageState extends State<InvestmentMoneyPage> {
  late ConfettiController _confettiController;

  /// Satış onayı: güncel değer cüzdana gelir olarak işlenir.
  Future<bool?> _confirmSell(InvestmentEntity investment) {
    return IboDialog.showCustomDialog<bool>(
      context,
      title: '${investment.name} satılsın mı?',
      content: Text(
        'Güncel değer (${formatMoney(investment.currentValue)}) cüzdana '
        'gelir olarak işlenir ve kayıt kapatılır.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sat'),
        ),
      ],
    );
  }

  /// Kayıt silme onayı: hatalı girişler için, alım gideri iade edilir.
  Future<bool?> _confirmDelete(InvestmentEntity investment) {
    return IboDialog.showCustomDialog<bool>(
      context,
      title: '${investment.name} kaydı silinsin mi?',
      content: Text(
        'Hatalı girişler için: alım gideri '
        '(${formatMoney(investment.amount)}) düzeltme kaydıyla iade edilir, '
        'bakiye yatırım öncesine döner.\n\n'
        'Gerçekten sattıysanız bunun yerine "Sat" kullanın.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Kaydı Sil'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadInvestments();
  }

  @override
  void didUpdateWidget(covariant InvestmentMoneyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeWallet.id != oldWidget.activeWallet.id) {
      _loadInvestments();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _loadInvestments() {
    context.read<InvestmentBloc>().add(GetInvestmentsEvent(
          userId: widget.activeWallet.userId,
          walletId: widget.activeWallet.id!,
        ));
  }

  /// Sat: nakit gelir işlenir; Kaydı Sil: alım gideri ters kayıtla iade.
  void _dispatchDelete(InvestmentEntity investment, {required bool sell}) {
    context.read<InvestmentBloc>().add(DeleteInvestmentEvent(
          id: investment.id!,
          userId: widget.activeWallet.userId,
          walletId: widget.activeWallet.id!,
          amount: investment.amount,
          currentValue: investment.currentValue,
          recordSale: sell,
        ));
  }

  /// Sağa kaydırma artık yalnızca "Kaydı Sil" akışıdır; satış eylem
  /// menüsünden ayrıca yapılır.
  Future<bool> _deleteInvestment(InvestmentEntity investment) async {
    final confirmed = await _confirmDelete(investment);
    if (confirmed == true && mounted) {
      _dispatchDelete(investment, sell: false);
      return true;
    }
    return false;
  }

  /// Katkı (Mod A: nakit, Mod B: varlık alımı) — muhasebe contribute_sheet'te.
  void _showContributeSheet(InvestmentEntity investment) {
    final bloc = context.read<InvestmentBloc>();
    ContributeSheet.show(
      context,
      investment: investment,
      onSave: (updated) {
        bloc.add(UpdateInvestmentEvent(
          investment: updated,
          userId: widget.activeWallet.userId,
          walletId: widget.activeWallet.id!,
          prevAmount: investment.amount,
          newAmount: updated.amount,
        ));
        if (updated.isTargetReached && !investment.isTargetReached) {
          _confettiController.play();
        }
      },
    );
  }

  void _openEditSheet(InvestmentEntity item) {
    void onSave(InvestmentEntity updatedInvestment) {
      context.read<InvestmentBloc>().add(UpdateInvestmentEvent(
            investment: updatedInvestment,
            userId: widget.activeWallet.userId,
            walletId: widget.activeWallet.id!,
            prevAmount: item.amount,
            newAmount: updatedInvestment.amount,
          ));

      if (updatedInvestment.isTargetReached && !item.isTargetReached) {
        _confettiController.play();
      }
    }

    switch (item.type) {
      case InvestmentType.gold:
        AddGoldSheet.show(
          context,
          userId: item.userId,
          walletId: item.walletId,
          investmentToEdit: item,
          onSave: onSave,
        );
        break;
      case InvestmentType.stock:
        AddStockSheet.show(
          context,
          userId: item.userId,
          walletId: item.walletId,
          investmentToEdit: item,
          onSave: onSave,
        );
        break;
      case InvestmentType.custom:
        AddCustomSheet.show(
          context,
          userId: item.userId,
          walletId: item.walletId,
          investmentToEdit: item,
          onSave: onSave,
        );
        break;
    }
  }

  /// Karta dokunma: Sat / Sil / Düzenle / Katkı / Fiyat eylemleri ayrı
  /// satırlar olarak sunulur.
  Future<void> _showActionSheet(InvestmentEntity investment) async {
    final action =
        await InvestmentActionSheet.show(context, investment: investment);
    if (action == null || !mounted) return;

    switch (action) {
      case InvestmentAction.contribute:
        _showContributeSheet(investment);
        break;
      case InvestmentAction.refreshPrice:
        context.read<InvestmentBloc>().add(RefreshPricesEvent(
              userId: widget.activeWallet.userId,
              walletId: widget.activeWallet.id!,
              investmentId: investment.id,
            ));
        break;
      case InvestmentAction.edit:
        _openEditSheet(investment);
        break;
      case InvestmentAction.sell:
        final confirmed = await _confirmSell(investment);
        if (confirmed == true && mounted) {
          _dispatchDelete(investment, sell: true);
        }
        break;
      case InvestmentAction.delete:
        final confirmed = await _confirmDelete(investment);
        if (confirmed == true && mounted) {
          _dispatchDelete(investment, sell: false);
        }
        break;
    }
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
        // Hedefli birikimler listenin başında gösterilir (kararlı sıra).
        final allInvestments =
            loaded?.investments ?? const <InvestmentEntity>[];
        final investments = [
          ...allInvestments.where((i) => i.isGoal),
          ...allInvestments.where((i) => !i.isGoal),
        ];
        final totalInvestment = loaded?.totalAmount ?? 0.0;
        final totalCurrentValue = loaded?.totalCurrentValue ?? 0.0;
        final totalProfit = loaded?.totalProfit ?? 0.0;
        final totalProfitPercentage = loaded?.totalProfitPercentage ?? 0.0;

        return Stack(
          children: [
            Scaffold(
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
                                Row(
                                  children: [
                                    Text(
                                      '${investments.length} yatırım',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (investments
                                        .any((i) => i.canRefreshPrice))
                                      IconButton(
                                        tooltip: 'Fiyatları Güncelle',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => context
                                            .read<InvestmentBloc>()
                                            .add(RefreshPricesEvent(
                                              userId:
                                                  widget.activeWallet.userId,
                                              walletId:
                                                  widget.activeWallet.id!,
                                            )),
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 20,
                                          color: Colors.teal,
                                        ),
                                      ),
                                  ],
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
                                      return await _deleteInvestment(
                                          investment);
                                    },
                                    onEdit: (item) => _openEditSheet(item),
                                    child: GestureDetector(
                                      // Dokunuş eylem menüsünü açar: katkı,
                                      // fiyat, düzenle, sat ve sil ayrı ayrı.
                                      onTap: () =>
                                          _showActionSheet(investment),
                                      child: InvestmentCard(
                                        investment: investment,
                                      ),
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
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2, // downwards
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
              ),
            ),
          ],
        );
      },
    );
  }
}
