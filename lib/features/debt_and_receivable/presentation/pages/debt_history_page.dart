import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/core/onboarding/onboarding_auto_tour_trigger.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => getIt<DebtBloc>()..add(GetDebtsEvent(walletId))),
        BlocProvider(
            create: (_) =>
                getIt<ReceivableBloc>()..add(GetReceivablesEvent(walletId))),
      ],
      child: _DebtHistoryView(showAppBar: showAppBar),
    );
  }
}

class _DebtHistoryView extends StatelessWidget {
  final bool showAppBar;

  const _DebtHistoryView({required this.showAppBar});

  @override
  Widget build(BuildContext context) {
    return OnboardingAutoTourTrigger(
      flow: OnboardingFlow.debtHistory,
      keysBuilder: () => [OnboardingKeys.debtHistoryBody],
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: showAppBar
              ? AppBar(
                  title: Text(context.l10n.gecmis),
                  centerTitle: true,
                )
              : null,
          body: Showcase(
            key: OnboardingKeys.debtHistoryBody,
            title: context.l10n.onboardingDebtHistoryTitle,
            description: context.l10n.onboardingDebtHistoryDesc,
            child: Column(
              children: [
                TabBar(
                  indicatorWeight: 4,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: [
                    Tab(
                        icon: const Icon(Icons.outbound),
                        text: context.l10n.borcGecmisi),
                    Tab(
                        icon: const Icon(Icons.call_received),
                        text: context.l10n.alacakGecmisi),
                  ],
                ),
                const Expanded(
                  child: TabBarView(
                    children: [
                      _DebtHistoryTab(),
                      _ReceivableHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebtHistoryTab extends StatelessWidget {
  const _DebtHistoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DebtBloc, DebtState>(
      builder: (context, state) {
        if (state is DebtLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final debts = state is DebtLoaded ? state.debts : <DebtEntity>[];
        final paidDebts = debts.where((d) => d.isPaid).toList();

        if (paidDebts.isEmpty) {
          return _HistoryEmptyState(
            title: 'Henüz Kapanan Borç Yok',
            message: context.l10n.msgOdemesiTamamlanipKapatilanBorclarinizin,
          );
        }

        final totalPaid = paidDebts.fold<double>(
          0.0,
          (sum, d) => sum + d.totalPaidAmount,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HistorySummaryCard(
              text: context.l10n.paidDebtsLengthBorcKapandi(paidDebts.length),
              amount: totalPaid,
            ),
            const SizedBox(height: 16),
            ...paidDebts.map(
              (debt) => _HistoryCard(
                icon: Icons.receipt_long_rounded,
                title: debt.title,
                subtitle: debt.counterparty,
                amount: debt.totalPaidAmount,
                badge: 'Ödendi',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReceivableHistoryTab extends StatelessWidget {
  const _ReceivableHistoryTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceivableBloc, ReceivableState>(
      builder: (context, state) {
        if (state is ReceivableLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final receivables = state is ReceivableLoaded
            ? state.receivables
            : <ReceivableEntity>[];
        final paidReceivables = receivables.where((r) => r.isPaid).toList();

        if (paidReceivables.isEmpty) {
          return _HistoryEmptyState(
            title: 'Henüz Tahsil Edilen Alacak Yok',
            message: context.l10n.msgOdendiOlarakIsaretlenenAlacaklarinizin,
          );
        }

        final totalCollected = paidReceivables.fold<double>(
          0.0,
          (sum, r) => sum + r.amount,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HistorySummaryCard(
              text: context.l10n
                  .paidReceivablesLengthAlacakTahsil(paidReceivables.length),
              amount: totalCollected,
            ),
            const SizedBox(height: 16),
            ...paidReceivables.map(
              (receivable) => _HistoryCard(
                icon: Icons.call_received_rounded,
                title: receivable.debtorName,
                subtitle:
                    "Vade: ${DateFormat('dd MMM yyyy').format(receivable.dueDate)}",
                amount: receivable.amount,
                badge: 'Tahsil Edildi',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  final String text;
  final double amount;

  const _HistorySummaryCard({required this.text, required this.amount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      accent: Colors.green,
      padding: const EdgeInsets.all(16),
      elevated: false,
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
          ),
          Text(
            AppFormatters.currency.format(amount),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.green,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final String badge;

  const _HistoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      section: AppSection.neutral,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8F5E9),
            radius: 20,
            child: Icon(icon, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppFormatters.currency.format(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _HistoryEmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: AppCard(
          section: AppSection.debt,
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
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
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
