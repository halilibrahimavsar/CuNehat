// transaction_form_fields.dart'tan bölündü (v1 temizliği): davranış aynı.
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

  const AmountHero({
    super.key,
    required this.controller,
    required this.accent,
    required this.isExpense,
    required this.isEdit,
    required this.focusNode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = isExpense ? 'Gider' : 'Gelir';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEdit
                          ? Icons.edit_outlined
                          : (isExpense
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded),
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEdit ? '$label Düzenle' : '$label Ekle',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  focusNode.unfocus();
                  onClose();
                },
                visualDensity: VisualDensity.compact,
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
                    },
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      height: 1.0,
                    ),
                    cursorColor: accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
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
                      fontSize: 26,
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
