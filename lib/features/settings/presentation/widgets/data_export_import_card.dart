import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/features/settings/presentation/blocs/data_export_import/data_export_import_cubit.dart';
import 'package:cunehat/features/settings/presentation/blocs/data_export_import/data_export_import_state.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/config/di/injection.dart';

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
          IboSnackbar.showSuccess(context, state.message);
        } else if (state is DataExportImportError) {
          IboSnackbar.showError(context, state.message);
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
                    'İşlem Dışa / İçe Aktar',
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
                'Tüm işlemlerinizi standart CSV formatında dışa aktararak diğer uygulamalarda kullanabilir veya yedekleyebilirsiniz.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              final appAuthState =
                                  context.read<AppAuthBloc>().state;
                              String? userId;
                              if (appAuthState is AppAuthenticated) {
                                userId = appAuthState.user.uid;
                              } else if (appAuthState is AppAuthLocked) {
                                userId = appAuthState.user.uid;
                              }

                              if (userId != null) {
                                context
                                    .read<DataExportImportCubit>()
                                    .importTransactions(userId);
                              }
                            },
                      icon: const Icon(Icons.file_download_rounded),
                      label: const Text('İçe Aktar (CSV)'),
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
                              final appAuthState =
                                  context.read<AppAuthBloc>().state;
                              String? userId;
                              if (appAuthState is AppAuthenticated) {
                                userId = appAuthState.user.uid;
                              } else if (appAuthState is AppAuthLocked) {
                                userId = appAuthState.user.uid;
                              }

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
                                    .exportTransactions(userId, walletId);
                              } else {
                                IboSnackbar.showWarning(context,
                                    "Dışa aktarım için aktif bir cüzdan gereklidir.");
                              }
                            },
                      icon: const Icon(Icons.file_upload_rounded),
                      label: const Text('Dışa Aktar (CSV)'),
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
}
