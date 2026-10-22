import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Borç türüne göre dinamik gösterilen detay alanları (Vade + Taksit ya da
/// Faiz). Gecikme faizi buradan çıktı: formun kapalı açılan "Gelişmiş"
/// bölümünde, [DebtOverdueField] olarak durur.
class DebtDynamicFields extends StatelessWidget {
  final DebtType selectedDebtType;
  final bool isBankLoanMonthly;
  final bool isInstallmentAmortized;
  final TextEditingController termController;
  final TextEditingController installmentController;
  final TextEditingController interestController;
  final Color accent;
  final VoidCallback onChanged;

  const DebtDynamicFields({
    super.key,
    required this.selectedDebtType,
    required this.isBankLoanMonthly,
    required this.isInstallmentAmortized,
    required this.termController,
    required this.installmentController,
    required this.interestController,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      // Yan yana sığmıyorsa alt alta: 320dp + büyük yazıda iki alanın
      // etiketi "Vad…" / "Aylı…" diye kesiliyor, ne yazılacağı görünmüyordu.
      child: LayoutBuilder(builder: (context, constraints) {
        final minField = MediaQuery.textScalerOf(context).scale(150);
        final stacked = (constraints.maxWidth - 10) / 2 < minField;
        final fields = <Widget>[
          Expanded(
            child: FilledEntryField(
              controller: termController,
              label: context.l10n.vadeAyHint,
              hint: '',
              icon: Icons.event_repeat_rounded,
              accent: accent,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              dense: true,
              onChanged: onChanged,
            ),
          ),
          if (selectedDebtType == DebtType.bankLoan && isBankLoanMonthly) ...[
            const SizedBox(width: 10, height: 10),
            Expanded(
              child: FilledEntryField(
                controller: installmentController,
                label: context.l10n.aylikTaksitHint,
                hint: '',
                icon: Icons.payments_rounded,
                accent: accent,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter()],
                dense: true,
                onChanged: onChanged,
              ),
            ),
          ] else if (selectedDebtType != DebtType.personalDebt) ...[
            const SizedBox(width: 10, height: 10),
            Expanded(
              child: FilledEntryField(
                controller: interestController,
                label: selectedDebtType == DebtType.installmentDebt &&
                        !isInstallmentAmortized
                    ? context.l10n.vadeFarkiYuzdeHint
                    : context.l10n.aylikFaizYuzdeHint,
                hint: '',
                icon: Icons.percent_rounded,
                accent: accent,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter(decimalDigits: 4)],
                dense: true,
                onChanged: onChanged,
              ),
            ),
          ],
        ];
        if (!stacked) return Row(children: fields);
        return Column(
          children: [
            for (final f in fields)
              if (f is Expanded) f.child else f,
          ],
        );
      }),
    );
  }
}

/// Gecikme faizi (%) — kişisel borç dışında her türde girilebilir.
///
/// Alan görünmese de değeri formun denetleyicisinde YAŞAR ve kayda yazılır:
/// eskiden bazı modlarda gizliydi ve gizliyken kaydetme onu 0 yazdığı için
/// modu değişen bir kaydın gecikme faizi düzenlemede sessizce siliniyordu.
class DebtOverdueField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final VoidCallback onChanged;

  const DebtOverdueField({
    super.key,
    required this.controller,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilledEntryField(
      controller: controller,
      label: context.l10n.gecikmeFaiziYuzdeHint,
      hint: '',
      icon: Icons.running_with_errors_rounded,
      accent: accent,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [AmountInputFormatter(decimalDigits: 4)],
      dense: true,
      onChanged: onChanged,
    );
  }
}

/// Form alanları için genel dolgulu Metin Giriş Bileşeni (Filled Field).
class FilledEntryField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color accent;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool dense;
  final String? label;
  final VoidCallback? onChanged;

  const FilledEntryField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accent,
    this.keyboardType,
    this.inputFormatters,
    this.dense = false,
    this.label,
    this.onChanged,
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
      onChanged: (_) => onChanged?.call(),
      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        isDense: dense,
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: dense ? 12 : 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
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
