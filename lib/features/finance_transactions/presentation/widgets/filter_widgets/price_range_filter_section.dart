import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';

/// Tutar aralığı filtresi.
///
/// Eskiden burada AYRI bir ✓ düğmesi vardı ve panelin altında bir de "Uygula"
/// duruyordu: aynı doğrulama iki yerde kopyalanmış, kullanıcı da hangisinin
/// gerçekten uyguladığını bilmiyordu (kategori seçimi zaten anında
/// uygulanıyordu). Artık alan yazıldıkça uygular; geçersiz aralık snackbar
/// yerine alanın ALTINDA, bağlamında söylenir.
class PriceRangeFilterSection extends StatefulWidget {
  /// Filtredeki güncel aralık; dışarıdan temizlenirse alanlar da temizlenir.
  final PriceRangeFilter? range;
  final Color accent;
  final ValueChanged<PriceRangeFilter?> onChanged;

  const PriceRangeFilterSection({
    super.key,
    required this.range,
    required this.accent,
    required this.onChanged,
  });

  @override
  State<PriceRangeFilterSection> createState() =>
      _PriceRangeFilterSectionState();
}

class _PriceRangeFilterSectionState extends State<PriceRangeFilterSection> {
  late final TextEditingController _min =
      TextEditingController(text: _textOf(widget.range?.minPrice));
  late final TextEditingController _max =
      TextEditingController(text: _textOf(widget.range?.maxPrice));

  bool _invalid = false;

  static String _textOf(double? v) =>
      v == null ? '' : formatAmountForInput(v, decimalDigits: 0);

  @override
  void didUpdateWidget(covariant PriceRangeFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.range == oldWidget.range) return;
    // Yalnız DIŞARIDAN gelen değişimi yansıt. Kullanıcı yazarken emisyon
    // geri döndüğünde alanı yeniden yazmak imleci başa atardı.
    if (widget.range == _parsed()) return;
    _min.text = _textOf(widget.range?.minPrice);
    _max.text = _textOf(widget.range?.maxPrice);
    _invalid = false;
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  PriceRangeFilter? _parsed() {
    final min = parseAmountInput(_min.text);
    final max = parseAmountInput(_max.text);
    if (min == null && max == null) return null;
    return PriceRangeFilter(minPrice: min, maxPrice: max);
  }

  void _emit() {
    final min = parseAmountInput(_min.text);
    final max = parseAmountInput(_max.text);
    final invalid = min != null && max != null && min > max;

    if (invalid != _invalid) setState(() => _invalid = invalid);
    // Geçersizken filtreye DOKUNMA: yarım yazılmış "100 – 5" aralığı listeyi
    // boşaltıp kullanıcıya hata yerine boş ekran gösteriyordu.
    if (invalid) return;

    widget.onChanged(_parsed());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.txFilterAmountRange,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _field(context, _min, l10n.labelMin, '0')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '—',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(child: _field(context, _max, l10n.labelMax, '∞')),
          ],
        ),
        if (_invalid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 15, color: scheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.txFilterMinMaxError,
                    style: TextStyle(fontSize: 12, color: scheme.error),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label,
    String hint,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [AmountInputFormatter(decimalDigits: 0)],
      onChanged: (_) => _emit(),
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: context.activeWalletCurrencySymbol,
        errorText: _invalid ? '' : null,
        errorStyle: const TextStyle(height: 0, fontSize: 0),
        filled: true,
        fillColor: scheme.onSurface.withValues(alpha: 0.03),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.accent, width: 1.4),
        ),
      ),
    );
  }
}
