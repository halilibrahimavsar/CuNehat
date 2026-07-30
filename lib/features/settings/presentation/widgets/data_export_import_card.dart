import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/features/settings/presentation/blocs/data_export_import/data_export_import_cubit.dart';
import 'package:cunehat/features/settings/presentation/blocs/data_export_import/data_export_import_state.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

class DataExportImportCard extends StatelessWidget {
  const DataExportImportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DataExportImportCubit>(),
      child: const _DataExportImportCardContent(),
    );
  }
}

class _DataExportImportCardContent extends StatelessWidget {
  const _DataExportImportCardContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<DataExportImportCubit, DataExportImportState>(
      listener: (context, state) {
        if (state is DataExportImportSuccess) {
          final l = context.l10n;
          switch (state.messageType) {
            case DataExportMessageType.noTransactionsToExport:
              AppMessenger.error(l.disaAktarilacakIslemBulunamadi);
            case DataExportMessageType.noValidTransactionsInCsv:
              AppMessenger.error(l.csvGecerliIslemBulunamadi);
            case DataExportMessageType.exportSuccess:
              AppMessenger.success(l.islemlerDisaAktarildi);
            case DataExportMessageType.importSuccess:
              final msg = state.skippedRows > 0
                  ? '${l.verilerIceAktarildi} ${l.satirAtlandi(state.skippedRows)}'
                  : l.verilerIceAktarildi;
              AppMessenger.success(msg);
            case DataExportMessageType.fullBackupExportSuccess:
              AppMessenger.success(l.fullBackupSaved);
            case DataExportMessageType.fullBackupImportSuccess:
              final userId = _currentUserId(context);
              if (userId != null) {
                context.read<WalletBloc>().add(GetWalletsEvent(userId));
              }
              AppMessenger.success(l.fullBackupRestored);
            case DataExportMessageType.fullBackupShareSuccess:
              AppMessenger.success(l.fullBackupShared);
            case DataExportMessageType.fullBackupCancelled:
              AppMessenger.info(l.fullBackupCancelled);
          }
        } else if (state is DataExportImportVersionMismatch) {
          // Ham istisna metni yerine gerçek sebep: dosya sağlam, sürüm farklı.
          AppMessenger.error(context.l10n.driveErrVersionMismatch(
            state.foundVersion,
            DataSerializationService.schemaVersion,
          ));
        } else if (state is DataExportImportError) {
          AppMessenger.error(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is DataExportImportLoading;

        return AppCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.import_export_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.dataExportImport,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.dataExportImportDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.fullBackup,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          context
                              .read<DataExportImportCubit>()
                              .exportFullBackupToDevice();
                        },
                  icon: const Icon(Icons.save_alt_rounded),
                  label: Text(context.l10n.saveFullBackupToDevice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: context.l10n.restoreFullBackupTitle,
                            message: context.l10n.restoreFullBackupDesc,
                            confirmText: context.l10n.geriYukle,
                            cancelText: context.l10n.cancelLabel,
                            danger: true,
                          );
                          if (!confirmed || !context.mounted) return;

                          context
                              .read<DataExportImportCubit>()
                              .importFullBackupFromDevice(
                                userId: _currentUserId(context),
                              );
                        },
                  icon: const Icon(Icons.restore_rounded),
                  label: Text(context.l10n.restoreFullBackupFromDevice),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<DataExportImportCubit>().shareFullBackup(
                                shareText: context.l10n.fullBackupShareText,
                              );
                        },
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(context.l10n.shareFullBackup),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: colorScheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 14),
              Text(
                context.l10n.transactionCsv,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              final userId = _currentUserId(context);

                              if (userId != null) {
                                context
                                    .read<DataExportImportCubit>()
                                    .importTransactions(userId);
                              }
                            },
                      icon: const Icon(Icons.file_download_rounded),
                      label: Text(context.l10n.iceAktarCsv),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colorScheme.outline),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              final userId = _currentUserId(context);

                              final walletState =
                                  context.read<WalletBloc>().state;
                              String? walletId;
                              if (walletState is WalletLoadedSt &&
                                  walletState.activeWallet != null) {
                                walletId = walletState.activeWallet!.id;
                              }

                              if (userId != null && walletId != null) {
                                context
                                    .read<DataExportImportCubit>()
                                    .exportTransactions(userId, walletId,
                                        shareText:
                                            context.l10n.islemGecmisiCsv);
                              } else {
                                AppMessenger.warning(
                                    context.l10n.activeWalletRequiredForExport);
                              }
                            },
                      icon: const Icon(Icons.file_upload_rounded),
                      label: Text(context.l10n.disaAktarCsv),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String? _currentUserId(BuildContext context) {
    final appAuthState = context.read<AppAuthBloc>().state;
    if (appAuthState is AppAuthenticated) {
      return appAuthState.user.uid;
    }
    if (appAuthState is AppAuthLocked) {
      return appAuthState.user.uid;
    }
    return null;
  }
}
