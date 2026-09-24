import 'package:flutter/material.dart';

import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';

/// "İçe aktarımı geri al": onay → çalışıyor → sonuç, TEK diyalogda.
///
/// Eskiden düğme onaysız çalışıyordu (tek dokunuş = N işlem silinir) ve
/// sonuç 3 saniyelik bir snackbar'daydı; bağlı satırların neden yerinde
/// kaldığını anlatan iki cümlelik metin o sürede okunamıyordu. Şimdi kullanıcı
/// neyin silineceğini önceden, neyin silindiğini sonradan kendi hızında okur.
///
/// [cubit] açıkça verilir: diyaloğun context'i sayfadaki `BlocProvider`ın
/// altında değil (diyalog kök Navigator'da açılır).
Future<void> showImportUndoDialog(
  BuildContext context, {
  required BankImportCubit cubit,
  required BankImportDone done,
}) {
  return _show(
    context,
    plan: ImportUndoPlan(
      added: done.added,
      corrected: done.corrected,
      cardStatement: done.cardStatementSaved,
    ),
    onUndo: cubit.undoImport,
  );
}

/// Geçmişteki bir içe aktarımı ("Son içe aktarımlar") geri alma diyaloğu.
Future<void> showBatchUndoDialog(
  BuildContext context, {
  required BankImportCubit cubit,
  required ImportBatch batch,
  required String userId,
}) {
  return _show(
    context,
    plan: ImportUndoPlan(added: batch.count, later: true),
    onUndo: () => cubit.undoBatch(batch, userId: userId),
  );
}

Future<void> _show(
  BuildContext context, {
  required ImportUndoPlan plan,
  required Future<ImportUndoResult> Function() onUndo,
}) {
  return showDialog<void>(
    context: context,
    // Çalışırken dışarı dokunup kapatmak yazımı durdurmaz, yalnız sonucu
    // kaybettirirdi; onay evresinde de açık bir "İptal" var.
    barrierDismissible: false,
    builder: (_) => ImportUndoDialog(plan: plan, onUndo: onUndo),
  );
}

/// Onay evresinde neyin geri alınacağı.
class ImportUndoPlan {
  /// Silinecek (eklenmiş) satır sayısı.
  final int added;

  /// Eski tutarına dönecek (düzeltilmiş) kayıt sayısı.
  final int corrected;

  /// Kartın son ekstre bilgisi geri çevrilecek mi.
  final bool cardStatement;

  /// Bitiş ekranından çıkıldıktan SONRA mı (geçmiş listesinden): tutar
  /// düzeltmeleri ve kart künyesi o yoldan geri alınamaz, kullanıcı bilmeli.
  final bool later;

  const ImportUndoPlan({
    required this.added,
    this.corrected = 0,
    this.cardStatement = false,
    this.later = false,
  });
}

enum _Phase { confirm, running, result }

class ImportUndoDialog extends StatefulWidget {
  final ImportUndoPlan plan;
  final Future<ImportUndoResult> Function() onUndo;

  const ImportUndoDialog({super.key, required this.plan, required this.onUndo});

  @override
  State<ImportUndoDialog> createState() => _ImportUndoDialogState();
}

class _ImportUndoDialogState extends State<ImportUndoDialog> {
  _Phase _phase = _Phase.confirm;
  ImportUndoResult _result = ImportUndoResult.none;

  Future<void> _run() async {
    setState(() => _phase = _Phase.running);
    final result = await widget.onUndo();
    if (!mounted) return;
    setState(() {
      _result = result;
      _phase = _Phase.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _phase != _Phase.running,
      child: AppDialogSurface(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: switch (_phase) {
            _Phase.confirm => _confirm(context),
            _Phase.running => _running(context),
            _Phase.result => _resultView(context),
          },
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String text,
      {IconData? icon, Color? color}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color ?? cs.primary, size: 22),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  /// Madde satırı: ikon + metin.
  Widget _line(BuildContext context, IconData icon, String text,
      {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _confirm(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final d = widget.plan;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, l10n.bankImportUndoTitle,
            icon: Icons.warning_rounded, color: cs.error),
        const SizedBox(height: 4),
        if (d.added > 0)
          _line(
              context,
              Icons.delete_outline_rounded,
              d.later
                  ? l10n.bankImportUndoWillRemoveBatch(d.added)
                  : l10n.bankImportUndoWillRemove(d.added),
              color: cs.error),
        if (d.corrected > 0)
          _line(context, Icons.history_rounded,
              l10n.bankImportUndoWillRevert(d.corrected)),
        if (d.cardStatement)
          _line(
              context, Icons.credit_card_rounded, l10n.bankImportUndoWillCard),
        if (d.added > 0)
          _line(context, Icons.link_rounded, l10n.bankImportUndoWillKeepLinked),
        if (d.later)
          _line(context, Icons.info_outline_rounded,
              l10n.bankImportUndoLaterNote),
        const SizedBox(height: 20),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.iptal),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: _run,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: Text(l10n.geriAl),
            ),
          ],
        ),
      ],
    );
  }

  Widget _running(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(context.l10n.bankImportUndoRunning)),
        ],
      ),
    );
  }

  Widget _resultView(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final r = _result;
    final nothing = r.removed == 0 &&
        r.reverted == 0 &&
        r.kept == 0 &&
        !r.cardStatementReverted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, l10n.bankImportUndoDoneTitle,
            icon: Icons.check_circle_rounded, color: Colors.green),
        const SizedBox(height: 4),
        if (nothing)
          _line(
              context, Icons.info_outline_rounded, l10n.bankImportUndoNothing),
        if (r.removed > 0)
          _line(context, Icons.delete_outline_rounded,
              l10n.bankImportUndoRemoved(r.removed)),
        if (r.reverted > 0)
          _line(context, Icons.history_rounded,
              l10n.bankImportUndoReverted(r.reverted)),
        if (r.cardStatementReverted)
          _line(context, Icons.credit_card_rounded,
              l10n.bankImportUndoCardReverted),
        if (r.kept > 0)
          _line(context, Icons.link_rounded, l10n.bankImportUndoKept(r.kept),
              color: cs.tertiary),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.tamam),
          ),
        ),
      ],
    );
  }
}
