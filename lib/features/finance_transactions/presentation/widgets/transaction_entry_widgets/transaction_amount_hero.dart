// transaction_form_fields.dart'tan bölündü (v1 temizliği): davranış aynı.
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';

// ============================================================ Amount hero

class AmountHero extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final bool isExpense;
  final bool isEdit;
  final FocusNode focusNode;
  final VoidCallback onClose;

  /// Gider ↔ gelir. Başlık eskiden sabit bir "Gider Ekle" rozetiydi: tür
  /// sayfayı açan düğmeyle donuyor, yanlış basan kullanıcı kapatıp baştan
  /// başlıyordu.
  final ValueChanged<bool> onTypeChanged;

  const AmountHero({
    super.key,
    required this.controller,
    required this.accent,
    required this.isExpense,
    required this.isEdit,
    required this.focusNode,
    required this.onClose,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              if (isEdit) ...[
                Icon(Icons.edit_outlined, size: 18, color: accent),
                const SizedBox(width: 8),
              ],
              // Genişlik sabit: segment hücrelerini eşit böler ve sınırsız
              // genişlikte ölçülemez.
              SizedBox(
                width: 172,
                child: LabeledSegment<bool>(
                  key: const ValueKey('tx-type-segment'),
                  items: [
                    SegmentItem(
                      value: true,
                      label: l10n.menuExpense,
                      color: AppGradients.debt,
                    ),
                    SegmentItem(
                      value: false,
                      label: l10n.menuIncome,
                      color: AppGradients.savings,
                    ),
                  ],
                  selected: isExpense,
                  onChanged: onTypeChanged,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  focusNode.unfocus();
                  onClose();
                },
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: TextField(
                    controller: controller.amountController,
                    focusNode: focusNode,
                    textAlign: TextAlign.right,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    onChanged: (_) {
                      if (controller.error.value != null) {
                        controller.error.value = null;
                      }
                      // Yeni kayda başlandı: önceki kaydın onayı çekilir.
                      if (controller.lastSaved.value != null) {
                        controller.lastSaved.value = null;
                      }
                    },
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      // Yazılan tutar METİN tonuyla: gelir yeşili açık zeminde
                      // yazı olarak 2,5:1 veriyordu.
                      color: isExpense
                          ? MoneyColors.expenseText(
                              Theme.of(context).brightness)
                          : MoneyColors.incomeText(
                              Theme.of(context).brightness),
                      height: 1.0,
                    ),
                    cursorColor: accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: accent.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    context.activeWalletCurrencySymbol,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: accent.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
