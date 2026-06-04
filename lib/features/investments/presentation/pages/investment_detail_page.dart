import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_chart.dart';
import 'package:cunehat/features/investments/presentation/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      create: (_) => getIt<InvestmentBloc>()
        ..add(GetInvestmentsEvent(userId: userId, walletId: walletId)),
      child: _InvestmentDetailView(showAppBar: showAppBar),
    );
  }
}

class _InvestmentDetailView extends StatelessWidget {
  final bool showAppBar;

  const _InvestmentDetailView({required this.showAppBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const Text('Birikim Detayı'),
              centerTitle: true,
            )
          : null,
      body: BlocBuilder<InvestmentBloc, InvestmentState>(
        builder: (context, state) {
          if (state is InvestmentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final investments = state is InvestmentLoaded
              ? state.investments
              : <InvestmentEntity>[];

          final totalInvestment =
              investments.fold(0.0, (sum, item) => sum + item.amount);
          final totalCurrentValue =
              investments.fold(0.0, (sum, item) => sum + item.currentValue);
          final totalProfit = totalCurrentValue - totalInvestment;
          final totalProfitPercentage =
              totalInvestment > 0 ? (totalProfit / totalInvestment) * 100 : 0.0;

          if (investments.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Birikim Detayı',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SummaryCard(
                  totalInvestment: totalInvestment,
                  totalCurrentValue: totalCurrentValue,
                  totalProfit: totalProfit,
                  totalProfitPercentage: totalProfitPercentage,
                ),
                const SizedBox(height: 24),
                InvestmentChart(investments: investments),
                const SizedBox(height: 24),
                const Text(
                  'Portföy Detayı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...investments.map(
                  (investment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InvestmentCard(investment: investment),
                  ),
                ),
              ],
            ),
          );
        },
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
                child: Icon(Icons.savings_outlined,
                    size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz Yatırım Kaydı Yok',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Yatırımlarınızı ekledikten sonra detaylı analizler burada görünecektir.',
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
