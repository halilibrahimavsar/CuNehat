import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/shared/widgets/info_action_menu.dart';
import 'package:cunehat/core/shared/widgets/try_only_feature_view.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_math.dart';
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
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:showcaseview/showcaseview.dart';

class DebtAndReceivablePage extends StatefulWidget {
  final String userId;
  final String walletId;

  /// Aktif cüzdanın para birimi; TL değilse özellik bilgilendirmeyle kapalı
  /// (v1 kısıtı — nakit kuplajı TL varsayar).
  final String walletCurrency;

  const DebtAndReceivablePage({
    super.key,
    required this.userId,
    required this.walletId,
    this.walletCurrency = kDefaultCurrency,
  });

  @override
  State<DebtAndReceivablePage> createState() => _DebtAndReceivablePageState();
}

class _DebtAndReceivablePageState extends State<DebtAndReceivablePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final GlobalKey _tabBarKey = GlobalKey(debugLabel: 'onboarding_debt_tabbar');

  List<GlobalKey> get _tourKeys => [_tabBarKey, OnboardingKeys.addActionSlider];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    // v1 kısıtı: TL dışı cüzdanda bu sayfa TryOnlyFeatureView gösterir,
    // showcase hedefleri hiç mount olmaz; tur da istenmez.
    final isTryWallet = widget.walletCurrency == kDefaultCurrency;
    return OnboardingTour(
      flow: OnboardingFlow.debt,
      keys: _tourKeys,
      enabled: isTryWallet,
      child: isTryWallet
          ? _buildContent(context)
          : Scaffold(
              body: TryOnlyFeatureView(message: context.l10n.sadeceTlCuzdanBorc),
            ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final tabBar = TabBar(
      controller: _tabController,
      indicatorWeight: 4,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      tabs: [
        Tab(icon: const Icon(Icons.outbound), text: context.l10n.borclarim),
        Tab(
            icon: const Icon(Icons.call_received),
            text: context.l10n.alacaklarim),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Text(
          context.l10n.finansalTakip,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: tabBar.preferredSize,
          child: Showcase(
            key: _tabBarKey,
            title: context.l10n.onboardingDebtTabsTitle,
            description: context.l10n.onboardingDebtTabsDesc,
            child: tabBar,
          ),
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
              .where((debt) =>
                  !debt.isPaid && moneyIsPositive(debt.remainingAmount))
              .toList();

          if (activeDebts.isEmpty) {
            return _EmptyStateCard(
              icon: Icons.outbound_rounded,
              title: context.l10n.henuzBorcKaydiYok,
              description: context.l10n.henuzBorcKaydiYokAciklama,
              section: AppSection.debt,
            );
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
                  child: Text(context.l10n.tekrarDene),
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
        PopupMenuItem(
          value: 'payment',
          child: Row(
            children: [
              const Icon(Icons.payment, color: Colors.green),
              const SizedBox(width: 8),
              Text(context.l10n.odemeYap,
                  style: const TextStyle(color: Colors.green)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(context.l10n.duzenle),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 8),
              Text(context.l10n.sil, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        final debtBloc = context.read<DebtBloc>();
        if (value == 'payment') {
          DebtPaymentDialog.show(context, debt);
        } else if (value == 'edit') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddEntrySheet(
              walletId: walletId,
              userId: userId,
              debtToEdit: debt,
            ),
          );
        } else if (value == 'delete') {
          // Borç silmek cüzdanın nakit hareketini de geri alır
          // (bkz. DebtBloc._onDeleteDebt) → geri alınamaz.
          final confirmed = await ConfirmDialog.show(
            context,
            title: context.l10n.borcSilBaslik,
            message: context.l10n.borcSilOnayMesaji(debt.title),
            confirmText: context.l10n.sil,
            danger: true,
          );
          if (!confirmed) return;

          debtBloc.add(DeleteDebtEvent(
              id: debt.id!,
              userId: debt.userId,
              walletId: debt.walletId,
              principalAmount: debt.principalAmount,
              totalPaidAmount: debt.totalPaidAmount,
              principalToWallet: debt.principalToWallet));
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
                          child: Text(
                            context.l10n.vADESIGecmis,
                            style: const TextStyle(
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
                      AppFormatters.currency.format(debt.remainingAmount),
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
                        child: Text(
                          context.l10n.oDENDI,
                          style: const TextStyle(
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
                  context.l10n.vadeDebtTermmonthsAy(
                      debt.termMonths, debt.payments.length),
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
                    label: Text(context.l10n.ode),
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
          // Ödenenler borçlardaki gibi Geçmiş alt sayfasına taşınır.
          final activeReceivables =
              state.receivables.where((r) => !r.isPaid).toList();

          if (activeReceivables.isEmpty) {
            return _EmptyStateCard(
              icon: Icons.call_received_rounded,
              title: context.l10n.henuzAlacakKaydiYok,
              description: context.l10n.henuzAlacakKaydiYokAciklama,
              section: AppSection.savings,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeReceivables.length,
            itemBuilder: (context, index) {
              final receivable = activeReceivables[index];
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
                  child: Text(context.l10n.tekrarDene),
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
          PopupMenuItem(
            value: 'mark_paid',
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(context.l10n.odendiIsaretle,
                    style: const TextStyle(color: Colors.green)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(context.l10n.duzenle),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 8),
              Text(context.l10n.sil, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        final receivableBloc = context.read<ReceivableBloc>();
        if (value == 'mark_paid') {
          receivableBloc.add(MarkReceivableAsPaidEvent(receivable));
        } else if (value == 'edit') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddEntrySheet(
              walletId: walletId,
              userId: userId,
              receivableToEdit: receivable,
            ),
          );
        } else if (value == 'delete') {
          final confirmed = await ConfirmDialog.show(
            context,
            title: context.l10n.alacakSilBaslik,
            message: context.l10n.alacakSilOnayMesaji(receivable.debtorName),
            confirmText: context.l10n.sil,
            danger: true,
          );
          if (!confirmed) return;

          receivableBloc.add(DeleteReceivableEvent(
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
                    context.l10n.vadeDateformatDdMmm(
                        DateFormat('dd MMM yyyy').format(receivable.dueDate)),
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
                      child: Text(
                        context.l10n.vADESIGecmis,
                        style: const TextStyle(
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
                  AppFormatters.currency.format(receivable.amount),
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
                    child: Text(
                      context.l10n.oDENDI,
                      style: const TextStyle(
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

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final AppSection section;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accentColor = AppGradients.sectionColor(section);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppCard(
                  section: section,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 44,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
