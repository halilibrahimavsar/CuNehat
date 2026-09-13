import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/error/error_log.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';

/// Cihazda tutulan hata günlüğünün ([ErrorLog]) görüntülendiği yüzey.
///
/// Cihazda yaşanan bir hatanın release'teki tek somut izi burası. Kayıt
/// kendiliğinden hiçbir yere gitmez; tester sorun bildirirken tek dokunuşla
/// kopyalayıp gönderebilir.
class ErrorLogPage extends StatefulWidget {
  const ErrorLogPage({super.key});

  @override
  State<ErrorLogPage> createState() => _ErrorLogPageState();
}

class _ErrorLogPageState extends State<ErrorLogPage> {
  // Günlük canlı DİNLENMEZ: hata yakalayıcı build sırasında da çağrılabilir
  // ve oradan tetiklenen bir setState ikinci bir hata turu başlatırdı. Sayfa
  // açılışta ve kendi eylemlerinden sonra anlık görüntüyü okur.
  List<ErrorLogEntry> _entries = ErrorLog.instance.entries;

  Future<void> _copy() async {
    final l10n = context.l10n;
    await Clipboard.setData(
      ClipboardData(text: ErrorLog.instance.formatForShare()),
    );
    AppMessenger.success(l10n.errorLogCopied);
  }

  Future<void> _share() async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: ErrorLog.instance.formatForShare()),
      );
    } catch (e, st) {
      reportError('Hata günlüğü paylaşımı', e, st);
      // Paylaşım sayfası açılamadıysa içerik yine de kullanıcıya ulaşsın.
      if (!mounted) return;
      await _copy();
    }
  }

  Future<void> _clear() async {
    final l10n = context.l10n;
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.errorLogClearConfirmTitle,
      message: l10n.errorLogClearConfirmDesc,
      confirmText: l10n.temizle,
      danger: true,
    );
    if (!confirmed) return;
    await ErrorLog.instance.clear();
    if (!mounted) return;
    setState(() => _entries = ErrorLog.instance.entries);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasEntries = _entries.isNotEmpty;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.errorLogTitle),
        actions: [
          IconButton(
            tooltip: l10n.errorLogCopy,
            icon: const Icon(Icons.copy_rounded),
            onPressed: hasEntries ? _copy : null,
          ),
          IconButton(
            tooltip: l10n.errorLogShare,
            icon: const Icon(Icons.share_rounded),
            onPressed: hasEntries ? _share : null,
          ),
          IconButton(
            tooltip: l10n.temizle,
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: hasEntries ? _clear : null,
          ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(16, 16, 16, 32).plusSystemBottom(context),
        children: [
          Text(
            l10n.errorLogPrivacyNote,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (!hasEntries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  l10n.errorLogEmpty,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final entry in _entries) ...[
              _EntryCard(entry: entry),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final ErrorLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stack = entry.stack;
    final meta = [
      ErrorLog.formatTimestamp(entry.at),
      entry.source,
      if (entry.repeat > 1) '×${entry.repeat}',
    ].join(' · ');

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        // Kart zaten çerçeveli; ExpansionTile'ın açıkken çizdiği üst/alt
        // çizgiler kartın içinde ikinci bir çerçeve oluşturur.
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          '${entry.type}: ${entry.message}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        subtitle: Text(
          meta,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            [
              entry.message,
              if (stack != null && stack.isNotEmpty) stack,
            ].join('\n\n'),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
