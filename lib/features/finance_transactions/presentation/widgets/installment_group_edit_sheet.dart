import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/installments.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';
import 'package:flutter/material.dart';

/// Taksitli alışverişin TAMAMINI düzenler: toplam tutar, ad ve kategori.
///
/// Dönüş: grubun satırlarının yeni hâlleri (bkz. [redistributeInstallments])
/// ya da vazgeçildiyse `null`. Yazmak çağıranın işidir
/// (`UpdateTransactionsEvent`).
///
/// Tarihler burada DEĞİŞMEZ: taksitlerin ayları ekstrelerle eşleşir; alış
/// gününü kaydırmak bütün ekstre dönemlerini kaydırırdı.
class InstallmentGroupEditSheet extends StatefulWidget {
  /// Grubun satırları (taksit sırasıyla).
  final List<TransactionEntity> group;

  /// Tutarların birimi: satırların cüzdanınınki.
  final String currency;

  /// Kategorinin o an görünen adı; kategori değişirse sayfa kendi günceller.
  final String? categoryLabel;

  const InstallmentGroupEditSheet({
    super.key,
    required this.group,
    required this.currency,
    this.categoryLabel,
  });

  static Future<List<TransactionEntity>?> show(
    BuildContext context, {
    required List<TransactionEntity> group,
    required String currency,
    String? categoryLabel,
  }) {
    return showModalBottomSheet<List<TransactionEntity>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InstallmentGroupEditSheet(
        group: group,
        currency: currency,
        categoryLabel: categoryLabel,
      ),
    );
  }

  @override
  State<InstallmentGroupEditSheet> createState() =>
      _InstallmentGroupEditSheetState();
}

class _InstallmentGroupEditSheetState extends State<InstallmentGroupEditSheet> {
  late final TransactionEntity _first = widget.group.first;
  late final double _initialTotal =
      roundToCents(widget.group.fold<double>(0, (sum, t) => sum + t.amount));
  late final String _initialName = installmentBaseTitle(_first.title);

  late final _name = TextEditingController(text: _initialName);
  late final _total =
      TextEditingController(text: formatAmountForInput(_initialTotal));

  /// Yeni kategori; `null` = değiştirilmedi.
  String? _tag;
  String? _tagLabel;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    super.dispose();
  }

  double? get _parsedTotal => parseMoneyInput(_total.text);

  Future<void> _pickCategory() async {
    final picked = await showCategoryPickerSheet(
      context: context,
      isExpense: _first.isExpense,
      walletId: _first.walletId,
      currentId: _tag ?? _first.tag,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _tag = picked.id;
      _tagLabel = picked.name;
    });
  }

  void _submit() {
    final l10n = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.installmentEditNameRequired);
      return;
    }
    final total = _parsedTotal;
    if (total == null || total <= 0) {
      setState(() => _error = l10n.gecerliTutarGirin);
      return;
    }
    Navigator.of(context).pop(redistributeInstallments(
      widget.group,
      total: total,
      // Ad değişmediyse başlıklara DOKUNULMAZ: kullanıcı tek bir taksitin
      // başlığını elle düzenlemiş olabilir.
      title: name == _initialName ? null : name,
      tag: _tag,
    ));
  }

  /// "6 taksit × 2.083,33 ₺" — bölünme tam değilse son taksit ayrıca yazılır.
  String? _preview() {
    final total = _parsedTotal;
    if (total == null || total <= 0) return null;
    final rows = redistributeInstallments(widget.group, total: total);
    String money(double v) => formatMoney(v, currency: widget.currency);
    final first = rows.first.amount;
    final last = rows.last.amount;
    return moneyEquals(first, last)
        ? context.l10n.installmentEditPreview(rows.length, money(first))
        : context.l10n.installmentEditPreviewUneven(
            rows.length, money(first), money(last));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final preview = _preview();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      // Birincil eylem kaydırılan içeriğin DIŞINDA: klavye açılınca düğme
      // görünür kalsın.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    l10n.installmentEditTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.installmentEditHint,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('installment-edit-name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.installmentEditName,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('installment-edit-total'),
                    controller: _total,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    decoration: InputDecoration(
                      labelText: l10n.installmentEditTotal,
                      suffixText: currencySymbol(widget.currency),
                      helperText: preview,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    key: const ValueKey('installment-edit-category'),
                    onTap: _pickCategory,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.installmentEditCategory,
                        suffixIcon: const Icon(Icons.chevron_right_rounded),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _tagLabel ?? widget.categoryLabel ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (_error case final String error) ...[
                    const SizedBox(height: 10),
                    Text(error, style: TextStyle(color: cs.error)),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding:
                EdgeInsets.fromLTRB(20, 8, 20, 16 + sheetBottomInset(context)),
            child: FilledButton.icon(
              key: const ValueKey('installment-edit-save'),
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(l10n.kaydet),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
