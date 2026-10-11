import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter/material.dart';

/// Borç eklenirken kullanıcının seçtiği bakiye etkisi:
/// [cash] = nakit ele geçti (anapara gelir yazılır),
/// [product] = ürün/hizmet alındı (bakiye değişmez),
/// [ledger] = nakit ele geçti ve giriş defterde ZATEN duruyor (ekstreden
/// gelen "KREDI KULLANDIRIM" satırı) — o satır benimsenir, ikinci gelir
/// yazılmaz.
enum DebtCashImpact { cash, product, ledger }

/// "Bu borç karşılığında ne aldın?" — formun İÇİNDE, Kaydet'in hemen üstünde.
///
/// Eskiden Kaydet'e basıldıktan SONRA açılan bir diyalogdu: kullanıcı formu
/// bitirdiğini sanıyor, karşısına bakiyesini değiştirecek bir soru çıkıyordu.
/// Şimdi seçim formun bir alanı ve altında, girilen tutarla, cüzdana ne
/// olacağı yazıyor.
///
/// Ön seçim BİLEREK yok: "nakit" varsayılsa, yıllardır ödediği krediyi
/// takibe alan kullanıcının bakiyesi sessizce anapara kadar şişerdi. Seçim
/// zorunlu kalır, yalnız sürpriz olmaktan çıkar.
class DebtCashImpactSelector extends StatelessWidget {
  final DebtCashImpact? selected;
  final ValueChanged<DebtCashImpact> onChanged;

  /// Formdaki tutar; henüz geçerli bir tutar yoksa `null`.
  final double? amount;
  final Color accent;

  /// Borcun ait olduğu cüzdanın para birimi.
  final String currency;

  /// Seçim yapılmadan kaydedilmeye çalışıldı: bölüm çerçeveyle işaretlenir.
  final bool missing;

  const DebtCashImpactSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.amount,
    required this.accent,
    required this.currency,
    this.missing = false,
  });

  String _effect(BuildContext context) {
    final l10n = context.l10n;
    return switch (selected) {
      null => l10n.borcNakitEtkiAciklama,
      // Kullanıcının AZ ÖNCE girdiği tutarın cüzdana ne yapacağını söyleyen
      // metin; göz düğmesinden bilerek muaf — maskelenirse anlamsızlaşır.
      DebtCashImpact.cash => l10n.borcNakitSecenekGovde(
          amount == null
              ? l10n.tutarHint
              : formatMoney(amount!, currency: currency),
        ),
      DebtCashImpact.ledger => l10n.borcDefterdeSecenekGovde,
      DebtCashImpact.product => l10n.borcUrunSecenekGovde,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final warn = AppGradients.debt;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: missing ? warn : cs.onSurface.withValues(alpha: 0.05),
          width: missing ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.borcNakitEtkiBaslik,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: missing ? warn : cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          LabeledSegment<DebtCashImpact?>(
            key: const ValueKey('debt-cash-impact'),
            items: [
              SegmentItem(
                value: DebtCashImpact.cash,
                label: l10n.borcNakitSecenekBaslik,
                color: accent,
              ),
              SegmentItem(
                value: DebtCashImpact.ledger,
                label: l10n.borcEtkiDefterKisa,
                color: accent,
              ),
              SegmentItem(
                value: DebtCashImpact.product,
                label: l10n.borcEtkiUrunKisa,
                color: accent,
              ),
            ],
            selected: selected,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                _effect(context),
                style: TextStyle(
                  fontSize: 12.5,
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
