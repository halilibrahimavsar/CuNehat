import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/utils/byte_format.dart';
import 'package:cunehat/core/utils/drive_status_messages.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/settings/presentation/blocs/backup_preview/backup_preview_cubit.dart';
import 'package:cunehat/features/settings/presentation/blocs/backup_preview/backup_preview_state.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

/// Yedeklerin içine BAKMA ekranı (Ayarlar → Google Drive → Yedekleri Görüntüle).
///
/// `drive.appdata` yedeği kullanıcıdan gizler: Drive arayüzünde görünmez, başka
/// hiçbir uygulama okuyamaz. Bu ekran olmadan "yedeğimde ne var" sorusunun tek
/// cevabı üzerine geri yükleyip bakmaktı — yani yıkıcı bir teşhis.
///
/// Aynı ekran cihazdaki `.json` yedeklerini de okur; ikisi de yazmadan
/// özetlenir ve geri yükleme öncesi FARK gösterilir.
class BackupPreviewPage extends StatelessWidget {
  const BackupPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BackupPreviewCubit>()..loadList(),
      child: const _BackupPreviewView(),
    );
  }
}

class _BackupPreviewView extends StatelessWidget {
  const _BackupPreviewView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BackupPreviewCubit, BackupPreviewState>(
      builder: (context, state) {
        final isDetail = state is BackupPreviewDetailLoaded ||
            state is BackupPreviewDetailFailed;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isDetail
                  ? context.l10n.backupPreviewDetailTitle
                  : context.l10n.backupPreviewTitle,
            ),
            leading: isDetail
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () =>
                        context.read<BackupPreviewCubit>().loadList(),
                  )
                : null,
          ),
          body: switch (state) {
            BackupPreviewListLoading() => const _Busy(),
            BackupPreviewDetailLoading() =>
              _Busy(label: context.l10n.backupPreviewLoading),
            BackupPreviewRestoring() =>
              _Busy(label: context.l10n.backupPreviewLoading),
            BackupPreviewListLoaded() => _ListView(state: state),
            BackupPreviewListFailed() => _FailureView(
                status: state.status,
                onRetry: () => context.read<BackupPreviewCubit>().loadList(),
              ),
            BackupPreviewDetailLoaded() => _DetailView(state: state),
            BackupPreviewDetailFailed() => _FailureView(
                status: state.status,
                onRetry: () => context.read<BackupPreviewCubit>().loadList(),
              ),
          },
        );
      },
    );
  }
}

// ================================================================== yardımcı

