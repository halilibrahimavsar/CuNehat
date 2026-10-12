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

  /// Aynı kayda neredeyse aynı güçte benzeyen ve hâlâ eşleşmemiş diğer satır
  /// (bkz. `DuplicateMatch.alternativeDraftIndex`); yoksa `null`.
  final ImportDraft? alternativeDraft;

  /// Eşleşmeyi [alternativeDraft]'a taşı.
  final VoidCallback? onMoveMatch;

  /// "Eski taksit satırını doğru aya taşı" kararı (bkz.
  /// `DuplicateMatch.legacyInstallment`); verilmezse seçenek sunulmaz.
  final ValueChanged<bool>? onRelocate;

  const DuplicateMatchPanel({
    super.key,
    required this.draft,
    required this.currency,
    required this.onSelected,
    required this.onCorrect,
    this.existingCategoryLabel,
    this.alternativeDraft,
    this.onMoveMatch,
    this.onRelocate,
  });

  @override
  Widget build(BuildContext context) {
    final match = draft.duplicateOf!;
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final color = switch (match.kind) {
      DuplicateKind.approximate =>
        match.strong ? AppGradients.debt : Colors.orange.shade800,
      // Kullanıcının kendi kararı: tahmin renginde (turuncu) değil.
      DuplicateKind.linkedByUser => cs.primary,
      DuplicateKind.exact || DuplicateKind.withinFile => cs.onSurfaceVariant,
    };
    final title = switch (match.kind) {
      DuplicateKind.exact => l10n.bankImportDupExact,
      DuplicateKind.withinFile => l10n.bankImportDupWithinFile,
      DuplicateKind.linkedByUser => l10n.bankImportDupLinkedByUser,
      DuplicateKind.approximate when match.existingIsSystem =>
        l10n.bankImportDupSystem,
      DuplicateKind.approximate => match.strong
          ? l10n.bankImportDupApproxStrong
          : l10n.bankImportDupApproxPossible,
    };
    final icon = switch (match.kind) {
      DuplicateKind.approximate => Icons.difference_outlined,
      DuplicateKind.linkedByUser => Icons.link_rounded,
      DuplicateKind.exact || DuplicateKind.withinFile => Icons.copy_all_rounded,
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
              Icon(icon, size: 16, color: color),
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
          if (match.hasReasons) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final reason in _reasons(context, match))
                  DuplicateReasonChip(label: reason),
              ],
            ),
          ],
          if (alternativeDraft case final alt?) ...[
            const SizedBox(height: 6),
            Text(
              l10n.bankImportDupAlternative(_rowLine(alt)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 4),
          _decision(context, match, color),
        ],
      ),
    );
  }

  /// Banka satırının kısa özeti: `MIGROS … · −910,00 ₺ · 07.09.26`.
  String _rowLine(ImportDraft d) => [
        d.description.isEmpty ? '—' : d.description,
        '${d.isIncome ? '+' : '−'}${formatMoney(d.amount, currency: currency)}',
        AppFormatters.dateShort.format(d.date),
      ].join(' · ');

  String _existingLine(BuildContext context, DuplicateMatch m) =>
      ledgerEntryLine(
        title: m.existingTitle,
        categoryLabel: existingCategoryLabel,
        amount: m.existingAmount,
        isIncome: draft.isIncome,
        date: m.existingDate,
        currency: currency,
      );

  List<String> _reasons(BuildContext context, DuplicateMatch m) =>
      duplicateReasonLabels(
        context,
        amountPattern: m.amountPattern,
        amountDelta: m.amountDelta,
        dayDistance: m.dayDistance,
        sharedWord: m.sharedWord,
        categoryMatches: m.categoryMatches,
        currency: currency,
      );

  /// Şu anki karar + onu değiştiren düğmeler. Satır dar ekranda sarar
  /// (Wrap): düğme etiketleri tutar içerdiği için genişliği öngörülemez.
  Widget _decision(BuildContext context, DuplicateMatch m, Color color) {
    final l10n = context.l10n;
    final bank = formatMoney(draft.amount, currency: currency);
    final relocating = draft.relocateExisting && m.legacyInstallment;
    final status = draft.selected
        ? l10n.bankImportDupWillAdd
        : relocating
            // Eski içe aktarım bu taksiti alışveriş gününe yazmış: satır
            // taksitin kendi ayına alınır, kalanlar da yazılır.
            ? l10n.bankImportDupWillRelocate(
                AppFormatters.dateShort.format(draft.date),
                draft.installment?.remaining ?? 0,
              )
            : draft.correctExisting
                ? l10n.bankImportDupWillCorrect(bank)
                : l10n.bankImportDupWillSkip;

    final actions = <Widget>[
      if (draft.selected)
        _action(context, l10n.bankImportDupSkip, () => onSelected(false))
      else if (relocating)
        _action(context, l10n.bankImportDupRelocateUndo,
            () => onRelocate?.call(false))
      else if (draft.correctExisting)
        _action(context, l10n.bankImportDupCorrectUndo, () => onCorrect(false))
      else ...[
        _action(
          context,
          m.hasReasons
              ? l10n.bankImportDupAddAnyway
              : l10n.bankImportDupAddAnywayExact,
          () => onSelected(true),
        ),
        if (m.canCorrectAmount)
          _action(
              context, l10n.bankImportDupCorrect(bank), () => onCorrect(true),
              emphasized: true),
        if (alternativeDraft != null && onMoveMatch != null)
          _action(context, l10n.bankImportDupMoveMatch, onMoveMatch!),
        if (m.legacyInstallment && onRelocate != null)
          _action(context, l10n.bankImportDupRelocate, () => onRelocate!(true),
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

/// Defter kaydının tek satırlık özeti:
/// `“bim” · Market · −913,00 ₺ · 05.09.26 21:40`.
///
/// Not boş bırakılmış elle kayıtta başlık kategori adına düşer; o durumda
/// kategori ikinci kez yazılmaz (“Yakıt” · Yakıt). Saat yalnız kayıtta varsa
/// (ekstre satırları gün hassasiyetlidir) yazılır.
String ledgerEntryLine({
  required String title,
  required String? categoryLabel,
  required double amount,
  required bool isIncome,
  required DateTime date,
  required String currency,
}) {
  final sign = isIncome ? '+' : '−';
  final hasTime = date.hour != 0 || date.minute != 0;
  final titleIsCategory =
      categoryLabel != null && foldTr(categoryLabel) == foldTr(title);
  return [
    '“$title”',
    if (categoryLabel != null && !titleIsCategory) categoryLabel,
    '$sign${formatMoney(amount, currency: currency)}',
    hasTime
        ? '${AppFormatters.dateShort.format(date)} '
            '${AppFormatters.time.format(date)}'
        : AppFormatters.dateShort.format(date),
  ].join(' · ');
}

/// Bir eşleşmenin (ya da önerinin) gerekçeleri, sade dille: tutar nasıl
/// benziyor, kaç gün uzak, ortak kelime, aynı kategori. Tekrar paneli ve
/// "karşılığı bulunamayan kayıtlar" sayfası AYNI dili konuşsun diye tek yerde.
List<String> duplicateReasonLabels(
  BuildContext context, {
  required AmountPattern amountPattern,
  required double amountDelta,
  required int dayDistance,
  required String? sharedWord,
  required bool categoryMatches,
  required String currency,
}) {
  final l10n = context.l10n;
  final delta = formatMoney(amountDelta.abs(), currency: currency);
  return [
    switch (amountPattern) {
      AmountPattern.exact => l10n.bankImportDupReasonSameAmount,
      AmountPattern.centsDropped => l10n.bankImportDupReasonCents(delta),
      AmountPattern.roundedSmall ||
      AmountPattern.roundedLarge =>
        l10n.bankImportDupReasonRounded(delta),
      AmountPattern.near => l10n.bankImportDupReasonNear(delta),
    },
    dayDistance == 0
        ? l10n.bankImportDupReasonSameDay
        : l10n.bankImportDupReasonDays(dayDistance),
    if (sharedWord case final word?) l10n.bankImportDupReasonWord(word),
    if (categoryMatches) l10n.bankImportDupReasonCategory,
  ];
}

/// Gerekçe çipi (tekrar paneli ve öneri sayfası).
class DuplicateReasonChip extends StatelessWidget {
  final String label;
  const DuplicateReasonChip({super.key, required this.label});

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
