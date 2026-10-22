import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter/material.dart';

/// Satır düzenleme sayfasının sonucu. Çağıran yalnız DEĞİŞEN alanları
/// cubit'e yazar.
typedef DraftEdit = ({
  String description,
  double amount,
  TransactionTypeModel type,
});

/// İnceleme listesindeki bir satırın açıklama, tutar ve türünü TEK sayfada
/// düzenler.
///
/// Eskiden üç ayrı ve görünmez yol vardı: açıklamaya dokun (diyalog), tutara
/// dokun (başka diyalog), satırın ucundaki 20dp'lik ok simgesine dokun (türü
/// onaysız, tek dokunuşla çevirir ve kategoriyi sıfırlar). Hiçbirinin
/// "düzenlenebilir" olduğunu gösteren bir işareti yoktu; üçüncüsü parmak
/// kaydığında yanlışlıkla tetikleniyordu.
Future<DraftEdit?> showDraftEditSheet(
  BuildContext context, {
  required ImportDraft draft,
  required String currency,
  bool focusAmount = false,
}) {
  return showModalBottomSheet<DraftEdit>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _DraftEditSheet(
      draft: draft,
      currency: currency,
      focusAmount: focusAmount,
    ),
  );
}

class _DraftEditSheet extends StatefulWidget {
  final ImportDraft draft;
  final String currency;
  final bool focusAmount;

  const _DraftEditSheet({
    required this.draft,
    required this.currency,
    required this.focusAmount,
  });

  @override
  State<_DraftEditSheet> createState() => _DraftEditSheetState();
}

class _DraftEditSheetState extends State<_DraftEditSheet> {
  late final _description =
      TextEditingController(text: widget.draft.description);
  late final _amount =
      TextEditingController(text: formatAmountForInput(widget.draft.amount));
  late TransactionTypeModel _type = widget.draft.type;
  bool _amountInvalid = false;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final amount = parseMoneyInput(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _amountInvalid = true);
      return;
    }
    Navigator.pop<DraftEdit>(
      context,
      (description: _description.text.trim(), amount: amount, type: _type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + sheetBottomInset(context)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.bankImportEditRowTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            LabeledSegment<TransactionTypeModel>(
              key: const ValueKey('draft-edit-type'),
              items: [
                SegmentItem(
                  value: TransactionTypeModel.expense,
                  label: l10n.detailLabelGider,
                  color: AppGradients.debt,
                ),
                SegmentItem(
                  value: TransactionTypeModel.income,
                  label: l10n.detailLabelGelir,
                  color: AppGradients.savings,
                ),
              ],
              selected: _type,
              onChanged: (type) => setState(() => _type = type),
            ),
            // Tür değişince satırın kategorisi yeniden tahmin edilir (gider
            // kategorisi gelir satırına yazılamaz): kullanıcı kaydetmeden
            // önce bilmeli.
            if (_type != widget.draft.type) ...[
              const SizedBox(height: 6),
              Text(
                l10n.bankImportEditTypeNote,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _description,
              autofocus: !widget.focusAmount,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.bankImportEditDescLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: widget.focusAmount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter()],
              onChanged: (_) {
                if (_amountInvalid) setState(() => _amountInvalid = false);
              },
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l10n.bankImportEditAmountLabel,
                // Hedef cüzdanın birimi; sabit '₺' USD/EUR cüzdanda yanlıştı.
                suffixText: currencySymbol(widget.currency),
                errorText: _amountInvalid ? l10n.gecerliTutarGirin : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.iptal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.kaydet),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
