import 'package:flutter/material.dart';

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';

/// Tekrar sanılan bir satırın altında durur ve üç soruyu cevaplar: NEYLE
/// eşleşti, NEDEN eşleşti, ŞİMDİ ne olacak (+ kararı değiştirme düğmeleri).
///
/// Yaklaşık eşleşme bir tahmindir; kullanıcı bunu "uygulama bir şeyi
/// gizlice attı" diye değil, "şu kayda şu yüzden benzettim" diye görmeli.
/// Bu yüzden gerekçeler ([DuplicateMatch]'in alanları) tek tek, sade dille
/// çip olarak yazılır ve eşleşen kaydın kendisi (başlık · kategori · tutar ·
/// tarih) gösterilir — yanlış eşleşme bir bakışta fark edilsin.
class DuplicateMatchPanel extends StatelessWidget {
  final ImportDraft draft;

  /// Tutarların biçimlendirileceği birim (hedef cüzdanınki).
  final String currency;

  /// Eşleşen kaydın kategorisinin gösterilecek adı (bulunamazsa `null`).
  final String? existingCategoryLabel;

  /// Satırı yeni kayıt olarak ekle / eklemekten vazgeç.
  final ValueChanged<bool> onSelected;

  /// "Tutarı ekstredekiyle düzelt" kararı.
  final ValueChanged<bool> onCorrect;

  const DuplicateMatchPanel({
    super.key,
    required this.draft,
    required this.currency,
    required this.onSelected,
    required this.onCorrect,
    this.existingCategoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final match = draft.duplicateOf!;
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final color = switch (match.kind) {
      DuplicateKind.approximate =>
        match.strong ? AppGradients.debt : Colors.orange.shade800,
      DuplicateKind.exact || DuplicateKind.withinFile => cs.onSurfaceVariant,
    };
    final title = switch (match.kind) {
      DuplicateKind.exact => l10n.bankImportDupExact,
      DuplicateKind.withinFile => l10n.bankImportDupWithinFile,
      DuplicateKind.approximate when match.existingIsSystem =>
        l10n.bankImportDupSystem,
      DuplicateKind.approximate => match.strong
          ? l10n.bankImportDupApproxStrong
          : l10n.bankImportDupApproxPossible,
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                match.isApproximate
                    ? Icons.difference_outlined
                    : Icons.copy_all_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (match.kind != DuplicateKind.withinFile) ...[
            const SizedBox(height: 4),
            Text(
              _existingLine(context, match),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
          if (match.isApproximate) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final reason in _reasons(context, match))
                  _ReasonChip(label: reason),
              ],
            ),
          ],
          const SizedBox(height: 4),
          _decision(context, match, color),
        ],
      ),
    );
  }

  /// `“bim” · Market · −913,00 ₺ · 05.09.26 21:40`
  ///
  /// Not boş bırakılmış elle kayıtta başlık kategori adına düşer; o durumda
  /// kategori ikinci kez yazılmaz (“Yakıt” · Yakıt).
  String _existingLine(BuildContext context, DuplicateMatch m) {
    final sign = draft.isIncome ? '+' : '−';
    final date = m.existingDate;
    final hasTime = date.hour != 0 || date.minute != 0;
    final label = existingCategoryLabel;
    final titleIsCategory =
        label != null && foldTr(label) == foldTr(m.existingTitle);
    return [
      '“${m.existingTitle}”',
      if (label != null && !titleIsCategory) label,
      '$sign${formatMoney(m.existingAmount, currency: currency)}',
      hasTime
          ? '${AppFormatters.dateShort.format(date)} '
              '${AppFormatters.time.format(date)}'
          : AppFormatters.dateShort.format(date),
    ].join(' · ');
  }

  List<String> _reasons(BuildContext context, DuplicateMatch m) {
    final l10n = context.l10n;
    final delta = formatMoney(m.amountDelta.abs(), currency: currency);
    return [
      switch (m.amountPattern) {
        AmountPattern.exact => l10n.bankImportDupReasonSameAmount,
        AmountPattern.centsDropped => l10n.bankImportDupReasonCents(delta),
        AmountPattern.roundedSmall ||
        AmountPattern.roundedLarge =>
          l10n.bankImportDupReasonRounded(delta),
      },
      m.dayDistance == 0
          ? l10n.bankImportDupReasonSameDay
          : l10n.bankImportDupReasonDays(m.dayDistance),
      if (m.sharedWord case final word?) l10n.bankImportDupReasonWord(word),
      if (m.categoryMatches) l10n.bankImportDupReasonCategory,
    ];
  }

  /// Şu anki karar + onu değiştiren düğmeler. Satır dar ekranda sarar
  /// (Wrap): düğme etiketleri tutar içerdiği için genişliği öngörülemez.
  Widget _decision(BuildContext context, DuplicateMatch m, Color color) {
    final l10n = context.l10n;
    final bank = formatMoney(draft.amount, currency: currency);
    final status = draft.selected
        ? l10n.bankImportDupWillAdd
        : draft.correctExisting
            ? l10n.bankImportDupWillCorrect(bank)
            : l10n.bankImportDupWillSkip;

    final actions = <Widget>[
      if (draft.selected)
        _action(context, l10n.bankImportDupSkip, () => onSelected(false))
      else if (draft.correctExisting)
        _action(context, l10n.bankImportDupCorrectUndo, () => onCorrect(false))
      else ...[
        _action(
          context,
          m.isApproximate
              ? l10n.bankImportDupAddAnyway
              : l10n.bankImportDupAddAnywayExact,
          () => onSelected(true),
        ),
        if (m.canCorrectAmount)
          _action(
              context, l10n.bankImportDupCorrect(bank), () => onCorrect(true),
              emphasized: true),
      ],
    ];

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: draft.selected ? null : color,
          ),
        ),
        ...actions,
      ],
    );
  }

  /// Düğme yazısı temanın `labelLarge`ından türetilir: `styleFrom`'a ham
  /// bir `TextStyle` vermek temanın yazı ailesini de düşürürdü.
  Widget _action(BuildContext context, String label, VoidCallback onPressed,
      {bool emphasized = false}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
      ),
      child: Text(label),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String label;
  const _ReasonChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
