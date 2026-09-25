import 'package:cunehat/config/theme/app_gradients.dart';
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

  /// Alanın odak düğümü (sahibi çağıran). Verilmezse alan kendi düğümünü
  /// kurar. Temizle/kapat bu düğümü bırakır — `FocusScope.unfocus()` odak
  /// geçmişini silmiyor, menü kapanınca klavye yeniden açılıyordu.
  final FocusNode? focusNode;
  final bool autofocus;

  /// Verilirse alan KAPATILABİLİR: metin boşken sağdaki × aramayı kapatır
  /// (doluyken önce temizler).
  final VoidCallback? onClose;

  const TransactionSearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.onClose,
  });

  @override
  State<TransactionSearchField> createState() => _TransactionSearchFieldState();
}

class _TransactionSearchFieldState extends State<TransactionSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value ?? '');
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

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
    _ownFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final hasText = _controller.text.isNotEmpty;

    final onClose = widget.onClose;
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        onChanged: (value) {
          widget.onChanged(value);
          setState(() {}); // temizle düğmesinin görünürlüğü
        },
        textInputAction: TextInputAction.search,
        // Klavyedeki "Ara": kapatılabilir alan kapanır, sorgu KORUNUR (çip
        // satırında görünür, ikon işaretli kalır).
        onSubmitted: widget.onClose == null ? null : (_) => widget.onClose!(),
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
              const BoxConstraints(minWidth: 38, minHeight: 44),
          suffixIcon: hasText
              ? IconButton(
                  tooltip: l10n.txSearchClear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    // Kapatılabilir alanda temizlemek odağı KORUR: kullanıcı
                    // büyük ihtimalle yeni bir şey yazacak.
                    if (onClose == null) _focus.unfocus();
                    setState(() {});
                  },
                )
              : onClose == null
                  ? null
                  : IconButton(
                      key: const ValueKey('tx-search-close'),
                      tooltip: l10n.txSearchClose,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: onClose,
                    ),
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
            borderSide:
                const BorderSide(color: AppGradients.transactions, width: 1.4),
          ),
        ),
      ),
    );
  }
}
