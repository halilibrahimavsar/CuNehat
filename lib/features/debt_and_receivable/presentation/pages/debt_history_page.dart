import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/shared/widgets/info_action_menu.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/messaging/deletion_undo_message.dart';

class DebtHistoryPage extends StatelessWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  /// Cüzdanın para birimi; kapanmış borç/alacak tutarları bu birimde yazılır.
  final String walletCurrency;

  const DebtHistoryPage({
    super.key,
    required this.userId,
    required this.walletId,
    required this.walletCurrency,
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
      child: _DebtHistoryView(
        showAppBar: showAppBar,
        userId: userId,
        walletId: walletId,
        currency: walletCurrency,
      ),
    );
  }
}

class _DebtHistoryView extends StatelessWidget {
  final bool showAppBar;
  final String userId;
  final String walletId;
  final String currency;

  const _DebtHistoryView({
    required this.showAppBar,
    required this.userId,
    required this.walletId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: Text(context.l10n.gecmis),
                centerTitle: true,
              )
            : null,
        body: Column(
          children: [
            TabBar(
              indicatorWeight: 4,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(
                    icon: const Icon(Icons.outbound),
                    text: context.l10n.borcGecmisi),
                Tab(
                    icon: const Icon(Icons.call_received),
                    text: context.l10n.alacakGecmisi),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _DebtHistoryTab(
                      userId: userId, walletId: walletId, currency: currency),
                  _ReceivableHistoryTab(
                      userId: userId, walletId: walletId, currency: currency),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtHistoryTab extends StatelessWidget {
  final String userId;
  final String walletId;
  final String currency;

  const _DebtHistoryTab({
    required this.userId,
    required this.walletId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DebtBloc, DebtState>(
      listener: (context, state) {
        if (state is DebtOperationSuccess) {
          showDeletionMessage(context,
              message: state.message, undo: state.undo);
        } else if (state is DebtError) {
          AppMessenger.error(state.message);
        }
      },
      // DebtOperationSuccess yalnız snackbar taşıyan geçici bir durumdur; liste
      // için önceki kare korunur. Aksi halde gövde "başarı → hemen ardından
      // GetDebtsEvent geliyor" varsayımına bağlı kalır ve refetch atlayan bir
      // handler eklendiğinde sekme kalıcı spinner'da donardı.
      buildWhen: (_, current) => current is! DebtOperationSuccess,
      builder: (context, state) {
        if (state is DebtLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final debts = state is DebtLoaded ? state.debts : <DebtEntity>[];
        final paidDebts = debts.where((d) => d.isPaid).toList();

        if (paidDebts.isEmpty) {
          return _HistoryEmptyState(
            title: context.l10n.debtHistoryEmptyTitle,
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
              currency: currency,
            ),
            const SizedBox(height: 16),
            ...paidDebts.map(
              (debt) => InfoActionMenu<String>(
                items: [
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
                        Text(context.l10n.sil,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  // Bu sayfa kendi DebtBloc örneğini yaratır (DI'da factory).
                  // Modal route sayfanın provider'ının ALTINDA değil, Overlay'de
                  // kardeşi olarak açılır → sheet içindeki context.read global
                  // bloc'u bulur ve düzenleme bu listeyi hiç tazelemezdi.
                  final debtBloc = context.read<DebtBloc>();

                  if (value == 'edit') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BlocProvider.value(
                        value: debtBloc,
                        child: AddEntrySheet(
                          walletId: walletId,
                          userId: userId,
                          currency: currency,
                          debtToEdit: debt,
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    // Borç silmek cüzdanın nakit hareketini de geri alır
                    // (bkz. DebtBloc._onDeleteDebt); onay + 6 sn "Geri al" ile korunur.
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
                        startDate: debt.startDate,
                        payments: debt.payments,
                        principalToWallet: debt.principalToWallet));
                  }
                },
                child: _HistoryCard(
                  icon: Icons.receipt_long_rounded,
                  title: debt.title,
                  subtitle: debt.counterparty,
                  amount: debt.totalPaidAmount,
                  currency: currency,
                  badge: context.l10n.badgeOdendi,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReceivableHistoryTab extends StatelessWidget {
  final String userId;
  final String walletId;
  final String currency;

  const _ReceivableHistoryTab({
    required this.userId,
    required this.walletId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceivableBloc, ReceivableState>(
      listener: (context, state) {
        if (state is ReceivableOperationSuccess) {
          showDeletionMessage(context,
              message: state.message, undo: state.undo);
        } else if (state is ReceivableError) {
          AppMessenger.error(state.message);
        }
      },
      // Bkz. _DebtHistoryTab: OperationSuccess yalnız snackbar durumudur.
      buildWhen: (_, current) => current is! ReceivableOperationSuccess,
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
            title: context.l10n.receivableHistoryEmptyTitle,
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
              currency: currency,
            ),
            const SizedBox(height: 16),
            ...paidReceivables.map(
              (receivable) => InfoActionMenu<String>(
                items: [
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
                        Text(context.l10n.sil,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  // Bkz. _DebtHistoryTab: sheet Overlay'de açıldığından sayfanın
                  // yerel bloc'u elle taşınmalı.
                  final receivableBloc = context.read<ReceivableBloc>();

                  if (value == 'edit') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => BlocProvider.value(
                        value: receivableBloc,
                        child: AddEntrySheet(
                          walletId: walletId,
                          userId: userId,
                          currency: currency,
                          receivableToEdit: receivable,
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: context.l10n.alacakSilBaslik,
                      message: context.l10n
                          .alacakSilOnayMesaji(receivable.debtorName),
                      confirmText: context.l10n.sil,
                      danger: true,
                    );
                    if (!confirmed) return;

                    receivableBloc.add(DeleteReceivableEvent(
                        id: receivable.id!,
                        userId: receivable.userId,
                        walletId: receivable.walletId,
                        amount: receivable.amount,
                        isPaid: receivable.isPaid,
                        createdAt: receivable.createdAt));
                  }
                },
                child: _HistoryCard(
                  icon: Icons.call_received_rounded,
                  title: receivable.debtorName,
                  subtitle: context.l10n.vadeTarihLabel(
                      DateFormat('dd MMM yyyy').format(receivable.dueDate)),
                  amount: receivable.amount,
                  currency: currency,
                  badge: context.l10n.badgeTahsilEdildi,
                ),
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
  final String currency;

  const _HistorySummaryCard({
    required this.text,
    required this.amount,
    required this.currency,
  });

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
            formatMoney(amount, currency: currency),
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
  final String currency;
  final String badge;

  const _HistoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
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
                formatMoney(amount, currency: currency),
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
