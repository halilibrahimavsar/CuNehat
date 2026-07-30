import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/auto_backup_service.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/utils/byte_format.dart';
import 'package:cunehat/core/utils/drive_status_messages.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Google Drive yedekleme kartı.
///
/// Durum göstergesinin doğruluk kaynağı **Drive'ın kendisidir** (dosya listesi
/// + `modifiedTime`), yerel bir tercih değeri değil: eskiden "son yedekleme"
/// prefs'te biçimlenmiş bir metindi ve uygulama yeniden kurulunca "hiç yedek
/// yok" görünüyordu — oysa yedek Drive'da duruyordu.
class GoogleDriveBackupCard extends StatefulWidget {
  const GoogleDriveBackupCard({super.key});

  @override
  State<GoogleDriveBackupCard> createState() => _GoogleDriveBackupCardState();
}

class _GoogleDriveBackupCardState extends State<GoogleDriveBackupCard> {
  final GoogleDriveBackupService _backupService =
      getIt<GoogleDriveBackupService>();
  final AutoBackupService _autoBackup = getIt<AutoBackupService>();

  bool _isLoading = false;
  bool _isConnected = false;
  String _userEmail = '';

  /// Drive'dan okunan en yeni yedek. null → hiç yedek yok.
  DriveBackupFile? _latestBackup;
  int _backupCount = 0;

