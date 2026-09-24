import 'package:flutter/material.dart';

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';

/// Bir kategoriyi BİRDEN FAZLA satıra uygulamadan önce hangi satırlara
/// uygulanacağını gösteren ve tek tek çıkarmaya izin veren diyalog.
/// Kullanıcının seçtiği indeksleri döndürür; vazgeçilirse `null`.
///
/// Neden snackbar değil de diyalog: eskiden "Hepsine uygula" 6 saniyelik bir
/// snackbar'daydı ve yalnız SAYI + tek örnek gösteriyordu. Kümeleme ortak ön
/// eke baktığı için gruba yanlış satır da girebiliyor (bkz.
/// `description_grouper.dart` "BİLİNEN SINIR" — "TURK HAVA YOLLARI" ile
/// "TURK EKONOMI BANKASI" tek grup). Kullanıcı neyi onayladığını görmeli ve
/// yanlış olanı dışarıda bırakabilmeli; süre sınırı da olmamalı. Snackbar
/// ayrıca alttaki "Ekle" düğmesini örtüyordu.
///
/// Satırın zaten bir kategorisi varsa "Eski → Yeni" olarak yazılır: üzerine
/// yazma, onaylanmadan önce görünür olsun.
///
/// [rows] boşsa (seçilen kategori satırların türüne uymuyor) liste yerine
/// açıklama ve tek "Tamam" gösterilir; dönüş `null`.
Future<List<int>?> showBulkCategoryDialog(
  BuildContext context, {
  required String title,
  required String message,
  required List<(int, ImportDraft)> rows,
  required String categoryId,
  required String currency,
  required Map<String, String> categoryLabels,
  String? cancelLabel,
}) {
  return showDialog<List<int>>(
    context: context,
    builder: (_) => rows.isEmpty
        ? const _NothingToApply()
        : BulkCategoryDialog(
            title: title,
            message: message,
            rows: rows,
            categoryId: categoryId,
            currency: currency,
            categoryLabels: categoryLabels,
            cancelLabel: cancelLabel,
          ),
  );
}

class BulkCategoryDialog extends StatefulWidget {
  final String title;
  final String message;
  final List<(int, ImportDraft)> rows;
  final String categoryId;
  final String currency;
  final Map<String, String> categoryLabels;
  final String? cancelLabel;

  const BulkCategoryDialog({
    super.key,
    required this.title,
    required this.message,
    required this.rows,
    required this.categoryId,
    required this.currency,
    required this.categoryLabels,
    this.cancelLabel,
  });

  @override
  State<BulkCategoryDialog> createState() => _BulkCategoryDialogState();
}

class _BulkCategoryDialogState extends State<BulkCategoryDialog> {
  /// Varsayılan: hepsi işaretli. Kullanıcı yalnız istisnaları çıkarır.
  late final Set<int> _checked = {for (final (i, _) in widget.rows) i};

  /// Satırın kategorisi DEĞİŞECEK mi (başka bir kategoriden bu kategoriye).
  bool _overwrites(ImportDraft d) =>
      d.categoryId != null && d.categoryId != widget.categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = _checked.length;
    final overwriting = [
      for (final (i, d) in widget.rows)
        if (_checked.contains(i) && _overwrites(d)) i,
    ].length;
    final allChecked = count == widget.rows.length;

    return AppDialogSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.message, style: theme.textTheme.bodyMedium),
          if (widget.rows.length > 3)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() {
                  if (allChecked) {
                    _checked.clear();
                  } else {
                    _checked.addAll([for (final (i, _) in widget.rows) i]);
                  }
                }),
                child: Text(allChecked
                    ? l10n.bankImportDeselectAll
                    : l10n.bankImportSelectAll),
              ),
            )
          else
            const SizedBox(height: 8),
          // Uzun listede diyalog ekranı taşmasın: liste kendi içinde kayar ve
          // başlık/düğmelerden ARTAN yüksekliğe sığar (`Flexible`). Yalnız
          // sabit bir tavan (%45) vermek alçak ekranda yetmiyordu — 360×640'ta
          // diyalog 172px taşıyordu (ölçüldü).
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, k) {
                      final (index, draft) = widget.rows[k];
                      return _row(context, index, draft);
                    },
                  ),
                ),
              ),
            ),
          ),
          if (overwriting > 0) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.swap_horiz_rounded, size: 18, color: cs.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.bankImportBulkOverwriteNote(overwriting),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Dar ekranda iki düğme sığmazsa alt alta dizilir (taşmaz).
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: 8,
            overflowSpacing: 4,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.cancelLabel ?? l10n.iptal),
              ),
              FilledButton(
                onPressed: count == 0
                    ? null
                    : () => Navigator.of(context).pop([
                          // Listedeki sırayla (satır sırası) döner.
                          for (final (i, _) in widget.rows)
                            if (_checked.contains(i)) i,
                        ]),
                child: Text(l10n.bankImportBulkApply(count)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int index, ImportDraft d) {
    final cs = Theme.of(context).colorScheme;
    final checked = _checked.contains(index);
    final accent = d.isIncome ? AppGradients.savings : AppGradients.debt;
    final from = d.categoryId;
    final to = widget.categoryLabels[widget.categoryId] ?? widget.categoryId;

    return InkWell(
      onTap: () => setState(() {
        if (!_checked.remove(index)) _checked.add(index);
      }),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 12, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: checked,
              visualDensity: VisualDensity.compact,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _checked.add(index);
                } else {
                  _checked.remove(index);
                }
              }),
            ),
            Expanded(
              child: Opacity(
                // İşareti kaldırılan satır soluklaşır: "bu dışarıda kalacak".
                opacity: checked ? 1 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      d.description.isEmpty ? '—' : d.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '${d.isIncome ? '+' : '−'}'
                              '${formatMoney(d.amount, currency: widget.currency)}',
                          style: TextStyle(
                              color: accent, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' · ${AppFormatters.dateShort.format(d.date)}',
                        ),
                      ]),
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    if (from != null && from != widget.categoryId) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${widget.categoryLabels[from] ?? from} → $to',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçilen kategori satırların türüne uymadı: hiçbir şey değişmedi ve bu,
/// sessiz kalmak yerine söylenir (eskiden bir snackbar'dı; grup sayfasında
/// modal sayfanın ARKASINDA kalıyordu).
class _NothingToApply extends StatelessWidget {
  const _NothingToApply();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return AppDialogSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bankImportBulkNothingTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.bankImportAssignTypeMismatch),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.tamam),
            ),
          ),
        ],
      ),
    );
  }
}
