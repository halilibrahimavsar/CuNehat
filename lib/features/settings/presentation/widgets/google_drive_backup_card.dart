import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

class GoogleDriveBackupCard extends StatefulWidget {
  const GoogleDriveBackupCard({super.key});

  @override
  State<GoogleDriveBackupCard> createState() => _GoogleDriveBackupCardState();
}

class _GoogleDriveBackupCardState extends State<GoogleDriveBackupCard> {
  final GoogleDriveBackupService _backupService =
      getIt<GoogleDriveBackupService>();
  final SharedPreferences _prefs = getIt<SharedPreferences>();

  bool _isLoading = false;
  bool _isConnected = false;
  String _userEmail = '';
  String? _lastBackup;

  static const String _lastBackupKey = 'last_google_drive_backup_time';

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    final isConnected = await _backupService.silentSignIn();
    final lastBackupTime = _prefs.getString(_lastBackupKey);

    setState(() {
      _isConnected = isConnected;
      if (isConnected && _backupService.currentUser != null) {
        _userEmail = _backupService.currentUser!.email;
      }
      if (lastBackupTime != null) {
        _lastBackup = lastBackupTime;
      }
      _isLoading = false;
    });
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    final success = await _backupService.signIn();
    setState(() {
      _isConnected = success;
      if (success && _backupService.currentUser != null) {
        _userEmail = _backupService.currentUser!.email;
      }
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        _showSnackBar(context.l10n.googleDriveConnected, Colors.green);
      }
    } else {
      if (mounted) {
        _showSnackBar(context.l10n.googleDriveConnectionFailed, Colors.red);
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    await _backupService.signOut();
    setState(() {
      _isConnected = false;
      _userEmail = '';
      _isLoading = false;
    });
    if (mounted) {
      _showSnackBar(context.l10n.googleDriveDisconnected, Colors.orange);
    }
  }

  Future<void> _backup() async {
    setState(() => _isLoading = true);
    final success = await _backupService.backup();
    if (success) {
      final nowStr = _formatDateTime(DateTime.now());
      await _prefs.setString(_lastBackupKey, nowStr);
      setState(() {
        _lastBackup = nowStr;
      });
      if (mounted) {
        _showSnackBar(context.l10n.dataBackedUpSuccess, Colors.green);
      }
    } else {
      if (mounted) {
        _showSnackBar(context.l10n.backupFailed, Colors.red);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _restore() async {
    final confirm = await IboDialog.showConfirmation(
      context,
      context.l10n.restoreDataTitle,
      context.l10n.restoreDataDesc,
      confirmText: context.l10n.geriYukle,
      cancelText: context.l10n.cancelLabel,
      style: IboDialogStyle(
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _backupService.restore();
    if (success) {
      if (mounted) {
        final authState = context.read<AppAuthBloc>().state;
        String? userId;
        if (authState is AppAuthenticated) {
          userId = authState.user.uid;
        } else if (authState is AppAuthLocked) {
          userId = authState.user.uid;
        }

        getIt<TransactionsChangedNotifier>().notify(userId: userId);
        if (userId != null) {
          context.read<WalletBloc>().add(GetWalletsEvent(userId));
        }

        _showSnackBar(
          context.l10n.dataRestoredSuccess,
          Colors.green,
        );
      }
    } else {
      if (mounted) {
        _showSnackBar(context.l10n.restoreFailedNoBackup, Colors.red);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteBackup() async {
    final confirm = await IboDialog.showConfirmation(
      context,
      context.l10n.deleteBackup,
      context.l10n.deleteBackupDesc,
      confirmText: context.l10n.deleteBackup,
      cancelText: context.l10n.cancelLabel,
      style: IboDialogStyle(
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _backupService.deleteBackup();
    if (success) {
      await _prefs.remove(_lastBackupKey);
      if (mounted) {
        setState(() => _lastBackup = null);
        _showSnackBar(context.l10n.backupDeleted, Colors.green);
      }
    } else {
      if (mounted) {
        _showSnackBar(context.l10n.deleteBackupFailed, Colors.red);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message, Color color) {
    if (color == Colors.green) {
      IboSnackbar.showSuccess(context, message);
    } else if (color == Colors.red) {
      IboSnackbar.showError(context, message);
    } else if (color == Colors.orange) {
      IboSnackbar.showWarning(context, message);
    } else {
      IboSnackbar.showInfo(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  Icons.cloud_queue_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.googleDriveBackup,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
            ],
          ),
          const SizedBox(height: 16),
          if (!_isConnected) ...[
            Text(
              context.l10n.googleDriveBackupDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _connect,
                icon: const Icon(Icons.link_rounded),
                label: Text(context.l10n.connectGoogleDrive),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.account,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _userEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.lastBackup,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _lastBackup ?? context.l10n.noBackupsYet,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _restore,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(context.l10n.geriYukle),
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
                    onPressed: _isLoading ? null : _backup,
                    icon: const Icon(Icons.upload_rounded),
                    label: Text(context.l10n.yedekle),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _deleteBackup,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                label: Text(
                  context.l10n.deleteBackup,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _disconnect,
                icon:
                    const Icon(Icons.link_off_rounded, color: Colors.redAccent),
                label: Text(
                  context.l10n.disconnect,
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