  /// Bağlantı denemesi kod hatası olmayan bir sebeple başarısızsa (yapılandırma
  /// eksik, ağ yok) kullanıcı bunu görmeli — kart "bağlı değil" deyip sebebi
  /// yutmamalı.
  DriveOperationStatus? _connectionIssue;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);

    final signIn = await _backupService.silentSignIn();
    DriveResult<List<DriveBackupFile>>? listed;
    if (signIn.isSuccess) {
      listed = await _backupService.listBackups();
    }

    if (!mounted) return;
    setState(() {
      _isConnected = signIn.isSuccess;
      _userEmail = _backupService.currentUser?.email ?? '';
      // "Bağlı değil" beklenen bir durum, hata değil: sadece gerçek arızalar
      // (yapılandırma, ağ, kapsam) banda düşer.
      _connectionIssue = switch (signIn.status) {
        DriveOperationStatus.success => null,
        DriveOperationStatus.notSignedIn => null,
        final status => status,
      };
      final files = listed?.data;
      _latestBackup = (files == null || files.isEmpty) ? null : files.first;
      _backupCount = files?.length ?? 0;
      _isLoading = false;
    });
  }

  // ================================================================= eylemler

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    final result = await _backupService.signIn();
    if (!mounted) return;

    if (result.isSuccess) {
      AppMessenger.success(context.l10n.googleDriveConnected);
      await _refreshStatus();
      return;
    }

    setState(() => _isLoading = false);
    // İptal bir hata değil: kullanıcı hesap seçiciyi kapattı.
    if (!result.isCancelled) {
      AppMessenger.error(driveStatusMessage(context.l10n, result.status));
    }
  }

  Future<void> _disconnect() async {
    // Hangi hesaptan çıkıldığı AÇIKÇA yazılır: birden çok Google hesabı olan
    // kullanıcı, yedeklerinin hangi hesapta kaldığını burada görmezse tekrar
    // bağlanırken yanlış hesabı seçip "yedeklerim kayboldu" sanır.
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.disconnectConfirmTitle,
      message: context.l10n.disconnectConfirmDesc(_userEmail),
      confirmText: context.l10n.disconnect,
      cancelText: context.l10n.cancelLabel,
      danger: true,
      countdownSeconds: 5,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isLoading = true);
    await _backupService.signOut();
    // Hesap değişebilir: önceki hesabın otomatik yedek geçmişi (son başarı,
    // içerik damgası, hata serisi) yeni hesap için anlamsız ve yanıltıcıdır.
    await _autoBackup.clearState();

    if (!mounted) return;
    setState(() {
      _isConnected = false;
      _userEmail = '';
      _latestBackup = null;
      _backupCount = 0;
      _connectionIssue = null;
      _isLoading = false;
    });
    AppMessenger.warning(context.l10n.googleDriveDisconnected);
  }

  Future<void> _backup() async {
    setState(() => _isLoading = true);
    var result = await _backupService.backup();

    // Boş veri kapısı: reddetmek yerine kullanıcıya NE OLACAĞINI söyleyip
    // kararı ona bırak. Sessizce ezmek eski davranıştı ve veri kaybı yoluydu.
    if (result.status == DriveOperationStatus.emptyLocalData && mounted) {
      // Kullanıcı yanıtı beklenirken çalışan bir iş YOK: spinner'ı bırakmak
      // hem yanlış bilgi verir hem de dönen gösterge onayın arkasında kalır.
      setState(() => _isLoading = false);

      final confirmed = await ConfirmDialog.show(
        context,
        title: context.l10n.backupEmptyConfirmTitle,
        message: context.l10n.backupEmptyConfirmDesc,
        confirmText: context.l10n.backupEmptyConfirmAction,
        cancelText: context.l10n.cancelLabel,
        danger: true,
      );
      if (!confirmed || !mounted) return;

      setState(() => _isLoading = true);
      result = await _backupService.backup(allowEmpty: true);
    }

    if (!mounted) return;

    if (result.isSuccess) {
      AppMessenger.success(context.l10n.dataBackedUpSuccess);
      await _refreshStatus();
      return;
    }

    setState(() => _isLoading = false);
    if (!result.isCancelled) {
      AppMessenger.error(driveStatusMessage(context.l10n, result.status));
    }
  }

  Future<void> _restoreLatest() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: context.l10n.restoreDataTitle,
      message: context.l10n.restoreDataDesc,
      confirmText: context.l10n.geriYukle,
      cancelText: context.l10n.cancelLabel,
      danger: true,
    );
    if (!confirm || !mounted) return;

    setState(() => _isLoading = true);
    final userId = _currentUserId();
    final walletBloc = context.read<WalletBloc>();

    final result = await _backupService.restoreLatest();

    if (result.isSuccess) {
      // Geri yükleme defteri VE kategori tercihlerini değiştirir; ikisi ayrı
      // kanal. Kategori kanalı bildirilmediği için uygulama eskiden
      // "yeniden başlatın" demek zorundaydı.
      getIt<TransactionsChangedNotifier>().notify(userId: userId);
      getIt<CategoriesChangedNotifier>().notify();
      if (userId != null) walletBloc.add(GetWalletsEvent(userId));
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      AppMessenger.success(context.l10n.dataRestoredSuccess);
    } else if (!result.isCancelled) {
      AppMessenger.error(driveStatusMessage(
        context.l10n,
        result.status,
        foundSchemaVersion: result.foundSchemaVersion,
        expectedSchemaVersion: DataSerializationService.schemaVersion,
      ));
    }
  }

  Future<void> _deleteAllBackups() async {
    // "Tüm veriyi sil" ile aynı iki adımlı kapı: bu eylem kullanıcının TEK
    // kurtarma yolunu yok eder — cihaz verisi de giderse geri dönüş kalmaz.
    final step1 = await ConfirmDialog.show(
      context,
      title: context.l10n.deleteAllBackups,
      message: context.l10n.deleteAllBackupsDesc,
      confirmText: context.l10n.sil,
      cancelText: context.l10n.cancelLabel,
    );
    if (!step1 || !mounted) return;

    final step2 = await ConfirmDialog.show(
      context,
      title: context.l10n.irreversibleActionTitle,
      message: context.l10n.deleteAllBackupsDangerDesc(_backupCount),
      confirmText: context.l10n.sil,
      cancelText: context.l10n.cancelLabel,
      danger: true,
      countdownSeconds: 5,
    );
    if (!step2 || !mounted) return;

    setState(() => _isLoading = true);
    final result = await _backupService.deleteAllBackups();
    if (!mounted) return;

    if (result.isSuccess) {
      await _autoBackup.clearState();
      if (!mounted) return;
      AppMessenger.success(context.l10n.backupDeleted);
      await _refreshStatus();
      return;
    }

    setState(() => _isLoading = false);
    if (!result.isCancelled) {
      AppMessenger.error(driveStatusMessage(context.l10n, result.status));
    }
  }

  Future<void> _setAutoBackup(AutoBackupFrequency value) async {
    await _autoBackup.setFrequency(value);
    if (mounted) setState(() {});
  }

  String? _currentUserId() {
    final authState = context.read<AppAuthBloc>().state;
    if (authState is AppAuthenticated) return authState.user.uid;
    if (authState is AppAuthLocked) return authState.user.uid;
    return null;
  }

  // =================================================================== görünüm

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
          if (_connectionIssue != null) ...[
            _Banner(
              tone: _BannerTone.danger,
              icon: Icons.error_outline_rounded,
              message: driveStatusMessage(context.l10n, _connectionIssue!),
            ),
            const SizedBox(height: 12),
          ],
          if (!_isConnected)
            ..._disconnectedBody(theme, colorScheme)
          else
            ..._connectedBody(theme, colorScheme),
        ],
      ),
    );
  }

  List<Widget> _disconnectedBody(ThemeData theme, ColorScheme colorScheme) {
    return [
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
    ];
  }

  List<Widget> _connectedBody(ThemeData theme, ColorScheme colorScheme) {
    final l = context.l10n;
    final latest = _latestBackup;

    return [
      if (_autoBackup.hasPersistentFailure) ...[
        _Banner(
          tone: _BannerTone.warning,
          icon: Icons.sync_problem_rounded,
          message: l.autoBackupFailureWarning(_autoBackup.consecutiveFailures),
        ),
        const SizedBox(height: 12),
      ],
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            _InfoRow(label: l.account, value: _userEmail),
            const SizedBox(height: 8),
            _InfoRow(
              label: l.lastBackup,
              value: latest == null
                  ? l.noBackupsYet
                  : AppFormatters.dateTime.format(latest.modifiedTime),
            ),
            if (latest != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                label: l.backupSizeLabel,
                value: '${formatBytes(latest.sizeBytes)}'
                    ' · ${l.backupGenerationsKept(_backupCount)}',
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed:
                  (_isLoading || _latestBackup == null) ? null : _restoreLatest,
              icon: const Icon(Icons.download_rounded),
              label: Text(l.geriYukle),
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
              label: Text(l.yedekle),
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
        child: OutlinedButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  await context.push(AppRoutes.backupPreview);
                  // Önizleme ekranında silme/geri yükleme olmuş olabilir.
                  if (mounted) await _refreshStatus();
                },
          icon: const Icon(Icons.visibility_outlined),
          label: Text(l.viewBackups),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: colorScheme.outline),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _AutoBackupSection(
        frequency: _autoBackup.frequency,
        lastSuccessAt: _autoBackup.lastSuccessAt,
        onChanged: _isLoading ? null : _setAutoBackup,
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed:
              (_isLoading || _backupCount == 0) ? null : _deleteAllBackups,
          icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
          label: Text(
            l.deleteAllBackups,
            style: TextStyle(color: colorScheme.error),
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
          icon: Icon(Icons.link_off_rounded, color: colorScheme.error),
          label: Text(
            l.disconnect,
            style: TextStyle(color: colorScheme.error),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    ];
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

enum _BannerTone { warning, danger }

/// Kart içi kalıcı durum şeridi. Snackbar DEĞİL: kalıcı bir arıza (yanlış
/// yapılandırma, üst üste başarısız otomatik yedek) 3 saniyede kaybolmamalı.
class _Banner extends StatelessWidget {
  final _BannerTone tone;
  final IconData icon;
  final String message;

  const _Banner({
    required this.tone,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = tone == _BannerTone.danger
        ? theme.colorScheme.error
        : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _AutoBackupSection extends StatelessWidget {
  final AutoBackupFrequency frequency;
  final DateTime? lastSuccessAt;
  final ValueChanged<AutoBackupFrequency>? onChanged;

  const _AutoBackupSection({
    required this.frequency,
    required this.lastSuccessAt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.autoBackup,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.autoBackupDesc,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        SegmentedButton<AutoBackupFrequency>(
          segments: [
            ButtonSegment(
              value: AutoBackupFrequency.off,
              label: Text(l.autoBackupOff),
            ),
            ButtonSegment(
              value: AutoBackupFrequency.daily,
              label: Text(l.autoBackupDaily),
            ),
            ButtonSegment(
              value: AutoBackupFrequency.weekly,
              label: Text(l.autoBackupWeekly),
            ),
          ],
          selected: {frequency},
          showSelectedIcon: false,
          onSelectionChanged:
              onChanged == null ? null : (set) => onChanged!(set.first),
        ),
        if (frequency != AutoBackupFrequency.off) ...[
          const SizedBox(height: 8),
          // Sınırı açıkça yaz: "koruma altındasınız" izlenimi vermek, uygulama
          // haftalarca açılmadığında gerçek olmayan bir güven yaratırdı.
          Text(
            l.autoBackupLimitNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
