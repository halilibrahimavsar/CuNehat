import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// filter_view.dart'tan bölündü (v1 temizliği): davranış aynı.
class PriceRangeFilterSection extends StatelessWidget {
  final CombinedFilter filter;
  final TextEditingController minController;
  final TextEditingController maxController;
  final ValueChanged<PriceRangeFilter?> onPriceRangeChanged;

  const PriceRangeFilterSection({
    super.key,
    required this.filter,
    required this.minController,
    required this.maxController,
    required this.onPriceRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.fIYATAraligi,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                inputFormatters: [AmountInputFormatter(decimalDigits: 0)],
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: context.l10n.labelMin,
                  hintText: '0',
                  suffixText: context.activeWalletCurrencySymbol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.03),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '—',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                inputFormatters: [AmountInputFormatter(decimalDigits: 0)],
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: context.l10n.labelMax,
                  hintText: '∞',
                  suffixText: context.activeWalletCurrencySymbol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.03),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Uygula Butonu
            InkWell(
              onTap: () {
                final min = parseAmountInput(minController.text);
                final max = parseAmountInput(maxController.text);
                if (min != null && max != null && min > max) {
                  IboSnackbar.showError(
                    context,
                    'Minimum tutar, maksimum tutardan büyük olamaz',
                  );
                  return;
                }
                final range = (min == null && max == null)
                    ? null
                    : PriceRangeFilter(minPrice: min, maxPrice: max);
                onPriceRangeChanged(range);
                FocusScope.of(context).unfocus();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: filter.viewFilter.financeMode.primaryColor
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: filter.viewFilter.financeMode.primaryColor
                        .withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: filter.viewFilter.financeMode.primaryColor,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        if (filter.dataFilter.priceRange != null &&
            filter.dataFilter.priceRange!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filter.dataFilter.priceRange!
                        .label(symbol: context.activeWalletCurrencySymbol),
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    minController.clear();
                    maxController.clear();
                    onPriceRangeChanged(null);
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
