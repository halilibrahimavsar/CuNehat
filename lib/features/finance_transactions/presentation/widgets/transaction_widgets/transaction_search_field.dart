import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// İşlem listesinin arama alanı.
///
/// Filtre durumundaki `searchQuery` uzun süredir vardı ama onu yazan bir UI
/// yoktu; alan sayılıyor, hiç uygulanmıyordu. Alan artık üst çubukta kalıcı
/// olarak duruyor (ikon ardına gizlenmiş bir arama keşfedilmiyor) ve yazdıkça
/// canlı süzüyor.
class TransactionSearchField extends StatefulWidget {
  /// Filtredeki güncel sorgu; dışarıdan temizlenirse (ör. "Filtreleri
  /// temizle") alan da temizlenmeli.
  final String? value;
  final ValueChanged<String> onChanged;

  const TransactionSearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TransactionSearchField> createState() => _TransactionSearchFieldState();
}

class _TransactionSearchFieldState extends State<TransactionSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(covariant TransactionSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Yalnız DIŞARIDAN gelen değişimi yansıt.
    //
    // Karşılaştırma KIRPILMIŞ metinle yapılır: filtre sorguyu `trim`'liyor,
    // alan ise ham metni tutuyor. Kullanıcı "elektrik " yazıp ikinci kelimeye
    // geçerken ilgisiz bir yeniden çizim gelirse (ör. silme sonrası defter
    // tazelemesi) ham karşılaştırma alanı "elektrik"e ezer ve boşluk kaybolur
    // — çok kelimeli arama yazılamaz hâle gelirdi (ölçüldü).
    final external = widget.value ?? '';
    if (external != _controller.text.trim()) {
      _controller.text = external;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final hasText = _controller.text.isNotEmpty;

    return SizedBox(
      height: 42,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          widget.onChanged(value);
          setState(() {}); // temizle düğmesinin görünürlüğü
        },
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 14, color: scheme.onSurface),
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.txSearchHint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 42),
          suffixIcon: hasText
              ? IconButton(
                  tooltip: l10n.txSearchClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    FocusScope.of(context).unfocus();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: scheme.onSurface.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: scheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: scheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary, width: 1.4),
          ),
        ),
      ),
    );
  }
}
