import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yatırım ekleme/düzenleme sheet'lerinin (hisse / altın / özel) ortak yapı
/// taşları. Üç sheet de aynı görsel iskeleti paylaşır; tek değişen, türe özgü
/// vurgu rengi (accent), ikincil renk, başlık ve metinlerdir. Bu yüzden bu
/// widget'lar accent'i parametre alır ve sunum kararlarını çağırana bırakır.
///
/// [accent] her zaman bir [MaterialColor]'dır (purple / amber / blue) çünkü
/// kaydet butonu ve canlı-fiyat butonu `.shade600` tonunu kullanır.

/// Tutacak (drag handle) + başlık satırı (ikon + başlık + kapat).
class InvestmentSheetHeader extends StatelessWidget {
  final MaterialColor accent;
  final IconData icon;
  final String title;
  final VoidCallback onClose;

  const InvestmentSheetHeader({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Mevcut Değer" büyük giriş kartı. [valueColor] hem degrade bitişini hem de
/// büyük rakamın rengini verir (üç sheet'te de aynıdır).
class InvestmentAmountCard extends StatelessWidget {
  final MaterialColor accent;
  final Color valueColor;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const InvestmentAmountCard({
    super.key,
    required this.accent,
    required this.valueColor,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.15),
            valueColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.mevcutDeger,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [AmountInputFormatter()],
                  onChanged: (_) => onChanged(),
                  cursorColor: accent,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: accent.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  context.activeWalletCurrencySymbol,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: accent.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bölüm başlığı (küçük, kalın etiket).
class InvestmentSectionLabel extends StatelessWidget {
  final String text;

  const InvestmentSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Dolgulu metin alanı; odaklanınca kenarlık [accent] rengine döner.
class InvestmentFilledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final MaterialColor accent;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback onChanged;

  const InvestmentFilledField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accent,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: keyboardType == null
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      onChanged: (_) => onChanged(),
      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon,
            size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
      ),
    );
  }
}

/// Renk seçici (yatay sarmal daireler).
class InvestmentColorSelector extends StatelessWidget {
  final List<Color> options;
  final Color selected;
  final ValueChanged<Color> onSelected;

  const InvestmentColorSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((color) {
        final isSelected = selected == color;
        return GestureDetector(
          onTap: () => onSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

/// Düzenleme modunda gösterilen "maliyeti değiştirirsen fark cüzdana yansır"
/// bilgi şeridi. Türden bağımsız; her sheet'te aynıdır.
class InvestmentCostEditWarning extends StatelessWidget {
  const InvestmentCostEditWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.maliyetiDegistirirsenizFarkCuzdana,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir alanın altında gösterilen küçük açıklama metni (info ikon + metin).
/// "Mevcut Değer" / "Toplam Maliyet" gibi alanların ne anlama geldiğini
/// kullanıcıya açıklamak için kullanılır.
class InvestmentHintCaption extends StatelessWidget {
  final String text;

  const InvestmentHintCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: cs.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hata şeridi. Türden bağımsız.
class InvestmentErrorBanner extends StatelessWidget {
  final String error;

  const InvestmentErrorBanner(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                  color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kaydet / Güncelle butonu; degrade [accent].shade600 ile boyanır.
class InvestmentSaveButton extends StatelessWidget {
  final MaterialColor accent;
  final double radius;
  final bool isEditing;
  final VoidCallback onSave;

  const InvestmentSaveButton({
    super.key,
    required this.accent,
    required this.radius,
    required this.isEditing,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius.clamp(16, 20));
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          onTap: onSave,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppGradients.vivid(accent.shade600),
              borderRadius: br,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEditing ? Icons.check_rounded : Icons.add_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? context.l10n.guncelle : context.l10n.kaydet,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Adet alanı + canlı fiyat "Hesapla" butonu (hisse ve altın sheet'lerinde
/// kullanılır). Buton [accent].shade600 ile boyanır; [fetchedMessage] varsa
/// altında [fetchedColor] ile gösterilir.
class InvestmentQuantityAndFetch extends StatelessWidget {
  final MaterialColor accent;
  final TextEditingController quantityController;
  final VoidCallback onQuantityChanged;
  final bool isLoading;
  final String? fetchedMessage;
  final Color fetchedColor;
  final VoidCallback onFetch;

  const InvestmentQuantityAndFetch({
    super.key,
    required this.accent,
    required this.quantityController,
    required this.onQuantityChanged,
    required this.isLoading,
    required this.fetchedMessage,
    required this.fetchedColor,
    required this.onFetch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: InvestmentFilledField(
            controller: quantityController,
            hint: context.l10n.adet,
            icon: Icons.numbers_rounded,
            accent: accent,
            onChanged: onQuantityChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Adet para değildir; 0,125 gr gibi hassas girişe izin ver.
            inputFormatters: [AmountInputFormatter(decimalDigits: 4)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56, // Match InvestmentFilledField height
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onFetch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    context.l10n.hesapla,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              if (fetchedMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    fetchedMessage!,
                    style: TextStyle(
                      color: fetchedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
