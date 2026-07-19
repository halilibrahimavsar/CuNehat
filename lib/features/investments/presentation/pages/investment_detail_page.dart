import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:cunehat/core/onboarding/onboarding_auto_tour_trigger.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';

class InvestmentDetailPage extends StatelessWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  const InvestmentDetailPage({
    super.key,
    required this.userId,
    required this.walletId,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionBloc>()
        ..add(GetTransactionsEvent(userId: userId, walletId: walletId)),
      child: _InvestmentDetailView(showAppBar: showAppBar),
    );
  }
}

class _InvestmentDetailView extends StatelessWidget {
  final bool showAppBar;

  const _InvestmentDetailView({required this.showAppBar});

  @override
  Widget build(BuildContext context) {
    return OnboardingAutoTourTrigger(
      flow: OnboardingFlow.investmentDetail,
      keysBuilder: () => [OnboardingKeys.investmentDetailBody],
      child: Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: Text(context.l10n.birikimDetayi),
                centerTitle: true,
              )
            : null,
        body: Showcase(
          key: OnboardingKeys.investmentDetailBody,
          title: context.l10n.onboardingInvestmentDetailTitle,
          description: context.l10n.onboardingInvestmentDetailDesc,
          child: BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              final allTransactions = state.currentTransactions;

              if (state is TransactionLoading && allTransactions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Sadece otomatik oluşturulan yatırım hareketlerini filtrele
              final investmentTransactions = allTransactions.where((t) {
                return t.isSystem &&
                    (t.tag == CashMovementTags.investmentBuy ||
                        t.tag == CashMovementTags.investmentSell ||
                        t.tag == CashMovementTags.investmentCorrection);
              }).toList();

              if (investmentTransactions.isEmpty) {
                return _buildEmptyState(context);
              }

              // TransactionCard beklentisi olan TransactionWithBalance sınıfına çevir
              // Bakiye takibi bu sayfada görünür olmadığından currentBalance: 0
              final withBalanceList = buildLedgerView(
                allTransactions: investmentTransactions,
                currentBalance: 0,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.gecmis,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...withBalanceList.map(
                      (item) => TransactionCard(
                        context: context,
                        item: item,
                        isListView: true,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: AppCard(
          section: AppSection.savings,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history_rounded,
                    size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.henuzYatirimKaydiYok,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Yatırım geçmişiniz burada listelenecektir.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
