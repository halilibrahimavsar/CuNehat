import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter/material.dart';

/// Altın türü anahtarları — fiyat servisinin (truncgil) beklediği hâl.
/// Kayıtta `symbol` olarak saklanır; ekranda ASLA ham hâliyle gösterilmez,
/// [goldTypeLabel]'dan geçirilir.
const List<String> kGoldTypeKeys = [
  'gram-altin',
  'ceyrek-altin',
  'yarim-altin',
  'tam-altin',
  'cumhuriyet-altini',
  'ata-altin',
];

/// Anahtarın kullanıcıya gösterilen adı ("gram-altin" → "Gram Altın").
/// Tanınmayan anahtar (elle girilmiş sembol) olduğu gibi döner.
String goldTypeLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'gram-altin' => l10n.gramAltin,
    'ceyrek-altin' => l10n.ceyrekAltin,
    'yarim-altin' => l10n.yarimAltin,
    'tam-altin' => l10n.tamAltin,
    'cumhuriyet-altini' => l10n.cumhuriyetAltini,
    'ata-altin' => l10n.ataAltin,
    _ => key,
  };
}

Map<String, String> goldTypeLabels(BuildContext context) => {
      for (final key in kGoldTypeKeys) key: goldTypeLabel(context, key),
    };

/// Kaydın miktar biriminin adı: altında türün kendisi ("Gram Altın"),
/// hissede "lot". Miktar takibi olmayan kayıtta null.
String? investmentUnitLabel(BuildContext context, InvestmentEntity inv) {
  final symbol = inv.symbol;
  if (symbol == null) return null;
  return switch (inv.type) {
    InvestmentType.gold => goldTypeLabel(context, symbol),
    InvestmentType.stock => context.l10n.lot,
    InvestmentType.custom => null,
  };
}

/// Altın türü seçici. Ekleme ve katkı sayfaları aynı listeyi gösterdiği için
/// tek yerde durur.
class GoldTypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  /// null → seçim serbest. Doluysa alan kilitlidir (kayıt düzenlenirken
  /// birimi değiştirmek miktarın anlamını sessizce değiştirirdi).
  final bool enabled;

  const GoldTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labels = goldTypeLabels(context);
    // Tanınmayan sembol listede yoksa DropdownButton assert atar; kaydın
    // kendi değeri her hâlükârda seçenek olarak sunulur.
    if (!labels.containsKey(value)) {
      labels[value] = goldTypeLabel(context, value);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: cs.surface,
          icon: Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
          items: labels.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(
                e.value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: enabled
              ? (val) {
                  if (val != null) onChanged(val);
                }
              : null,
        ),
      ),
    );
  }
}