class _Busy extends StatelessWidget {
  final String? label;
  const _Busy({this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!),
          ],
        ],
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  final DriveOperationStatus status;
  final VoidCallback onRetry;

  const _FailureView({required this.status, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              driveStatusMessage(context.l10n, status),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.bankImportRetry),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================== liste

class _ListView extends StatelessWidget {
  final BackupPreviewListLoaded state;
  const _ListView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.l10n.backupPreviewDriveSection,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (state.files.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              context.l10n.backupPreviewEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final file in state.files) ...[
            _DriveFileCard(file: file),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.read<BackupPreviewCubit>().openDeviceFile(),
          icon: const Icon(Icons.folder_open_rounded),
          label: Text(context.l10n.backupPreviewLocalButton),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _DriveFileCard extends StatelessWidget {
  final DriveBackupFile file;
  const _DriveFileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = context.l10n;

    return AppCard(
      onTap: () => context.read<BackupPreviewCubit>().openDriveBackup(file),
      child: Row(
        children: [
          Icon(
            file.origin == BackupOrigin.auto
                ? Icons.schedule_rounded
                : Icons.cloud_done_rounded,
            color: cs.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppFormatters.dateTime.format(file.modifiedTime),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_originLabel(l, file.origin)} · '
                  '${file.transactionCount?.toString() ?? l.backupPreviewUnknownCount}'
                  ' ${l.backupPreviewTransactions.toLowerCase()} · '
                  '${formatBytes(file.sizeBytes)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

String _originLabel(AppLocalizations l, BackupOrigin origin) =>
    switch (origin) {
      BackupOrigin.auto => l.backupPreviewOriginAuto,
      BackupOrigin.manual => l.backupPreviewOriginManual,
      BackupOrigin.unknown => l.backupPreviewUnknownCount,
    };

// ===================================================================== detay

class _DetailView extends StatelessWidget {
  final BackupPreviewDetailLoaded state;
  const _DetailView({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final inspection = state.inspection;
    final summary = inspection.summary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SourceCard(source: state.source),
        const SizedBox(height: 12),

        // Geri yüklenemeyen yedekte içerik özeti yoktur; sebebi tek başına
        // gösterilir. "Bulunamadı" demek yerine NEDEN olmadığını söyler.
        if (summary == null) ...[
          _WarningCard(
            icon: Icons.block_rounded,
            tone: _WarningTone.danger,
            message: inspection.status == BackupInspectionStatus.versionMismatch
                ? l.driveErrVersionMismatch(
                    '${inspection.foundVersion}',
                    inspection.expectedVersion,
                  )
                : l.driveErrCorrupt,
          ),
        ] else ...[
          if (summary.isEmpty)
            _WarningCard(
              icon: Icons.warning_amber_rounded,
              tone: _WarningTone.danger,
              message: l.backupPreviewEmptyWarning,
            ),
          if (summary.transactionsWithReceipt > 0)
            _WarningCard(
              icon: Icons.receipt_long_rounded,
              tone: _WarningTone.info,
              message: l
                  .backupPreviewReceiptWarning(summary.transactionsWithReceipt),
            ),
          _ContentsCard(backup: summary, device: state.deviceSummary),
          const SizedBox(height: 12),
          if (summary.wallets.isNotEmpty) _WalletsCard(summary: summary),
          const SizedBox(height: 12),
          _TotalsCard(summary: summary),
        ],

        const SizedBox(height: 20),
        _DetailActions(state: state),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final BackupPreviewSource source;
  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;

    final (String title, String subtitle, IconData icon) = switch (source) {
      DriveBackupSource(:final file) => (
          AppFormatters.dateTime.format(file.modifiedTime),
          '${_originLabel(l, file.origin)} · ${formatBytes(file.sizeBytes)}'
              ' · ${l.backupPreviewSchemaVersion} '
              '${file.schemaVersion ?? l.backupPreviewUnknownCount}',
          Icons.cloud_rounded,
        ),
      DeviceFileBackupSource(:final fileName) => (
          fileName,
          l.backupPreviewLocalSource,
          Icons.insert_drive_file_rounded,
        ),
    };

    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

enum _WarningTone { info, danger }

class _WarningCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final _WarningTone tone;

  const _WarningCard({
    required this.icon,
    required this.message,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = tone == _WarningTone.danger ? cs.error : cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        accent: accent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fark paneli: cihazdaki mevcut veri → yedekteki veri.
///
/// Bu ekranın en kritik parçası. Kullanıcı "geri yükle"ye basmadan ÖNCE ne
/// kaybedeceğini görmeli. Kutupluluk yalnız renkle değil işaretle (+/−) de
/// verilir: yeşil/kırmızı ayrımı renk körlüğünde güvenilir değil.
class _ContentsCard extends StatelessWidget {
  final BackupSummary backup;
  final BackupSummary device;

  const _ContentsCard({required this.backup, required this.device});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.backupPreviewDiffTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _headerCell(context, l.backupPreviewDiffOnDevice),
              _headerCell(context, l.backupPreviewDiffInBackup),
              const SizedBox(width: 56),
            ],
          ),
          const Divider(height: 12),
          _row(context, l.backupPreviewWallets, device.walletCount,
              backup.walletCount),
          _row(context, l.backupPreviewTransactions, device.transactionCount,
              backup.transactionCount),
          _row(context, l.backupPreviewInvestments, device.investmentCount,
              backup.investmentCount),
          _row(context, l.backupPreviewDebts, device.debtCount,
              backup.debtCount),
          _row(context, l.backupPreviewReceivables, device.receivableCount,
              backup.receivableCount),
          _row(context, l.backupPreviewBudgets, device.budgetCount,
              backup.budgetCount),
          _row(context, l.backupPreviewRecurring, device.recurringCount,
              backup.recurringCount),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String label) {
    return SizedBox(
      width: 64,
      child: Text(
        label,
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _row(
      BuildContext context, String label, int deviceCount, int backupCount) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final delta = backupCount - deviceCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$deviceCount',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$backupCount',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              delta == 0 ? '—' : (delta > 0 ? '+$delta' : '$delta'),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: delta < 0
                    ? cs.error
                    : (delta > 0 ? cs.primary : cs.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletsCard extends StatelessWidget {
  final BackupSummary summary;
  const _WalletsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.backupPreviewWallets,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final wallet in summary.wallets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      wallet.name,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatMoney(wallet.balance, currency: wallet.currency),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final BackupSummary summary;
  const _TotalsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    // Yedek birden çok para birimi içeriyorsa tutarları tek sembolle basmak
    // YANLIŞ olurdu (60 USD + 40 TRY = 100 ₺ değil). Bu durumda sembolsüz
    // sayı gösterilir; tek para birimi varsa onun sembolüyle biçimlenir.
    final currencies = summary.wallets.map((w) => w.currency).toSet();
    String money(double v) => currencies.length == 1
        ? formatMoney(v, currency: currencies.first)
        : formatMoney(v, symbol: false);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.createdAt != null) ...[
            _line(context, l.backupPreviewTakenAt,
                AppFormatters.dateTime.format(summary.createdAt!)),
            const SizedBox(height: 6),
          ],
          _line(
            context,
            l.backupPreviewDateRange,
            summary.firstTransactionDate == null
                ? l.backupPreviewNoTransactions
                : '${AppFormatters.dateShort.format(summary.firstTransactionDate!)}'
                    ' – '
                    '${AppFormatters.dateShort.format(summary.lastTransactionDate!)}',
          ),
          const SizedBox(height: 6),
          _line(context, l.backupPreviewIncome, money(summary.totalIncome)),
          const SizedBox(height: 6),
          _line(context, l.backupPreviewExpense, money(summary.totalExpense)),
          const SizedBox(height: 6),
          _line(context, l.backupPreviewCategories, '${summary.categoryCount}'),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _DetailActions extends StatelessWidget {
  final BackupPreviewDetailLoaded state;
  const _DetailActions({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final source = state.source;

    return Column(
      children: [
        if (state.inspection.isRestorable)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _restore(context),
              icon: const Icon(Icons.restore_rounded),
              label: Text(l.backupPreviewRestoreButton),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        if (source is DriveBackupSource) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _delete(context, source.file),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                l.backupPreviewDeleteButton,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _restore(BuildContext context) async {
    final l = context.l10n;
    final confirmed = await ConfirmDialog.show(
      context,
      title: l.backupPreviewRestoreConfirmTitle,
      message: l.backupPreviewRestoreConfirmDesc,
      confirmText: l.geriYukle,
      cancelText: l.cancelLabel,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    final userId = _currentUserId(context);
    final cubit = context.read<BackupPreviewCubit>();
    final walletBloc = context.read<WalletBloc>();

    final status = await cubit.restoreCurrent(userId: userId);

    if (status == DriveOperationStatus.success) {
      if (userId != null) walletBloc.add(GetWalletsEvent(userId));
      AppMessenger.success(l.dataRestoredSuccess);
    } else {
      AppMessenger.error(driveStatusMessage(l, status));
    }
  }

  Future<void> _delete(BuildContext context, DriveBackupFile file) async {
    final l = context.l10n;
    final confirmed = await ConfirmDialog.show(
      context,
      title: l.backupPreviewDeleteButton,
      message: l.backupPreviewDeleteConfirmDesc,
      confirmText: l.sil,
      cancelText: l.cancelLabel,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    final cubit = context.read<BackupPreviewCubit>();
    final status = await cubit.deleteDriveBackup(file);

    if (status == DriveOperationStatus.success) {
      AppMessenger.success(l.backupDeleted);
    } else {
      AppMessenger.error(driveStatusMessage(l, status));
    }
  }

  String? _currentUserId(BuildContext context) {
    final authState = context.read<AppAuthBloc>().state;
    if (authState is AppAuthenticated) return authState.user.uid;
    if (authState is AppAuthLocked) return authState.user.uid;
    return null;
  }
}
